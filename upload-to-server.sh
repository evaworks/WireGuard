#!/bin/bash

# 自动上传server目录到服务器
# 只上传server目录，不包含docs、shadowsocks等其他文件
# 支持SSH密钥和密码两种方式

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 服务器配置
SERVER_IP="47.83.117.107"
SERVER_USER="root"
SERVER_PORT="22"
SERVER_PATH="/root/vpn"

# 本地项目路径
LOCAL_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$LOCAL_PATH/server"

# 检查必要的工具
check_tools() {
    if ! command -v scp &> /dev/null; then
        echo -e "${RED}错误: 未找到 scp 命令${NC}"
        echo "请安装 OpenSSH 客户端"
        exit 1
    fi
    
    if ! command -v ssh &> /dev/null; then
        echo -e "${RED}错误: 未找到 ssh 命令${NC}"
        echo "请安装 OpenSSH 客户端"
        exit 1
    fi
}

# 测试服务器连接
test_connection() {
    echo -e "${YELLOW}正在测试服务器连接...${NC}"
    
    if ssh -o ConnectTimeout=5 -o BatchMode=yes -p "$SERVER_PORT" "$SERVER_USER@$SERVER_IP" "echo '连接成功'" 2>/dev/null; then
        echo -e "${GREEN}✓ 使用SSH密钥连接成功${NC}"
        USE_PASSWORD=false
        return 0
    else
        echo -e "${YELLOW}SSH密钥连接失败，将使用密码方式${NC}"
        USE_PASSWORD=true
        return 1
    fi
}

# 创建服务器目录
create_server_dir() {
    echo -e "${YELLOW}正在创建服务器目录...${NC}"
    
    if [ "$USE_PASSWORD" = true ]; then
        if command -v sshpass &> /dev/null; then
            sshpass -p "$SERVER_PASSWORD" ssh -p "$SERVER_PORT" "$SERVER_USER@$SERVER_IP" "mkdir -p $SERVER_PATH" || {
                echo -e "${RED}无法创建服务器目录${NC}"
                exit 1
            }
        else
            ssh -p "$SERVER_PORT" "$SERVER_USER@$SERVER_IP" "mkdir -p $SERVER_PATH" || {
                echo -e "${RED}无法创建服务器目录${NC}"
                exit 1
            }
        fi
    else
        ssh -p "$SERVER_PORT" "$SERVER_USER@$SERVER_IP" "mkdir -p $SERVER_PATH" || {
            echo -e "${RED}无法创建服务器目录${NC}"
            exit 1
        }
    fi
}

# 使用密码上传（需要sshpass）
upload_with_password() {
    # 检查server目录是否存在
    if [ ! -d "$SERVER_DIR" ]; then
        echo -e "${RED}错误: server目录不存在: $SERVER_DIR${NC}"
        exit 1
    fi
    
    if ! command -v sshpass &> /dev/null; then
        echo -e "${YELLOW}未安装 sshpass，将提示您输入密码${NC}"
        echo -e "${BLUE}请输入服务器密码:${NC}"
        read -s SERVER_PASSWORD
        
        create_server_dir
        
        echo -e "${YELLOW}正在上传server目录到服务器...${NC}"
        scp -r -P "$SERVER_PORT" "$SERVER_DIR" "$SERVER_USER@$SERVER_IP:$SERVER_PATH/" || {
            echo -e "${RED}上传失败，请检查密码和网络连接${NC}"
            exit 1
        }
    else
        echo -e "${BLUE}请输入服务器密码:${NC}"
        read -s SERVER_PASSWORD
        
        create_server_dir
        
        echo -e "${YELLOW}正在上传server目录到服务器...${NC}"
        sshpass -p "$SERVER_PASSWORD" scp -r -P "$SERVER_PORT" "$SERVER_DIR" "$SERVER_USER@$SERVER_IP:$SERVER_PATH/" || {
            echo -e "${RED}上传失败，请检查密码和网络连接${NC}"
            exit 1
        }
    fi
}

