# Mac本地使用指南

本文档专门针对Mac用户，说明如何在本地Mac上使用VPN服务。

## 重要说明

⚠️ **这些脚本不需要在本地Mac上运行！**

- ✅ **服务器端脚本**（`server/install.sh`, `server/manage.sh`）需要在**香港服务器**上运行
- ✅ **本地Mac**只需要安装WireGuard客户端软件，然后导入配置文件

## Mac本地操作步骤

### 第一步：上传文件到服务器（可选，如果需要部署）

如果您需要将项目文件上传到服务器：

```bash
# 在Mac终端中执行
cd /Users/eva/Documents/Project/vpn

# 使用SCP上传到服务器（替换为您的服务器IP）
scp -r /Users/eva/Documents/Project/vpn root@<服务器IP>:/root/
```

然后在服务器上运行安装脚本（不是本地）。

### 第二步：在Mac上安装WireGuard客户端

#### 方法一：App Store（推荐，最简单）

1. 打开 **App Store**
2. 搜索 "**WireGuard**"
3. 安装官方客户端（免费）
4. 打开WireGuard应用

#### 方法二：Homebrew

```bash
# 安装Homebrew（如果还没有）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装WireGuard
brew install wireguard-tools
```

### 第三步：获取配置文件

在服务器上添加客户端后，获取配置文件：

#### 方法一：扫描二维码（最简单）

1. **在服务器上**运行：
   ```bash
   ssh root@<服务器IP>
   cd /root/vpn/server
   sudo ./manage.sh show myphone  # 替换为您的客户端名
   ```

2. 服务器会显示二维码

3. **在Mac上**：
   - 打开WireGuard应用
   - 点击左下角 **"+"** 按钮
   - 选择 **"Create from QR code"**
   - 用Mac的摄像头扫描服务器终端显示的二维码

#### 方法二：下载配置文件

1. **从服务器下载配置文件**：
   ```bash
   # 在Mac终端执行
   scp root@<服务器IP>:/etc/wireguard/clients/myphone.conf ~/Downloads/myphone.conf
   ```

2. **在Mac上导入**：
   - 打开WireGuard应用
   - 点击左下角 **"+"** 按钮
   - 选择 **"Import from file..."**
   - 选择下载的 `myphone.conf` 文件

#### 方法三：手动复制配置

1. **在服务器上查看配置**：
   ```bash
   ssh root@<服务器IP>
   cat /etc/wireguard/clients/myphone.conf
   ```

2. **复制配置内容**，在Mac上：
   - 打开WireGuard应用
   - 点击 **"+"** 按钮
   - 选择 **"Add empty tunnel..."**
   - 粘贴配置内容
   - 点击 **"Save"**

### 第四步：连接VPN

1. 在WireGuard应用中选择已添加的配置
2. 点击配置旁边的**开关按钮**
3. 首次连接可能需要输入Mac密码以允许VPN配置
4. 连接成功后，状态会显示为 **"Active"**

### 第五步：验证连接

1. **检查IP地址**：
   - 打开浏览器访问 [whatismyip.com](https://www.whatismyip.com/)
   - 查看显示的IP应该是您香港服务器的IP

2. **测试网络**：
   ```bash
   # 在Mac终端测试
   ping 8.8.8.8
   ```

## Mac常用操作

### 查看连接状态

- 在WireGuard应用中查看
- 或使用终端：
  ```bash
  # 如果使用Homebrew安装的命令行版本
  sudo wg show
  ```

### 断开VPN

在WireGuard应用中点击开关按钮关闭即可。

### 删除配置

1. 在WireGuard应用中选择配置
2. 点击配置，选择删除

## 故障排查

### 无法连接

1. **检查服务器状态**：
   ```bash
   ssh root@<服务器IP>
   sudo systemctl status wg-quick@wg0
   ```

2. **检查防火墙**：
   - 确保服务器防火墙开放了51820/UDP端口
   - 检查Mac的防火墙设置

3. **检查配置文件**：
   - 确保配置文件完整
   - 检查服务器地址是否正确

### 连接后无法上网

1. 检查服务器IP转发是否启用
2. 检查服务器iptables NAT规则
3. 查看 [故障排查指南](troubleshooting.md)

## 常见问题

### Q: 这些脚本能在Mac上运行吗？

**A**: 不能。这些脚本是专门为Linux服务器设计的（Ubuntu/CentOS等）。Mac本地只需要安装WireGuard客户端应用。

### Q: 我需要在Mac上安装什么？

**A**: 只需要安装WireGuard客户端应用（App Store版本最简单）。

### Q: 配置文件在哪里？

**A**: 配置文件在服务器上，您需要从服务器下载或扫描二维码导入。

### Q: 可以在Mac上管理服务器吗？

**A**: 可以！通过SSH连接到服务器后，在服务器上运行管理命令：
```bash
ssh root@<服务器IP>
cd /root/vpn/server
sudo ./manage.sh list        # 列出客户端
sudo ./manage.sh add newpc   # 添加新客户端
```

## 快速参考

### 本地Mac操作
```bash
# 上传项目到服务器（首次部署）
scp -r ~/Documents/Project/vpn root@<服务器IP>:/root/

# 从服务器下载客户端配置
scp root@<服务器IP>:/etc/wireguard/clients/myphone.conf ~/Downloads/

# SSH登录服务器进行管理
ssh root@<服务器IP>
```

### 服务器端操作（通过SSH）
```bash
# 安装VPN服务器
cd /root/vpn/server
sudo ./install.sh

# 添加客户端
sudo ./manage.sh add myphone

# 查看客户端配置和二维码
sudo ./manage.sh show myphone

# 列出所有客户端
sudo ./manage.sh list
```

## 总结

- ❌ **不在Mac本地运行** `install.sh` 和 `manage.sh`
- ✅ **在服务器上运行**安装和管理脚本
- ✅ **在Mac上安装**WireGuard客户端应用
- ✅ **在Mac上导入**配置文件并连接VPN

更多详细信息请参考：
- [部署和使用指南](deployment-guide.md)
- [客户端配置指南](client-setup.md)
- [故障排查指南](troubleshooting.md)

