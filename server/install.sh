#!/bin/bash

# WireGuard VPN 服务器安装脚本
# 支持 Ubuntu/Debian/CentOS/RHEL

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置变量
WG_INTERFACE="wg0"
WG_PORT="51820"
WG_NETWORK="10.0.0.0/24"
WG_SERVER_IP="10.0.0.1"
WG_CONFIG_DIR="/etc/wireguard"
WG_CLIENTS_DIR="$WG_CONFIG_DIR/clients"

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS=debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        OS=opensuse
    elif [ -f /etc/redhat-release ]; then
        OS=rhel
    else
        echo -e "${RED}无法检测操作系统类型${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}检测到操作系统: $OS $VER${NC}"
}

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}请使用root权限运行此脚本${NC}"
        echo "使用: sudo $0"
        exit 1
    fi
}

# 安装WireGuard
install_wireguard() {
    echo -e "${YELLOW}正在安装WireGuard...${NC}"
    
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        apt-get update
        apt-get install -y wireguard wireguard-tools qrencode iptables
        
        # 启用IP转发
        if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
            echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        fi
        if ! grep -q "net.ipv6.conf.all.forwarding=1" /etc/sysctl.conf; then
            echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
        fi
        sysctl -p
        
    elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ]; then
        if [ "$OS" == "centos" ] || [ "$OS" == "rhel" ]; then
            yum install -y epel-release elrepo-release
            yum install -y kmod-wireguard wireguard-tools qrencode iptables
        else
            dnf install -y wireguard-tools qrencode iptables
        fi
        
        # 启用IP转发
        if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
            echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        fi
        if ! grep -q "net.ipv6.conf.all.forwarding=1" /etc/sysctl.conf; then
            echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
        fi
        sysctl -p
    else
        echo -e "${RED}不支持的操作系统: $OS${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}WireGuard安装完成${NC}"
}

# 生成服务器密钥
generate_server_keys() {
    echo -e "${YELLOW}正在生成服务器密钥...${NC}"
    
    mkdir -p "$WG_CONFIG_DIR"
    mkdir -p "$WG_CLIENTS_DIR"
    
    if [ ! -f "$WG_CONFIG_DIR/server_private.key" ]; then
        wg genkey | tee "$WG_CONFIG_DIR/server_private.key" | wg pubkey > "$WG_CONFIG_DIR/server_public.key"
        chmod 600 "$WG_CONFIG_DIR/server_private.key"
        chmod 644 "$WG_CONFIG_DIR/server_public.key"
        echo -e "${GREEN}服务器密钥已生成${NC}"
    else
        echo -e "${YELLOW}服务器密钥已存在，跳过生成${NC}"
    fi
}

# 获取服务器公网IP
get_server_ip() {
    SERVER_PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
    if [ -z "$SERVER_PUBLIC_IP" ]; then
        echo -e "${YELLOW}无法自动获取公网IP，请手动输入:${NC}"
        read -p "服务器公网IP或域名: " SERVER_PUBLIC_IP
    fi
    echo -e "${GREEN}服务器地址: $SERVER_PUBLIC_IP${NC}"
}

# 创建WireGuard配置
create_wg_config() {
    echo -e "${YELLOW}正在创建WireGuard配置...${NC}"
    
    SERVER_PRIVATE_KEY=$(cat "$WG_CONFIG_DIR/server_private.key")
    
    # 动态获取出口网卡
    WG_EXT_NIC=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \K[^ ]+' || echo "eth0")
    
    cat > "$WG_CONFIG_DIR/$WG_INTERFACE.conf" <<EOF
[Interface]
Address = $WG_SERVER_IP/24
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIVATE_KEY
PostUp = iptables -A FORWARD -i $WG_INTERFACE -j ACCEPT; iptables -A FORWARD -o $WG_INTERFACE -j ACCEPT; iptables -t nat -A POSTROUTING -o $WG_EXT_NIC -j MASQUERADE
PostDown = iptables -D FORWARD -i $WG_INTERFACE -j ACCEPT; iptables -D FORWARD -o $WG_INTERFACE -j ACCEPT; iptables -t nat -D POSTROUTING -o $WG_EXT_NIC -j MASQUERADE

# 客户端配置将在这里添加
EOF
    
    chmod 600 "$WG_CONFIG_DIR/$WG_INTERFACE.conf"
    echo -e "${GREEN}WireGuard配置已创建${NC}"
}

# 配置防火墙
configure_firewall() {
    echo -e "${YELLOW}正在配置防火墙...${NC}"
    
    # 检测防火墙类型
    if command -v ufw &> /dev/null; then
        ufw allow $WG_PORT/udp
        # UFW默认允许转发，但需要明确设置
        ufw default allow forward 2>/dev/null || echo "UFW forward policy already set"
        echo -e "${GREEN}UFW防火墙规则已配置${NC}"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=$WG_PORT/udp
        firewall-cmd --permanent --add-masquerade
        firewall-cmd --reload
        echo -e "${GREEN}firewalld防火墙规则已配置${NC}"
    else
        echo -e "${YELLOW}未检测到UFW或firewalld，将使用iptables规则（已在配置文件中设置）${NC}"
    fi
}

# 启动WireGuard服务
start_wireguard() {
    echo -e "${YELLOW}正在启动WireGuard服务...${NC}"
    
    systemctl enable wg-quick@$WG_INTERFACE
    systemctl start wg-quick@$WG_INTERFACE
    
    if systemctl is-active --quiet wg-quick@$WG_INTERFACE; then
        echo -e "${GREEN}WireGuard服务已启动${NC}"
        wg show
    else
        echo -e "${RED}WireGuard服务启动失败${NC}"
        systemctl status wg-quick@$WG_INTERFACE
        exit 1
    fi
}

# 保存服务器信息
save_server_info() {
    cat > "$WG_CONFIG_DIR/server_info.txt" <<EOF
服务器公网地址: $SERVER_PUBLIC_IP
WireGuard端口: $WG_PORT
VPN网络段: $WG_NETWORK
服务器VPN IP: $WG_SERVER_IP
配置文件位置: $WG_CONFIG_DIR/$WG_INTERFACE.conf
客户端配置目录: $WG_CLIENTS_DIR

服务器公钥:
$(cat $WG_CONFIG_DIR/server_public.key)

使用 manage.sh 脚本管理客户端:
  ./manage.sh add <客户端名称>    # 添加客户端
  ./manage.sh list                # 列出所有客户端
  ./manage.sh show <客户端名称>   # 显示客户端配置和二维码
  ./manage.sh remove <客户端名称> # 删除客户端
EOF
    
    chmod 644 "$WG_CONFIG_DIR/server_info.txt"
    echo -e "${GREEN}服务器信息已保存到: $WG_CONFIG_DIR/server_info.txt${NC}"
}

# 主函数
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  WireGuard VPN 服务器安装程序${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    check_root
    detect_os
    install_wireguard
    generate_server_keys
    get_server_ip
    create_wg_config
    configure_firewall
    start_wireguard
    save_server_info
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "服务器信息已保存到: ${YELLOW}$WG_CONFIG_DIR/server_info.txt${NC}"
    echo -e "使用 ${YELLOW}./manage.sh add <客户端名称>${NC} 添加第一个客户端"
    echo ""
}

main "$@"

