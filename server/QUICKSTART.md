# WireGuard VPN 一键安装

## 安装命令

```bash
curl -sL https://raw.githubusercontent.com/evaworks/WireGuard/main/install.sh | sudo bash
```

## 客户端管理

```bash
# 添加客户端
sudo wg add myphone

# 列出所有客户端
sudo wg list

# 查看客户端配置和二维码
sudo wg show myphone

# 删除客户端
sudo wg remove myphone

# 查看帮助
sudo wg help
```

## 查看服务器信息

```bash
cat /etc/wireguard/server_info.txt
```

## 卸载

```bash
sudo systemctl stop wg-quick@wg0
sudo systemctl disable wg-quick@wg0
sudo rm -rf /etc/wireguard
sudo rm -f /usr/local/bin/wg
```

## 可选参数

```bash
# 指定端口
curl -sL ... | sudo bash -s -- --port 51820

# 指定服务器域名
curl -sL ... | sudo bash -s -- --domain your-server.com
```
