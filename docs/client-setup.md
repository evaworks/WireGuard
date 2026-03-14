# WireGuard 客户端配置指南

本指南将帮助您在各种平台上配置和使用WireGuard VPN客户端。

## 前提条件

- 已完成服务器端安装
- 已使用 `manage.sh add <客户端名称>` 添加客户端
- 已获取客户端配置文件或二维码

## Windows

### 1. 安装WireGuard客户端

1. 访问 [WireGuard官网](https://www.wireguard.com/install/)
2. 下载Windows版本安装程序
3. 运行安装程序并完成安装

### 2. 导入配置

**方法一：使用配置文件**
1. 打开WireGuard客户端
2. 点击 "Add Tunnel" -> "Add empty tunnel..."
3. 将服务器上生成的配置文件内容复制粘贴到编辑框
4. 点击 "Save" 保存

**方法二：使用配置文件文件**
1. 将服务器上的 `client_name.conf` 文件下载到本地
2. 在WireGuard客户端中点击 "Add Tunnel" -> "Import tunnel(s) from file..."
3. 选择下载的配置文件
4. 点击 "Save" 保存

### 3. 连接VPN

1. 在客户端界面选择已添加的配置
2. 点击 "Activate" 按钮
3. 连接成功后，状态会显示为 "Active"

### 4. 验证连接

- 打开浏览器访问 [whatismyip.com](https://www.whatismyip.com/) 查看IP是否已变更
- 使用 `ping 8.8.8.8` 测试网络连通性

## macOS

### 1. 安装WireGuard客户端

**方法一：使用Homebrew**
```bash
brew install wireguard-tools
```

**方法二：使用App Store**
1. 打开App Store
2. 搜索 "WireGuard"
3. 安装官方客户端

### 2. 导入配置

**使用命令行（Homebrew安装）**
```bash
# 将配置文件复制到WireGuard目录
sudo cp client_name.conf /usr/local/etc/wireguard/wg0.conf

# 启动VPN
sudo wg-quick up wg0

# 停止VPN
sudo wg-quick down wg0
```

**使用GUI客户端（App Store版本）**
1. 打开WireGuard应用
2. 点击左下角 "+" 按钮
3. 选择 "Import from file..." 或 "Create from QR code"
4. 导入配置文件或扫描二维码

### 3. 连接VPN

在GUI客户端中点击配置旁边的开关即可连接/断开。

## Linux

### 1. 安装WireGuard

**Ubuntu/Debian**
```bash
sudo apt-get update
sudo apt-get install wireguard wireguard-tools
```

**CentOS/RHEL**
```bash
sudo yum install epel-release
sudo yum install wireguard-tools
```

**Fedora**
```bash
sudo dnf install wireguard-tools
```

### 2. 配置客户端

```bash
# 将配置文件复制到WireGuard目录
sudo cp client_name.conf /etc/wireguard/wg0.conf

# 设置权限
sudo chmod 600 /etc/wireguard/wg0.conf
```

### 3. 启动VPN

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

### 4. 验证连接

```bash
# 查看IP地址
ip addr show wg0

# 测试连通性
ping -c 4 8.8.8.8

# 查看路由
ip route show
```

## iOS

### 1. 安装WireGuard客户端

1. 打开App Store
2. 搜索 "WireGuard"
3. 安装官方客户端（免费）

### 2. 导入配置

**方法一：扫描二维码（推荐）**
1. 在服务器上运行：`sudo ./manage.sh show <客户端名称>`
2. 在iPhone上打开WireGuard应用
3. 点击右上角 "+" 按钮
4. 选择 "Create from QR code"
5. 扫描服务器显示的二维码

**方法二：使用配置文件**
1. 将配置文件通过AirDrop、邮件或其他方式传输到iPhone
2. 在iPhone上打开文件
3. 选择 "用WireGuard打开"
4. 配置会自动导入

### 3. 连接VPN

1. 在WireGuard应用中选择已添加的配置
2. 点击右侧的开关按钮
3. 首次连接需要允许添加VPN配置（输入密码或Face ID）

### 4. 验证连接

- 打开Safari访问 [whatismyip.com](https://www.whatismyip.com/)
- 或使用其他网络工具查看IP地址

## Android

### 1. 安装WireGuard客户端

1. 打开Google Play Store
2. 搜索 "WireGuard"
3. 安装官方客户端（免费）

### 2. 导入配置

**方法一：扫描二维码（推荐）**
1. 在服务器上运行：`sudo ./manage.sh show <客户端名称>`
2. 在Android手机上打开WireGuard应用
3. 点击右下角 "+" 按钮
4. 选择 "Create from QR code"
5. 扫描服务器显示的二维码

**方法二：使用配置文件**
1. 将配置文件传输到Android手机（通过USB、邮件、云存储等）
2. 在手机上打开文件管理器
3. 点击配置文件，选择 "用WireGuard打开"
4. 配置会自动导入

### 3. 连接VPN

1. 在WireGuard应用中选择已添加的配置
2. 点击右侧的开关按钮
3. 首次连接需要允许添加VPN配置

### 4. 验证连接

- 打开浏览器访问 [whatismyip.com](https://www.whatismyip.com/)
- 或使用网络工具应用查看IP地址

## 高级配置

### 仅代理特定流量

默认配置会代理所有流量（`AllowedIPs = 0.0.0.0/0, ::/0`）。如果只想代理特定流量，可以修改客户端配置文件：

```ini
[Peer]
...
# 仅代理特定IP段
AllowedIPs = 10.0.0.0/8, 172.16.0.0/12

# 或仅代理特定网站
AllowedIPs = 1.2.3.4/32
```

### 自定义DNS服务器

在客户端配置的 `[Interface]` 部分修改DNS：

```ini
[Interface]
...
DNS = 8.8.8.8, 1.1.1.1, 208.67.222.222
```

### 自动连接

**Linux (systemd)**
```bash
sudo systemctl enable wg-quick@wg0
```

**Windows/macOS/iOS/Android**
在客户端设置中启用 "Connect on startup" 或类似选项。

## 常见问题

### 无法连接

1. 检查服务器防火墙是否开放UDP端口
2. 确认服务器WireGuard服务正在运行
3. 检查客户端配置是否正确
4. 查看服务器日志：`sudo journalctl -u wg-quick@wg0 -f`

### 连接后无法访问外网

1. 检查服务器IP转发是否启用：`sysctl net.ipv4.ip_forward`
2. 检查iptables NAT规则是否正确
3. 确认客户端 `AllowedIPs` 配置

### 速度慢

1. 检查服务器带宽和负载
2. 尝试更换DNS服务器
3. 检查网络延迟：`ping <服务器IP>`

更多故障排查信息请参考 [故障排查指南](troubleshooting.md)