# 使用SSH密钥上传
upload_with_key() {
    # 检查server目录是否存在
    if [ ! -d "$SERVER_DIR" ]; then
        echo -e "${RED}错误: server目录不存在: $SERVER_DIR${NC}"
        exit 1
    fi
    
    # 先创建服务器目录
    echo -e "${YELLOW}正在创建服务器目录...${NC}"
    ssh -p "$SERVER_PORT" "$SERVER_USER@$SERVER_IP" "mkdir -p $SERVER_PATH" || {
        echo -e "${RED}无法创建服务器目录${NC}"
        exit 1
    }
    
    echo -e "${YELLOW}正在上传server目录到服务器...${NC}"
    
    # 尝试使用默认密钥
    scp -r -P "$SERVER_PORT" "$SERVER_DIR" "$SERVER_USER@$SERVER_IP:$SERVER_PATH/" || {
        echo -e "${RED}上传失败${NC}"
        echo -e "${YELLOW}提示: 如果使用自定义密钥，请使用 -i 参数指定密钥路径${NC}"
        exit 1
    }
}

# 验证上传
verify_upload() {
    echo -e "${YELLOW}正在验证上传...${NC}"
    
    if ssh -p "$SERVER_PORT" "$SERVER_USER@$SERVER_IP" "test -d $SERVER_PATH/server && echo '目录存在'" 2>/dev/null; then
        echo -e "${GREEN}✓ 上传验证成功${NC}"
        
        # 显示服务器上的文件结构
        echo -e "${BLUE}服务器上的文件结构:${NC}"
        ssh -p "$SERVER_PORT" "$SERVER_USER@$SERVER_IP" "ls -la $SERVER_PATH/server" 2>/dev/null || true
    else
        echo -e "${YELLOW}警告: 无法验证上传，请手动检查${NC}"
    fi
}

# 设置服务器端权限
setup_permissions() {
    echo -e "${YELLOW}正在设置服务器端文件权限...${NC}"
    
    ssh -p "$SERVER_PORT" "$SERVER_USER@$SERVER_IP" << EOF
        cd $SERVER_PATH/server 2>/dev/null || exit 1
        chmod +x install.sh manage.sh uninstall.sh 2>/dev/null || true
        echo "权限设置完成"
EOF
    
    echo -e "${GREEN}✓ 权限设置完成${NC}"
}

# 主函数
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  server目录上传工具${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "服务器地址: ${BLUE}$SERVER_IP${NC}"
    echo -e "目标路径: ${BLUE}$SERVER_PATH/server${NC}"
    echo -e "本地路径: ${BLUE}$SERVER_DIR${NC}"
    echo ""
    
    check_tools
    
    # 测试连接
    if test_connection; then
        upload_with_key
    else
        upload_with_password
    fi
    
    verify_upload
    setup_permissions
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  上传完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "下一步操作:"
    echo -e "1. SSH登录服务器: ${YELLOW}ssh $SERVER_USER@$SERVER_IP${NC}"
    echo -e "2. 进入项目目录: ${YELLOW}cd $SERVER_PATH/server${NC}"
    echo -e "3. 运行安装脚本: ${YELLOW}sudo ./install.sh${NC}"
    echo ""
}

# 显示帮助信息
show_help() {
    cat << EOF
VPN项目文件上传工具

用法: $0 [选项]

选项:
  -h, --help          显示帮助信息
  -i, --key <path>    指定SSH密钥路径
  -p, --port <port>   指定SSH端口（默认: 22）
  -u, --user <user>   指定SSH用户（默认: root）
  -s, --server <ip>   指定服务器IP（默认: 47.83.117.107）

示例:
  $0                                    # 使用默认配置
  $0 -i ~/.ssh/id_rsa                  # 使用指定密钥
  $0 -p 2222                           # 使用自定义端口
  $0 -s 192.168.1.100 -u admin         # 使用自定义服务器和用户

EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--key)
            SSH_KEY="$2"
            shift 2
            ;;
        -p|--port)
            SERVER_PORT="$2"
            shift 2
            ;;
        -u|--user)
            SERVER_USER="$2"
            shift 2
            ;;
        -s|--server)
            SERVER_IP="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}未知参数: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 如果指定了SSH密钥，使用它
if [ -n "$SSH_KEY" ]; then
    if [ -f "$SSH_KEY" ]; then
        echo -e "${GREEN}使用指定的SSH密钥: $SSH_KEY${NC}"
        # 修改scp和ssh命令使用指定密钥
        scp() { command scp -i "$SSH_KEY" "$@"; }
        ssh() { command ssh -i "$SSH_KEY" "$@"; }
    else
        echo -e "${RED}错误: SSH密钥文件不存在: $SSH_KEY${NC}"
        exit 1
    fi
fi

main "$@"

