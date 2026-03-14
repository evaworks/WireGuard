# Shadowsocks 轻量级代理方案

Shadowsocks是一个轻量级的代理工具，适合只需要简单代理功能的场景。

## 特性

- ✅ 轻量级，资源占用少
- ✅ 配置简单
- ✅ 支持TCP和UDP
- ✅ 多平台客户端支持
- ✅ 适合个人使用

## 与WireGuard对比

| 特性 | WireGuard | Shadowsocks |
|------|-----------|-------------|
| 协议类型 | VPN | 代理 |
| 性能 | 极高 | 高 |
| 配置复杂度 | 中等 | 简单 |
| 系统资源 | 低 | 极低 |
| 适用场景 | 全流量VPN | 应用层代理 |
| 加密强度 | 极高 | 高 |

**选择建议**:
- 需要全局VPN、多设备、企业级安全 → **WireGuard**
- 只需要简单代理、轻量级、个人使用 → **Shadowsocks**

## 安装

```bash
cd shadowsocks
chmod +x install.sh
sudo ./install.sh
```

安装过程中会提示输入：
- 端口（默认8388）
- 密码（留空自动生成）
- 加密方法（默认aes-256-gcm）

## 客户端配置

### 方法一：使用配置URL（推荐）

安装脚本会生成一个 `ss://` 格式的配置URL，可以直接导入到客户端。

### 方法二：手动配置

- **服务器地址**: 您的服务器公网IP
- **端口**: 安装时设置的端口（默认8388）
- **密码**: 安装时设置的密码
- **加密方法**: 安装时设置的加密方法（默认aes-256-gcm）

## 客户端下载

- **Windows**: [shadowsocks-windows](https://github.com/shadowsocks/shadowsocks-windows/releases)
- **macOS**: [ShadowsocksX-NG](https://github.com/shadowsocks/ShadowsocksX-NG/releases)
- **Android**: [shadowsocks-android](https://github.com/shadowsocks/shadowsocks-android/releases)
- **iOS**: Shadowrocket, Quantumult X (App Store)

## 常用命令

```bash
# 查看服务状态
sudo systemctl status shadowsocks-libev

# 重启服务
sudo systemctl restart shadowsocks-libev

# 查看日志
sudo journalctl -u shadowsocks-libev -f

# 查看配置
sudo cat /etc/shadowsocks-libev/config.json

# 查看客户端配置信息
cat /etc/shadowsocks-libev/client_info.txt
```

## 修改配置

编辑配置文件：

```bash
sudo nano /etc/shadowsocks-libev/config.json
```

修改后重启服务：

```bash
sudo systemctl restart shadowsocks-libev
```

## 卸载

```bash
sudo systemctl stop shadowsocks-libev
sudo systemctl disable shadowsocks-libev
sudo apt-get remove shadowsocks-libev  # Ubuntu/Debian
# 或
sudo yum remove shadowsocks-libev      # CentOS/RHEL
sudo rm -rf /etc/shadowsocks-libev
```

## 故障排查

### 无法连接

1. 检查防火墙是否开放端口
2. 检查服务是否运行：`systemctl status shadowsocks-libev`
3. 检查配置文件是否正确：`cat /etc/shadowsocks-libev/config.json`

### 速度慢

1. 尝试更换加密方法（chacha20-ietf-poly1305通常更快）
2. 检查服务器带宽
3. 检查服务器负载

### 连接不稳定

1. 检查网络稳定性
2. 尝试调整timeout设置
3. 检查服务器日志：`journalctl -u shadowsocks-libev -f`

## 安全建议

- 使用强密码
- 定期更换密码
- 使用安全的加密方法（aes-256-gcm, chacha20-ietf-poly1305）
- 限制访问IP（如需要，使用iptables）
- 保持系统和软件更新

## 更多信息

- [Shadowsocks官方文档](https://shadowsocks.org/)
- [Shadowsocks GitHub](https://github.com/shadowsocks)

