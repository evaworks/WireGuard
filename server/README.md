# WireGuard VPN 一键安装

## 安装命令

```bash
# 方式1: curl (推荐)
curl -sL https://raw.githubusercontent.com/evaworks/WireGuard/main/install.sh | sudo bash

# 方式2: wget
wget -qO- https://raw.githubusercontent.com/evaworks/WireGuard/main/install.sh | sudo bash
```

## 参数选项

```bash
# 自定义端口
curl -sL https://raw.githubusercontent.com/evaworks/WireGuard/main/install.sh | sudo bash -s -- --port 51820

# 指定服务器IP/域名
curl -sL https://raw.githubusercontent.com/evaworks/WireGuard/main/install.sh | sudo bash -s -- --domain your-server.com

# 组合使用
curl -sL https://raw.githubusercontent.com/evaworks/WireGuard/main/install.sh | sudo bash -s -- --port 51820 --domain myserver.com
```

## 安装后

### 添加客户端

```bash
vpn-manage.sh add myphone
```

### 查看帮助

```bash
vpn-manage.sh help
```

### 查看服务器信息

```bash
cat /etc/wireguard/server_info.txt
```

## 客户端下载

服务器会显示客户端配置文件内容，可直接导入到 WireGuard 客户端，或扫描二维码。

## 卸载

```bash
systemctl stop wg-quick@wg0
systemctl disable wg-quick@wg0
rm -rf /etc/wireguard
rm -f /usr/local/bin/vpn-manage.sh
```
