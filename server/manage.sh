#!/bin/bash

# WireGuard 客户端管理脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置变量
WG_INTERFACE="wg0"
WG_CONFIG_DIR="/etc/wireguard"
WG_CLIENTS_DIR="$WG_CONFIG_DIR/clients"
WG_CONFIG_FILE="$WG_CONFIG_DIR/$WG_INTERFACE.conf"
WG_NETWORK="10.0.0.0/24"
WG_SERVER_IP="10.0.0.1"

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}请使用root权限运行此脚本${NC}"
        echo "使用: sudo $0"
        exit 1
    fi
}

# 获取下一个可用的客户端IP
get_next_client_ip() {
    local last_ip=$(grep -oP 'AllowedIPs = \K10\.0\.0\.\d+' "$WG_CONFIG_FILE" 2>/dev/null | sort -t. -k4 -n | tail -1)
    
    if [ -z "$last_ip" ]; then
        echo "10.0.0.2"
    else
        local last_num=$(echo "$last_ip" | cut -d. -f4)
        local next_num=$((last_num + 1))
        echo "10.0.0.$next_num"
    fi
}

# 获取服务器信息
get_server_info() {
    if [ -f "$WG_CONFIG_DIR/server_info.txt" ]; then
        SERVER_PUBLIC_IP=$(grep "服务器公网地址:" "$WG_CONFIG_DIR/server_info.txt" | cut -d: -f2 | xargs)
        WG_PORT=$(grep "WireGuard端口:" "$WG_CONFIG_DIR/server_info.txt" | cut -d: -f2 | xargs)
    else
        SERVER_PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
        WG_PORT="51820"
    fi
    
    if [ -z "$SERVER_PUBLIC_IP" ]; then
        read -p "请输入服务器公网IP或域名: " SERVER_PUBLIC_IP
    fi
}

# 添加客户端
add_client() {
    local client_name="$1"
    
    if [ -z "$client_name" ]; then
        echo -e "${RED}错误: 请提供客户端名称${NC}"
        echo "用法: $0 add <客户端名称>"
        exit 1
    fi
    
    # 检查客户端是否已存在
    if [ -f "$WG_CLIENTS_DIR/$client_name.conf" ]; then
        echo -e "${RED}错误: 客户端 '$client_name' 已存在${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}正在添加客户端: $client_name${NC}"
    
    # 生成客户端密钥
    local client_private_key=$(wg genkey)
    local client_public_key=$(echo "$client_private_key" | wg pubkey)
    
    # 获取客户端IP
    local client_ip=$(get_next_client_ip)
    
    # 获取服务器信息
    get_server_info
    
    # 获取服务器公钥
    local server_public_key=$(cat "$WG_CONFIG_DIR/server_public.key")
    
    # 创建客户端配置文件
    mkdir -p "$WG_CLIENTS_DIR"
    cat > "$WG_CLIENTS_DIR/$client_name.conf" <<EOF
[Interface]
PrivateKey = $client_private_key
Address = $client_ip/24
DNS = 223.5.5.5, 8.8.8.8, 1.1.1.1

[Peer]
PublicKey = $server_public_key
Endpoint = $SERVER_PUBLIC_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
    
    chmod 600 "$WG_CLIENTS_DIR/$client_name.conf"
    
    # 将客户端添加到服务器配置
    if ! grep -q "\[Peer\]" "$WG_CONFIG_FILE" || ! grep -q "$client_name" "$WG_CONFIG_FILE"; then
        cat >> "$WG_CONFIG_FILE" <<EOF

# Client: $client_name
[Peer]
PublicKey = $client_public_key
AllowedIPs = $client_ip/32
EOF
    fi
    
    # 重新加载WireGuard配置
    # 检查接口是否存在
    if ip link show $WG_INTERFACE &>/dev/null; then
        # 接口已存在，使用syncconf更新配置
        wg syncconf $WG_INTERFACE <(wg-quick strip $WG_INTERFACE) 2>/dev/null || {
            echo -e "${YELLOW}警告: 配置同步失败，尝试重启服务...${NC}"
            systemctl restart wg-quick@$WG_INTERFACE
        }
    else
        # 接口不存在，需要启动服务
        echo -e "${YELLOW}WireGuard接口未启动，正在启动服务...${NC}"
        systemctl start wg-quick@$WG_INTERFACE || {
            echo -e "${RED}错误: 无法启动WireGuard服务${NC}"
            echo -e "${YELLOW}请检查配置文件: $WG_CONFIG_FILE${NC}"
            exit 1
        }
    fi
    
    echo -e "${GREEN}客户端 '$client_name' 已添加${NC}"
    echo -e "客户端IP: ${BLUE}$client_ip${NC}"
    echo -e "配置文件: ${BLUE}$WG_CLIENTS_DIR/$client_name.conf${NC}"
    echo ""
    echo -e "${YELLOW}客户端配置:${NC}"
    cat "$WG_CLIENTS_DIR/$client_name.conf"
    echo ""
    
    # 显示二维码
    if command -v qrencode &> /dev/null; then
        echo -e "${YELLOW}二维码:${NC}"
        qrencode -t ANSIUTF8 < "$WG_CLIENTS_DIR/$client_name.conf"
    fi
}

