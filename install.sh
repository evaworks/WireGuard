#!/bin/bash

# WireGuard VPN 一键安装脚本
# 支持: curl -sL https://raw.githubusercontent.com/用户名/仓库/master/install.sh | sudo bash
# 或: wget -qO- https://raw.githubusercontent.com/用户名/仓库/master/install.sh | sudo bash

set -e

# GitHub配置 - 修改为你的GitHub仓库地址
GITHUB_REPO="https://raw.githubusercontent.com/evaworks/WireGuard/main/server"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置变量
WG_INTERFACE="wg0"
WG_PORT="51820"
WG_NETWORK="10.0.0.0/24"
WG_SERVER_IP="10.0.0.1"
WG_CONFIG_DIR="/etc/wireguard"
WG_CLIENTS_DIR="$WG_CONFIG_DIR/clients"
SCRIPT_DIR="/root/vpn"

# 解析参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --port)
                WG_PORT="$2"
                shift 2;;
            --ip)
                WG_SERVER_IP="$2"
                shift 2;;
            --domain)
                SERVER_PUBLIC_IP="$2"
                shift 2;;
            --repo)
                GITHUB_REPO="$2"
                shift 2;;
            -h|--help)
                show_help
                exit 0;;
            *)
                shift;;
        esac
    done
}

show_help() {
    echo -e "${BLUE}WireGuard VPN 一键安装脚本${NC}"
    echo ""
    echo "用法:"
    echo "  curl -sL https://raw.githubusercontent.com/用户名/仓库/master/install.sh | sudo bash"
    echo ""
    echo "参数:"
    echo "  --port <端口>      WireGuard监听端口 (默认: 51820)"
    echo "  --ip <IP>          VPN服务器IP (默认: 10.0.0.1)"
    echo "  --domain <域名>    服务器公网IP或域名 (自动检测)"
    echo "  --repo <仓库>      GitHub仓库地址 (可选)"
    echo "  -h, --help         显示帮助信息"
    echo ""
    echo "示例:"
    echo "  curl -sL ... | sudo bash"
    echo "  curl -sL ... | sudo bash -s -- --port 51820 --domain myserver.com"
}

# 下载必要文件
download_files() {
    echo -e "${YELLOW}正在下载必要文件...${NC}"
    
    mkdir -p "$SCRIPT_DIR/server"
    cd "$SCRIPT_DIR"
    
    # 下载manage.sh
    echo -e "下载 manage.sh..."
    curl -sL "$GITHUB_REPO/manage.sh" -o "$SCRIPT_DIR/server/manage.sh" || {
        echo -e "${RED}下载 manage.sh 失败，请检查网络或仓库地址${NC}"
        exit 1
    }
    
    # 下载wg0.conf.template
    echo -e "下载 wg0.conf.template..."
    curl -sL "$GITHUB_REPO/wg0.conf.template" -o "$SCRIPT_DIR/server/wg0.conf.template" || {
        echo -e "${RED}下载 wg0.conf.template 失败${NC}"
        exit 1
    }
    
    chmod +x "$SCRIPT_DIR/server/manage.sh"
    echo -e "${GREEN}文件下载完成${NC}"
}

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}请使用root权限运行此脚本${NC}"
        echo "使用: sudo $0"
        echo "或: curl ... | sudo bash"
        exit 1
    fi
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/debian_version ]; then
        OS=debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        OS=rhel
    else
        echo -e "${RED}无法检测操作系统类型${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}检测到操作系统: $OS $VER${NC}"
}

# 安装WireGuard
install_wireguard() {
    echo -e "${YELLOW}正在安装WireGuard...${NC}"
    
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        apt-get update
        apt-get install -y wireguard wireguard-tools qrencode iptables curl
        
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
            yum install -y kmod-wireguard wireguard-tools qrencode iptables curl
        else
            dnf install -y wireguard-tools qrencode iptables curl
        fi
        
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
    if [ -n "$SERVER_PUBLIC_IP" ]; then
        echo -e "${GREEN}使用指定服务器地址: $SERVER_PUBLIC_IP${NC}"
        return
    fi
    
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
    
    # 复制manage.sh到系统路径
    cp "$SCRIPT_DIR/server/manage.sh" /usr/local/bin/wg
    chmod +x /usr/local/bin/wg
    
    echo -e "${GREEN}WireGuard配置已创建${NC}"
}

# 配置防火墙
configure_firewall() {
    echo -e "${YELLOW}正在配置防火墙...${NC}"
    
    if command -v ufw &> /dev/null; then
        ufw allow $WG_PORT/udp
        ufw default allow forward 2>/dev/null || true
        echo -e "${GREEN}UFW防火墙规则已配置${NC}"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=$WG_PORT/udp
        firewall-cmd --permanent --add-masquerade
        firewall-cmd --reload
        echo -e "${GREEN}firewalld防火墙规则已配置${NC}"
    else
        echo -e "${YELLOW}未检测到UFW或firewalld，将使用iptables规则${NC}"
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
    SERVER_PUBLIC_KEY=$(cat "$WG_CONFIG_DIR/server_public.key")
    
    cat > "$WG_CONFIG_DIR/server_info.txt" <<EOF
========================================
WireGuard VPN 服务器信息
========================================

服务器地址: $SERVER_PUBLIC_IP
WireGuard端口: $WG_PORT
VPN网络段: $WG_NETWORK
服务器VPN IP: $WG_SERVER_IP

服务器公钥:
$SERVER_PUBLIC_KEY

客户端管理命令:
  wg add <客户端名称>    # 添加客户端
  wg list                # 列出所有客户端
  wg show <客户端名称>   # 显示客户端配置和二维码
  wg remove <客户端名称> # 删除客户端

========================================
EOF
    
    chmod 644 "$WG_CONFIG_DIR/server_info.txt"
    echo -e "${GREEN}服务器信息已保存${NC}"
}

# 主函数
main() {
    parse_args "$@"
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  WireGuard VPN 一键安装${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    check_root
    detect_os
    download_files
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
    echo -e "服务器地址: ${YELLOW}$SERVER_PUBLIC_IP${NC}"
    echo -e "WireGuard端口: ${YELLOW}$WG_PORT${NC}"
    echo -e "服务器公钥: ${YELLOW}$(cat $WG_CONFIG_DIR/server_public.key)${NC}"
    echo ""
    echo -e "添加客户端: ${YELLOW}wg add myphone${NC}"
    echo -e "查看信息: ${YELLOW}cat $WG_CONFIG_DIR/server_info.txt${NC}"
    echo ""
}

main "$@"
