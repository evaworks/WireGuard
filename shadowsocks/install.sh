#!/bin/bash

# Shadowsocks 服务器安装脚本
# 轻量级代理方案，适合简单代理需求

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置变量
SS_PORT="8388"
SS_PASSWORD=""
SS_METHOD="aes-256-gcm"
SS_CONFIG_DIR="/etc/shadowsocks-libev"
SS_CONFIG_FILE="$SS_CONFIG_DIR/config.json"

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

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}请使用root权限运行此脚本${NC}"
        echo "使用: sudo $0"
        exit 1
    fi
}

# 生成随机密码
generate_password() {
    if [ -z "$SS_PASSWORD" ]; then
        SS_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        echo -e "${GREEN}已生成随机密码${NC}"
    fi
}

# 安装Shadowsocks
install_shadowsocks() {
    echo -e "${YELLOW}正在安装Shadowsocks-libev...${NC}"
    
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        apt-get update
        apt-get install -y shadowsocks-libev
        
    elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ]; then
        yum install -y epel-release
        yum install -y shadowsocks-libev
        
    elif [ "$OS" == "fedora" ]; then
        dnf install -y shadowsocks-libev
        
    else
        echo -e "${RED}不支持的操作系统: $OS${NC}"
        echo -e "${YELLOW}请手动安装shadowsocks-libev${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Shadowsocks安装完成${NC}"
}

# 创建配置文件
create_config() {
    echo -e "${YELLOW}正在创建配置文件...${NC}"
    
    mkdir -p "$SS_CONFIG_DIR"
    
    # 获取服务器IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    cat > "$SS_CONFIG_FILE" <<EOF
{
    "server": "0.0.0.0",
    "server_port": $SS_PORT,
    "password": "$SS_PASSWORD",
    "method": "$SS_METHOD",
    "timeout": 300,
    "fast_open": true,
    "mode": "tcp_and_udp"
}
EOF
    
    chmod 600 "$SS_CONFIG_FILE"
    echo -e "${GREEN}配置文件已创建: $SS_CONFIG_FILE${NC}"
}

# 配置防火墙
configure_firewall() {
    echo -e "${YELLOW}正在配置防火墙...${NC}"
    
    if command -v ufw &> /dev/null; then
        ufw allow $SS_PORT/tcp
        ufw allow $SS_PORT/udp
        echo -e "${GREEN}UFW防火墙规则已配置${NC}"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=$SS_PORT/tcp
        firewall-cmd --permanent --add-port=$SS_PORT/udp
        firewall-cmd --reload
        echo -e "${GREEN}firewalld防火墙规则已配置${NC}"
    else
        echo -e "${YELLOW}未检测到UFW或firewalld，请手动配置防火墙${NC}"
    fi
}

# 启动服务
start_service() {
    echo -e "${YELLOW}正在启动Shadowsocks服务...${NC}"
    
    systemctl enable shadowsocks-libev
    systemctl restart shadowsocks-libev
    
    if systemctl is-active --quiet shadowsocks-libev; then
        echo -e "${GREEN}Shadowsocks服务已启动${NC}"
    else
        echo -e "${RED}Shadowsocks服务启动失败${NC}"
        systemctl status shadowsocks-libev
        exit 1
    fi
}

# 显示配置信息
show_config() {
    SERVER_PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
    
    if [ -z "$SERVER_PUBLIC_IP" ]; then
        SERVER_PUBLIC_IP="<服务器IP>"
    fi
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Shadowsocks 配置信息${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "服务器地址: ${BLUE}$SERVER_PUBLIC_IP${NC}"
    echo -e "端口: ${BLUE}$SS_PORT${NC}"
    echo -e "密码: ${BLUE}$SS_PASSWORD${NC}"
    echo -e "加密方法: ${BLUE}$SS_METHOD${NC}"
    echo ""
    echo -e "${YELLOW}客户端配置URL (ss://):${NC}"
    
    # 生成ss:// URL
    SS_URL="ss://$(echo -n "$SS_METHOD:$SS_PASSWORD@$SERVER_PUBLIC_IP:$SS_PORT" | base64 -w 0)"
    echo -e "${BLUE}$SS_URL${NC}"
    echo ""
    echo -e "${YELLOW}二维码 (使用客户端扫描):${NC}"
    if command -v qrencode &> /dev/null; then
        echo "$SS_URL" | qrencode -t ANSIUTF8
    else
        echo -e "${YELLOW}请安装qrencode以显示二维码: apt-get install qrencode${NC}"
    fi
    echo ""
    echo -e "${GREEN}配置文件位置: $SS_CONFIG_FILE${NC}"
    echo ""
    echo -e "${YELLOW}常用命令:${NC}"
    echo "  查看状态: systemctl status shadowsocks-libev"
    echo "  重启服务: systemctl restart shadowsocks-libev"
    echo "  查看日志: journalctl -u shadowsocks-libev -f"
    echo ""
}

# 保存配置信息
save_config() {
    cat > "$SS_CONFIG_DIR/client_info.txt" <<EOF
Shadowsocks 客户端配置信息

服务器地址: $SERVER_PUBLIC_IP
端口: $SS_PORT
密码: $SS_PASSWORD
加密方法: $SS_METHOD

配置URL: ss://$(echo -n "$SS_METHOD:$SS_PASSWORD@$SERVER_PUBLIC_IP:$SS_PORT" | base64 -w 0)

客户端下载:
- Windows: https://github.com/shadowsocks/shadowsocks-windows/releases
- macOS: https://github.com/shadowsocks/ShadowsocksX-NG/releases
- Android: https://github.com/shadowsocks/shadowsocks-android/releases
- iOS: Shadowrocket, Quantumult X (App Store)

配置文件位置: $SS_CONFIG_FILE
EOF
    
    chmod 644 "$SS_CONFIG_DIR/client_info.txt"
    echo -e "${GREEN}配置信息已保存到: $SS_CONFIG_DIR/client_info.txt${NC}"
}

# 主函数
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Shadowsocks 服务器安装程序${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    check_root
    detect_os
    
    # 询问配置
    read -p "Shadowsocks端口 [$SS_PORT]: " input_port
    SS_PORT=${input_port:-$SS_PORT}
    
    read -p "密码 (留空自动生成): " input_password
    SS_PASSWORD=${input_password:-""}
    
    read -p "加密方法 [$SS_METHOD]: " input_method
    SS_METHOD=${input_method:-$SS_METHOD}
    
    generate_password
    install_shadowsocks
    create_config
    configure_firewall
    start_service
    
    SERVER_PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
    save_config
    show_config
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

main "$@"