# 列出所有客户端
list_clients() {
    echo -e "${GREEN}已配置的客户端:${NC}"
    echo ""
    
    if [ ! -d "$WG_CLIENTS_DIR" ] || [ -z "$(ls -A $WG_CLIENTS_DIR 2>/dev/null)" ]; then
        echo -e "${YELLOW}暂无客户端${NC}"
        return
    fi
    
    printf "%-20s %-15s %-20s\n" "客户端名称" "IP地址" "状态"
    echo "------------------------------------------------------------"
    
    for conf_file in "$WG_CLIENTS_DIR"/*.conf; do
        if [ -f "$conf_file" ]; then
            local client_name=$(basename "$conf_file" .conf)
            local client_ip=$(grep "Address = " "$conf_file" | awk '{print $3}' | cut -d/ -f1)
            local client_pubkey=$(grep -A 5 "\[Peer\]" "$WG_CONFIG_FILE" | grep -B 5 "$client_name" | grep "PublicKey" | awk '{print $3}' | head -1)
            
            if wg show "$WG_INTERFACE" | grep -q "$client_pubkey"; then
                local status="${GREEN}已连接${NC}"
                local transfer=$(wg show "$WG_INTERFACE" | grep "$client_pubkey" -A 2 | grep "transfer" | awk '{print $2, $3}')
            else
                local status="${YELLOW}未连接${NC}"
                local transfer="-"
            fi
            
            printf "%-20s %-15s %s\n" "$client_name" "$client_ip" "$status"
            if [ "$transfer" != "-" ]; then
                echo "  传输: $transfer"
            fi
        fi
    done
    echo ""
}

# 显示客户端配置
show_client() {
    local client_name="$1"
    
    if [ -z "$client_name" ]; then
        echo -e "${RED}错误: 请提供客户端名称${NC}"
        echo "用法: $0 show <客户端名称>"
        exit 1
    fi
    
    local conf_file="$WG_CLIENTS_DIR/$client_name.conf"
    
    if [ ! -f "$conf_file" ]; then
        echo -e "${RED}错误: 客户端 '$client_name' 不存在${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}客户端配置: $client_name${NC}"
    echo ""
    cat "$conf_file"
    echo ""
    
    # 显示二维码
    if command -v qrencode &> /dev/null; then
        echo -e "${YELLOW}二维码 (扫描以导入配置):${NC}"
        qrencode -t ANSIUTF8 < "$conf_file"
        echo ""
        echo -e "${YELLOW}或使用以下命令获取配置文件:${NC}"
        echo "cat $conf_file"
    fi
}

# 删除客户端
remove_client() {
    local client_name="$1"
    
    if [ -z "$client_name" ]; then
        echo -e "${RED}错误: 请提供客户端名称${NC}"
        echo "用法: $0 remove <客户端名称>"
        exit 1
    fi
    
    local conf_file="$WG_CLIENTS_DIR/$client_name.conf"
    
    if [ ! -f "$conf_file" ]; then
        echo -e "${RED}错误: 客户端 '$client_name' 不存在${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}正在删除客户端: $client_name${NC}"
    
    # 从服务器配置中移除客户端
    local client_pubkey=$(grep -A 5 "\[Peer\]" "$WG_CONFIG_FILE" | grep -B 5 "$client_name" | grep "PublicKey" | awk '{print $3}' | head -1)
    
    if [ -n "$client_pubkey" ]; then
        # 使用sed删除客户端配置块
        sed -i "/# Client: $client_name/,/^$/d" "$WG_CONFIG_FILE"
        
        # 重新加载配置
        if ip link show $WG_INTERFACE &>/dev/null; then
            wg syncconf $WG_INTERFACE <(wg-quick strip $WG_INTERFACE) 2>/dev/null || {
                systemctl restart wg-quick@$WG_INTERFACE
            }
        fi
    fi
    
    # 删除客户端配置文件
    rm -f "$conf_file"
    
    echo -e "${GREEN}客户端 '$client_name' 已删除${NC}"
}

# 显示使用帮助
show_help() {
    cat <<EOF
WireGuard 客户端管理脚本

用法: $0 <命令> [参数]

命令:
  add <客户端名称>     添加新客户端
  list                 列出所有客户端
  show <客户端名称>    显示客户端配置和二维码
  remove <客户端名称>  删除客户端
  help                 显示此帮助信息

示例:
  $0 add myphone        # 添加名为 'myphone' 的客户端
  $0 list               # 列出所有客户端
  $0 show myphone       # 显示 'myphone' 的配置
  $0 remove myphone     # 删除 'myphone' 客户端

EOF
}

# 主函数
main() {
    check_root
    
    case "${1:-}" in
        add)
            add_client "$2"
            ;;
        list)
            list_clients
            ;;
        show)
            show_client "$2"
            ;;
        remove)
            remove_client "$2"
            ;;
        help|--help|-h|"")
            show_help
            ;;
        *)
            echo -e "${RED}错误: 未知命令 '$1'${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"

