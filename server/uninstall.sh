#!/bin/bash

# WireGuard VPN 服务器卸载脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 配置变量
WG_INTERFACE="wg0"
WG_CONFIG_DIR="/etc/wireguard"
WG_CLIENTS_DIR="$WG_CONFIG_DIR/clients"
WG_PORT="51820"

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}请使用root权限运行此脚本${NC}"
        echo "使用: sudo $0"
        exit 1
    fi
}

# 确认卸载
confirm_uninstall() {
    echo -e "${YELLOW}警告: 此操作将完全卸载WireGuard VPN服务器${NC}"
    echo -e "${YELLOW}包括所有客户端配置和密钥${NC}"
    echo ""
    read -p "确定要继续吗? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${GREEN}已取消卸载${NC}"
        exit 0
    fi
}

# 停止WireGuard服务
stop_wireguard() {
    echo -e "${YELLOW}正在停止WireGuard服务...${NC}"
    
    if systemctl is-active --quiet wg-quick@$WG_INTERFACE 2>/dev/null; then
        systemctl stop wg-quick@$WG_INTERFACE
        systemctl disable wg-quick@$WG_INTERFACE
        echo -e "${GREEN}WireGuard服务已停止${NC}"
    else
        echo -e "${YELLOW}WireGuard服务未运行${NC}"
    fi
}

# 清理防火墙规则
cleanup_firewall() {
    echo -e "${YELLOW}正在清理防火墙规则...${NC}"
    
    if command -v ufw &> /dev/null; then
        ufw delete allow $WG_PORT/udp 2>/dev/null || true
        echo -e "${GREEN}UFW防火墙规则已清理${NC}"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --remove-port=$WG_PORT/udp 2>/dev/null || true
        firewall-cmd --reload
        echo -e "${GREEN}firewalld防火墙规则已清理${NC}"
    fi
}

# 清理配置文件
cleanup_config() {
    echo -e "${YELLOW}正在清理配置文件...${NC}"
    
    if [ -d "$WG_CONFIG_DIR" ]; then
        # 备份配置（可选）
        read -p "是否备份配置文件? (yes/no): " backup
        if [ "$backup" == "yes" ]; then
            backup_dir="/root/wireguard_backup_$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$backup_dir"
            cp -r "$WG_CONFIG_DIR" "$backup_dir/"
            echo -e "${GREEN}配置文件已备份到: $backup_dir${NC}"
        fi
        
        rm -rf "$WG_CONFIG_DIR"
        echo -e "${GREEN}配置文件已删除${NC}"
    fi
}

# 卸载WireGuard软件包（可选）
uninstall_packages() {
    read -p "是否卸载WireGuard软件包? (yes/no): " uninstall_pkg
    
    if [ "$uninstall_pkg" == "yes" ]; then
        echo -e "${YELLOW}正在卸载WireGuard软件包...${NC}"
        
        if command -v apt-get &> /dev/null; then
            apt-get remove -y wireguard wireguard-tools qrencode 2>/dev/null || true
        elif command -v yum &> /dev/null; then
            yum remove -y wireguard-tools kmod-wireguard qrencode 2>/dev/null || true
        elif command -v dnf &> /dev/null; then
            dnf remove -y wireguard-tools qrencode 2>/dev/null || true
        fi
        
        echo -e "${GREEN}软件包已卸载${NC}"
    else
        echo -e "${YELLOW}保留软件包${NC}"
    fi
}

# 恢复IP转发设置（可选）
restore_ip_forward() {
    read -p "是否恢复IP转发设置? (yes/no): " restore
    
    if [ "$restore" == "yes" ]; then
        echo -e "${YELLOW}正在恢复IP转发设置...${NC}"
        sed -i '/net.ipv4.ip_forward=1/d' /etc/sysctl.conf
        sed -i '/net.ipv6.conf.all.forwarding=1/d' /etc/sysctl.conf
        sysctl -p
        echo -e "${GREEN}IP转发设置已恢复${NC}"
    else
        echo -e "${YELLOW}保留IP转发设置${NC}"
    fi
}

# 主函数
main() {
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  WireGuard VPN 服务器卸载程序${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    
    check_root
    confirm_uninstall
    
    stop_wireguard
    cleanup_firewall
    cleanup_config
    uninstall_packages
    restore_ip_forward
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  卸载完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

main "$@"

