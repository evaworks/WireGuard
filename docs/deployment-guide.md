# 部署和使用指南

本文档详细说明如何将VPN项目部署到服务器，以及如何在本地配置和使用。

## 目录

1. [上传文件到服务器](#上传文件到服务器)
2. [服务器端安装](#服务器端安装)
3. [本地客户端配置](#本地客户端配置)
4. [验证和测试](#验证和测试)

---

## 上传文件到服务器

### 方法一：使用 SCP（推荐）

SCP是最常用的文件传输方法，适合一次性上传整个项目。

#### 1. 准备本地文件

确保您已经下载或克隆了项目到本地：

```bash
# 如果项目在本地，进入项目目录
cd /Users/eva/Documents/Project/vpn

# 查看项目结构
ls -la
```

#### 2. 上传整个项目目录

```bash
# 基本语法
scp -r /Users/eva/Documents/Project/vpn root@<服务器IP>:/root/

# 示例（替换为您的服务器IP）
scp -r /Users/eva/Documents/Project/vpn root@123.45.67.89:/root/

# 如果使用非标准SSH端口
scp -r -P 2222 /Users/eva/Documents/Project/vpn root@123.45.67.89:/root/
```

**参数说明**：
- `-r`: 递归复制整个目录
- `-P`: 指定SSH端口（如果使用非22端口）

#### 3. 使用密钥认证（推荐）

如果使用SSH密钥登录，不需要每次都输入密码：

```bash
# 使用指定的密钥文件
scp -r -i ~/.ssh/id_rsa /Users/eva/Documents/Project/vpn root@123.45.67.89:/root/
```

#### 4. 上传后验证

```bash
# SSH登录到服务器
ssh root@<服务器IP>

# 检查文件是否上传成功
cd /root/vpn
ls -la
```

### 方法二：使用 SFTP

SFTP提供交互式文件传输，适合需要选择性上传的场景。

#### 1. 连接服务器

```bash
sftp root@<服务器IP>
```

#### 2. 在SFTP中操作

```bash
# 进入服务器目录
cd /root

# 创建vpn目录
mkdir vpn
cd vpn

# 切换到本地目录（在另一个终端或使用lcd命令）
# 在SFTP中，使用 put 命令上传文件
put -r /Users/eva/Documents/Project/vpn/* .

# 退出SFTP
exit
```

### 方法三：使用 rsync（推荐用于更新）

rsync适合需要同步或更新文件的场景，只传输有变化的文件。

```bash
# 基本语法
rsync -avz -e ssh /Users/eva/Documents/Project/vpn/ root@<服务器IP>:/root/vpn/

# 参数说明：
# -a: 归档模式，保持文件属性
# -v: 详细输出
# -z: 压缩传输
# -e: 指定远程shell

# 排除不需要的文件（如果有）
rsync -avz -e ssh --exclude='.git' /Users/eva/Documents/Project/vpn/ root@<服务器IP>:/root/vpn/
```

### 方法四：使用 Git（如果服务器已安装Git）

如果项目托管在Git仓库，可以直接在服务器上克隆：

```bash
# SSH登录服务器
ssh root@<服务器IP>

# 克隆项目
cd /root
git clone <您的Git仓库地址> vpn

# 或直接下载ZIP文件
wget <ZIP文件URL>
unzip vpn.zip
```

### 方法五：使用图形化工具

#### macOS - Cyberduck / FileZilla

1. 下载并安装 [Cyberduck](https://cyberduck.io/) 或 [FileZilla](https://filezilla-project.org/)
2. 创建新的SFTP连接
3. 输入服务器IP、用户名、密码
4. 连接后，拖拽项目文件夹到服务器

#### Windows - WinSCP / FileZilla

1. 下载并安装 [WinSCP](https://winscp.net/) 或 FileZilla
2. 创建SFTP连接
3. 上传项目文件夹

---

## 服务器端安装

### 1. SSH登录服务器

```bash
ssh root@<服务器IP>

# 或使用密钥
ssh -i ~/.ssh/id_rsa root@<服务器IP>
```

### 2. 进入项目目录

```bash
cd /root/vpn
ls -la
```

应该看到以下结构：
```
vpn/
├── server/
│   ├── install.sh
│   ├── manage.sh
│   ├── uninstall.sh
│   └── wg0.conf.template
├── shadowsocks/
├── docs/
└── README.md
```

### 3. 设置脚本权限

```bash
cd server
chmod +x install.sh manage.sh uninstall.sh
```

### 4. 运行安装脚本

```bash
sudo ./install.sh
```

**安装过程**：
- 脚本会自动检测操作系统
- 安装WireGuard和相关工具
- 生成服务器密钥
- 配置防火墙
- 启动服务

**注意事项**：
- 确保服务器有root权限或sudo权限
- 确保服务器可以访问外网（用于下载软件包）
- 安装过程可能需要几分钟

### 5. 安装完成后的操作

安装完成后，脚本会显示：
- 服务器信息
- 服务器公钥
- 下一步操作提示

**保存服务器信息**：
```bash
cat /etc/wireguard/server_info.txt
```

### 6. 添加第一个客户端

```bash
# 为您的设备添加配置（客户端名可以自定义）
sudo ./manage.sh add myphone

# 示例输出会显示：
# - 客户端配置文件内容
# - 二维码（用于移动设备扫描）
```

### 7. 查看客户端配置

```bash
# 列出所有客户端
sudo ./manage.sh list

# 查看特定客户端配置和二维码
sudo ./manage.sh show myphone
```

### 8. 获取客户端配置文件

**方法一：直接查看并复制**

```bash
# 查看配置文件内容
cat /etc/wireguard/clients/myphone.conf
```

复制输出的内容，保存到本地文件（如 `myphone.conf`）

**方法二：使用SCP下载**

在本地终端执行：

```bash
# 下载客户端配置文件
scp root@<服务器IP>:/etc/wireguard/clients/myphone.conf ~/Downloads/myphone.conf
```

---

## 本地客户端配置

### 1. 获取配置文件

从服务器获取客户端配置文件（参考上面的方法）。

### 2. 安装客户端软件

#### Windows

1. 访问 [WireGuard官网](https://www.wireguard.com/install/)
2. 下载Windows版本
3. 安装并运行

#### macOS

**方法一：App Store**
1. 打开App Store
2. 搜索 "WireGuard"
3. 安装官方客户端

**方法二：Homebrew**
```bash
brew install wireguard-tools
```

#### Linux

```bash
# Ubuntu/Debian
sudo apt-get install wireguard wireguard-tools

# CentOS/RHEL
sudo yum install wireguard-tools
```

#### iOS

1. 打开App Store
2. 搜索 "WireGuard"
3. 安装官方客户端（免费）

#### Android

1. 打开Google Play Store
2. 搜索 "WireGuard"
3. 安装官方客户端（免费）

### 3. 导入配置

#### Windows/macOS GUI客户端

1. 打开WireGuard应用
2. 点击 "Add Tunnel" 或 "+"
3. 选择 "Import from file" 或 "Create from QR code"
4. 如果使用二维码：在服务器上运行 `sudo ./manage.sh show myphone`，然后扫描二维码
5. 如果使用文件：选择下载的 `.conf` 文件

#### Linux命令行

```bash
# 复制配置文件到WireGuard目录
sudo cp ~/Downloads/myphone.conf /etc/wireguard/wg0.conf

# 设置权限
sudo chmod 600 /etc/wireguard/wg0.conf

# 启动VPN
sudo wg-quick up wg0

# 查看状态
sudo wg show
```

#### iOS/Android

**使用二维码（推荐）**：
1. 在服务器上运行：`sudo ./manage.sh show myphone`
2. 在手机上打开WireGuard应用
3. 点击 "+" 按钮
4. 选择 "Create from QR code"
5. 扫描服务器显示的二维码

**使用配置文件**：
1. 将配置文件通过AirDrop/邮件/云存储传输到手机
2. 在手机上打开文件
3. 选择 "用WireGuard打开"

### 4. 连接VPN

#### GUI客户端（Windows/macOS/iOS/Android）

1. 在WireGuard应用中选择已添加的配置
2. 点击开关按钮或 "Activate" 连接
3. 首次连接可能需要授权（输入密码/Face ID）

#### Linux命令行

```bash
# 启动VPN
sudo wg-quick up wg0

# 停止VPN
sudo wg-quick down wg0

# 查看状态
sudo wg show

# 启用开机自启
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

---

## 验证和测试

### 1. 检查连接状态

#### 服务器端

```bash
# 查看WireGuard状态
sudo wg show

# 查看服务状态
sudo systemctl status wg-quick@wg0

# 查看实时日志
sudo journalctl -u wg-quick@wg0 -f
```

#### 客户端

**GUI客户端**：查看应用中的连接状态

**Linux命令行**：
```bash
sudo wg show
ip addr show wg0
```

### 2. 测试网络连通性

#### 测试VPN内网

```bash
# 应该能ping通服务器VPN IP
ping 10.0.0.1
```

#### 测试外网访问

```bash
# 测试DNS解析
nslookup google.com

# 测试外网连通性
ping 8.8.8.8

# 测试HTTP访问
curl https://www.google.com
```

### 3. 检查IP地址

连接VPN后，您的公网IP应该变为服务器的IP地址。

**方法一：浏览器访问**
- 访问 [whatismyip.com](https://www.whatismyip.com/)
- 查看显示的IP地址

**方法二：命令行**
```bash
# 查看当前IP
curl ifconfig.me
# 或
curl ipinfo.io/ip
```

### 4. 测试网站访问

尝试访问之前无法访问的网站，确认VPN工作正常。

---

## 常见问题

### 上传文件时的问题

**问题：Permission denied**
```bash
# 确保有写入权限，或使用root用户
# 检查服务器目录权限
ssh root@<服务器IP> "ls -la /root"
```

**问题：连接超时**
- 检查服务器IP是否正确
- 检查防火墙是否允许SSH连接
- 检查SSH服务是否运行

### 安装时的问题

**问题：无法下载软件包**
```bash
# 检查网络连接
ping 8.8.8.8

# 更新软件源
# Ubuntu/Debian
sudo apt-get update

# CentOS/RHEL
sudo yum update
```

**问题：权限不足**
```bash
# 确保使用root或sudo
sudo ./install.sh
```

### 连接时的问题

**问题：无法连接VPN**
- 检查服务器防火墙是否开放51820/UDP端口
- 检查服务器WireGuard服务是否运行
- 查看 [故障排查指南](troubleshooting.md)

**问题：连接后无法访问外网**
- 检查服务器IP转发是否启用
- 检查iptables NAT规则
- 查看 [故障排查指南](troubleshooting.md)

---

## 快速参考

### 服务器端常用命令

```bash
# 进入项目目录
cd /root/vpn/server

# 添加客户端
sudo ./manage.sh add <客户端名>

# 列出客户端
sudo ./manage.sh list

# 查看客户端配置
sudo ./manage.sh show <客户端名>

# 删除客户端
sudo ./manage.sh remove <客户端名>

# 查看WireGuard状态
sudo wg show

# 重启服务
sudo systemctl restart wg-quick@wg0
```

### 客户端常用命令（Linux）

```bash
# 启动VPN
sudo wg-quick up wg0

# 停止VPN
sudo wg-quick down wg0

# 查看状态
sudo wg show

# 查看IP
ip addr show wg0
```

---

## 下一步

- 阅读 [客户端配置指南](client-setup.md) 了解各平台详细配置
- 阅读 [故障排查指南](troubleshooting.md) 解决常见问题
- 根据需要添加更多客户端设备

---

## 安全建议

1. **保护配置文件**：不要将配置文件分享给他人
2. **定期更新**：保持服务器系统和软件更新
3. **使用强密码**：确保服务器root密码足够强
4. **密钥管理**：定期备份服务器密钥和配置
5. **监控日志**：定期检查服务器日志，发现异常连接

