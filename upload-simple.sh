#!/bin/bash

# 简化版上传脚本 - 只上传server目录
# 如果已配置SSH密钥，可以直接使用，否则会提示输入密码

set -e

# 服务器配置
SERVER_IP="47.83.117.107"
SERVER_USER="root"
SERVER_PATH="/root/vpn"

# 本地项目路径
LOCAL_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$LOCAL_PATH/server"

echo "=========================================="
echo "  上传server目录到服务器"
echo "=========================================="
echo ""
echo "服务器: $SERVER_USER@$SERVER_IP"
echo "目标路径: $SERVER_PATH/server"
echo "本地路径: $SERVER_DIR"
echo ""

# 检查server目录是否存在
if [ ! -d "$SERVER_DIR" ]; then
    echo "错误: server目录不存在: $SERVER_DIR"
    exit 1
fi

# 先在服务器上创建目标目录
echo "正在创建服务器目录..."
ssh "$SERVER_USER@$SERVER_IP" "mkdir -p $SERVER_PATH" || {
    echo "错误: 无法连接到服务器或创建目录"
    exit 1
}

# 上传server目录
echo "正在上传server目录..."
scp -r "$SERVER_DIR" "$SERVER_USER@$SERVER_IP:$SERVER_PATH/"

echo ""
echo "✓ 上传完成！"
echo ""
echo "下一步："
echo "1. SSH登录: ssh $SERVER_USER@$SERVER_IP"
echo "2. 进入目录: cd $SERVER_PATH/server"
echo "3. 运行安装: sudo ./install.sh"
echo ""

