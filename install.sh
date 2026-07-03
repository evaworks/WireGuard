#!/bin/bash

# WireGuard VPN 一键安装脚本

set -e

# GitHub配置
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
FORCE=false

# 解析参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --port)
                WG_PORT="$2"
                shift 2;;
            --domain)
                SERVER_PUBLIC_IP="$2"
                shift 2;;
            -f|--force)
                FORCE=true
                shift;;
            -h|--help)
                show_help
                exit 0;;
            *)
                shift;;
        esac
    done
}

show_help() {
    echo -e "${BLUE}WireGuard VPN 一键安装${NC}"
    echo ""
    echo "用法: curl -sL https://.../install.sh | sudo bash"
    echo ""
    echo "参数:"
    echo "  --port <端口>   端口 (默认: 51820)"
    echo "  --domain <域名> 服务器域名/IP"
    echo "  -f, --force     强制重装（清理旧配置后重新安装）"
}

# 卸载旧版本
cleanup_old() {
    echo -e "${YELLOW}正在清理旧版本...${NC}"
    
    # 停止并禁用服务
    systemctl stop wg-quick@$WG_INTERFACE 2>/dev/null || true
    systemctl disable wg-quick@$WG_INTERFACE 2>/dev/null || true
    
    # 清理防火墙规则
    if command -v ufw &> /dev/null; then
        ufw delete allow $WG_PORT/udp 2>/dev/null || true
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --remove-port=$WG_PORT/udp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
    fi
    
    # 删除配置文件和密钥
    rm -rf "$WG_CONFIG_DIR"
    
    # 删除管理脚本
    rm -f /usr/local/bin/wgm /usr/local/bin/wg
    
    echo -e "${GREEN}旧版本已清理${NC}"
}

# 下载manage.sh
download_manage() {
    echo -e "${YELLOW}正在下载管理脚本...${NC}"
    # 删除旧版冲突的 wg 命令（若存在）
    rm -f /usr/local/bin/wg
    curl -sL "$GITHUB_REPO/manage.sh" -o /usr/local/bin/wgm
    chmod +x /usr/local/bin/wgm
    echo -e "${GREEN}下载完成${NC}"
    echo -e "${YELLOW}管理命令: wgm add/list/show/remove${NC}"
}

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}请使用root权限运行${NC}"
        exit 1
    fi
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    elif [ -f /etc/debian_version ]; then
        OS=debian
    else
        OS=rhel
    fi
    echo -e "${GREEN}检测到: $OS${NC}"
}

# 安装WireGuard
install_wireguard() {
    echo -e "${YELLOW}正在安装WireGuard...${NC}"
    
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        apt-get update
        apt-get install -y wireguard wireguard-tools qrencode iptables curl
        
    elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ]; then
        if [ "$OS" == "centos" ] || [ "$OS" == "rhel" ]; then
            yum install -y epel-release elrepo-release
            yum install -y kmod-wireguard wireguard-tools qrencode iptables curl
        else
            dnf install -y wireguard-tools qrencode iptables curl
        fi
    fi
    
    # 启用IP转发
    grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p
    
    echo -e "${GREEN}安装完成${NC}"
}

# 生成密钥
generate_keys() {
    echo -e "${YELLOW}正在生成密钥...${NC}"
    mkdir -p "$WG_CONFIG_DIR"
    
    # 检查现有密钥是否有效（WireGuard私钥为44位base64，以=结尾）
    local key_valid=false
    if [ -f "$WG_CONFIG_DIR/server_private.key" ]; then
        local key_content=$(cat "$WG_CONFIG_DIR/server_private.key")
        if echo "$key_content" | wg pubkey &>/dev/null 2>&1; then
            key_valid=true
        fi
    fi
    
    if [ "$key_valid" != true ]; then
        wg genkey | tee "$WG_CONFIG_DIR/server_private.key" | wg pubkey > "$WG_CONFIG_DIR/server_public.key"
        chmod 600 "$WG_CONFIG_DIR/server_private.key"
    fi
    echo -e "${GREEN}密钥生成完成${NC}"
}

# 获取服务器IP
get_server_ip() {
    if [ -z "$SERVER_PUBLIC_IP" ]; then
        SERVER_PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
    fi
    if [ -z "$SERVER_PUBLIC_IP" ]; then
        read -p "请输入服务器IP/域名: " SERVER_PUBLIC_IP </dev/tty
    fi
    if [ -z "$SERVER_PUBLIC_IP" ]; then
        echo -e "${RED}错误: 无法获取服务器IP，请使用 --domain 参数指定${NC}"
        exit 1
    fi
    echo -e "${GREEN}服务器: $SERVER_PUBLIC_IP${NC}"
}

# 创建配置
create_config() {
    echo -e "${YELLOW}正在创建配置...${NC}"
    
    SERVER_PRIVATE_KEY=$(cat "$WG_CONFIG_DIR/server_private.key")
    WG_EXT_NIC=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \K[^ ]+' || echo "eth0")
    
    cat > "$WG_CONFIG_DIR/$WG_INTERFACE.conf" <<EOF
[Interface]
Address = $WG_SERVER_IP/24
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIVATE_KEY
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $WG_EXT_NIC -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $WG_EXT_NIC -j MASQUERADE
EOF
    
    chmod 600 "$WG_CONFIG_DIR/$WG_INTERFACE.conf"
    echo -e "${GREEN}配置创建完成${NC}"
}

# 配置防火墙
configure_firewall() {
    echo -e "${YELLOW}配置防火墙...${NC}"
    
    if command -v ufw &> /dev/null; then
        ufw allow $WG_PORT/udp
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=$WG_PORT/udp
        firewall-cmd --permanent --add-masquerade
        firewall-cmd --reload
    fi
    echo -e "${GREEN}防火墙配置完成${NC}"
}

# 启动服务
start_wireguard() {
    echo -e "${YELLOW}启动WireGuard...${NC}"
    systemctl enable wg-quick@$WG_INTERFACE
    systemctl start wg-quick@$WG_INTERFACE
    
    if systemctl is-active --quiet wg-quick@$WG_INTERFACE; then
        echo -e "${GREEN}服务已启动${NC}"
    else
        echo -e "${RED}启动失败${NC}"
        exit 1
    fi
}

# 保存信息
save_info() {
    cat > "$WG_CONFIG_DIR/server_info.txt" <<EOF
服务器: $SERVER_PUBLIC_IP
端口: $WG_PORT
公钥: $(cat $WG_CONFIG_DIR/server_public.key)

    管理命令: wgm add/list/show/remove
EOF
}

# 主函数
main() {
    parse_args "$@"
    
    echo -e "${BLUE}=============================${NC}"
    echo -e "${BLUE}  WireGuard VPN 一键安装${NC}"
    echo -e "${BLUE}=============================${NC}"
    
    check_root
    
    if [ "$FORCE" = true ]; then
        cleanup_old
    fi
    
    detect_os
    download_manage
    install_wireguard
    generate_keys
    get_server_ip
    create_config
    configure_firewall
    start_wireguard
    save_info
    
    echo ""
    echo -e "${GREEN}安装完成!${NC}"
    echo ""
    echo -e "服务器: ${YELLOW}$SERVER_PUBLIC_IP${NC}"
    echo -e "端口: ${YELLOW}$WG_PORT${NC}"
    echo -e "公钥: ${YELLOW}$(cat $WG_CONFIG_DIR/server_public.key)${NC}"
    echo ""
    echo -e "添加客户端: ${YELLOW}wgm add myphone${NC}"
}

main "$@"
