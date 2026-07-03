# WireGuard VPN 一键安装

一行命令，快速搭建 VPN 服务器。

## 快速开始

```bash
curl -sL https://raw.githubusercontent.com/evaworks/WireGuard/main/install.sh | sudo bash
```

## 客户端管理

```bash
sudo wgm add myphone      # 添加客户端
sudo wgm list             # 列出客户端
sudo wgm show myphone     # 查看配置/二维码
sudo wgm remove myphone   # 删除客户端
```

## 指定域名

```bash
# 使用域名安装（避免手动输入IP）
curl -sL https://raw.githubusercontent.com/evaworks/WireGuard/main/install.sh | sudo bash -s -- --domain your-domain.com
```

## 强制重装

```bash
# 清理旧配置并重新安装
curl -sL https://raw.githubusercontent.com/evaworks/WireGuard/main/install.sh | sudo bash -s -- --force
```

## 卸载

```bash
curl -sL https://raw.githubusercontent.com/evaworks/WireGuard/main/server/uninstall.sh | sudo bash
```

## 可选参数

```bash
--port <端口>     指定端口 (默认: 51820)
--domain <域名>   指定服务器域名/IP
-f, --force       强制重装（清理旧配置后重新安装）
```

## 系统要求

- Ubuntu 18.04+ / Debian 10+ / CentOS 7+ / RHEL 8+
- Root 权限

## 详细文档

- [快速开始](server/QUICKSTART.md)
- [使用指南](server/README.md)
