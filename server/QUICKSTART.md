# WireGuard VPN 一键安装

## 安装命令

```bash
curl -sL https://raw.githubusercontent.com/evaworks/WireGuard/main/install.sh | sudo bash
```

## 客户端管理

```bash
# 添加客户端
sudo wgm add myphone

# 列出所有客户端
sudo wgm list

# 查看客户端配置和二维码
sudo wgm show myphone

# 删除客户端
sudo wgm remove myphone

# 查看帮助
sudo wgm help
```

## 查看服务器信息

```bash
cat /etc/wireguard/server_info.txt
```

## 强制重装

```bash
# 清理旧配置并重新安装（无需手动卸载）
curl -sL https://raw.githubusercontent.com/evaworks/WireGuard/main/install.sh | sudo bash -s -- --force
```

## 卸载

```bash
curl -sL https://raw.githubusercontent.com/evaworks/WireGuard/main/server/uninstall.sh | sudo bash
```

或手动清除：

```bash
sudo systemctl stop wg-quick@wg0
sudo systemctl disable wg-quick@wg0
sudo rm -rf /etc/wireguard
sudo rm -f /usr/local/bin/wgm
```

## 可选参数

```bash
# 指定端口
curl -sL ... | sudo bash -s -- --port 51820

# 指定服务器域名
curl -sL ... | sudo bash -s -- --domain your-server.com

# 强制重装（清理旧配置后重新安装）
curl -sL ... | sudo bash -s -- --force
```
