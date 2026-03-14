# 文件上传指南

本文档说明如何将VPN项目文件上传到服务器。

## 方法一：使用自动上传脚本（推荐）

### 完整版脚本（upload-to-server.sh）

功能更全面，支持多种配置选项：

```bash
# 基本使用（会自动检测SSH密钥或提示输入密码）
./upload-to-server.sh

# 使用指定的SSH密钥
./upload-to-server.sh -i ~/.ssh/id_rsa

# 使用自定义端口
./upload-to-server.sh -p 2222

# 使用自定义服务器和用户
./upload-to-server.sh -s 192.168.1.100 -u admin
```

### 简化版脚本（upload-simple.sh）

更简单直接：

```bash
./upload-simple.sh
```

脚本会提示输入密码（如果未配置SSH密钥）。

## 方法二：手动使用SCP

### 基本命令

```bash
# 从项目目录执行
cd /Users/eva/Documents/Project/vpn

# 上传整个项目
scp -r /Users/eva/Documents/Project/vpn root@47.83.117.107:/root/
```

### 使用SSH密钥（推荐）

如果已配置SSH密钥，无需输入密码：

```bash
# 使用默认密钥
scp -r /Users/eva/Documents/Project/vpn root@47.83.117.107:/root/

# 使用指定密钥
scp -r -i ~/.ssh/id_rsa /Users/eva/Documents/Project/vpn root@47.83.117.107:/root/
```

### 使用密码

如果没有SSH密钥，会提示输入密码：

```bash
scp -r /Users/eva/Documents/Project/vpn root@47.83.117.107:/root/
# 然后输入密码
```

### 安装sshpass（可选，自动输入密码）

```bash
# macOS
brew install hudochenkov/sshpass/sshpass

# 然后使用
sshpass -p 'your_password' scp -r /Users/eva/Documents/Project/vpn root@47.83.117.107:/root/
```

## 方法三：使用rsync（适合更新文件）

rsync只传输有变化的文件，适合后续更新：

```bash
# 基本用法
rsync -avz -e ssh /Users/eva/Documents/Project/vpn/ root@47.83.117.107:/root/vpn/

# 排除不需要的文件
rsync -avz -e ssh --exclude='.git' /Users/eva/Documents/Project/vpn/ root@47.83.117.107:/root/vpn/
```

## 方法四：使用图形化工具

### macOS

1. **Cyberduck**
   - 下载：https://cyberduck.io/
   - 创建SFTP连接
   - 输入服务器IP、用户名、密码
   - 拖拽项目文件夹上传

2. **FileZilla**
   - 下载：https://filezilla-project.org/
   - 创建SFTP连接
   - 拖拽上传

## 配置SSH密钥（推荐，免密码）

### 生成SSH密钥对

```bash
# 在Mac上生成密钥对
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 按提示操作，默认保存在 ~/.ssh/id_rsa
```

### 将公钥复制到服务器

```bash
# 方法一：使用ssh-copy-id（最简单）
ssh-copy-id root@47.83.117.107

# 方法二：手动复制
cat ~/.ssh/id_rsa.pub | ssh root@47.83.117.107 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 测试SSH密钥登录

```bash
ssh root@47.83.117.107
# 如果不需要输入密码，说明配置成功
```

## 上传后验证

上传完成后，SSH登录服务器验证：

```bash
# SSH登录
ssh root@47.83.117.107

# 检查文件
ls -la /root/vpn

# 应该看到以下结构：
# vpn/
# ├── server/
# ├── shadowsocks/
# ├── docs/
# └── README.md
```

## 设置服务器端权限

上传后，在服务器上设置脚本权限：

```bash
ssh root@47.83.117.107
cd /root/vpn/server
chmod +x install.sh manage.sh uninstall.sh
```

或者使用上传脚本，它会自动设置权限。

## 常见问题

### 问题：Permission denied

**解决**：
- 检查用户名是否正确（默认是root）
- 检查服务器SSH服务是否运行
- 检查防火墙是否允许SSH连接

### 问题：连接超时

**解决**：
- 检查服务器IP是否正确
- 检查网络连接
- 检查服务器是否在线
- 检查SSH端口是否被防火墙阻止

### 问题：需要输入密码但不想每次输入

**解决**：
- 配置SSH密钥（见上方说明）
- 或使用sshpass工具

## 快速参考

```bash
# 使用自动脚本（最简单）
./upload-to-server.sh

# 或手动上传
scp -r /Users/eva/Documents/Project/vpn root@47.83.117.107:/root/

# 上传后登录服务器
ssh root@47.83.117.107
cd /root/vpn/server
sudo ./install.sh
```

