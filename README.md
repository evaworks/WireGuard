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

## 系统要求

- Ubuntu 18.04+ / Debian 10+ / CentOS 7+ / RHEL 8+
- Root 权限

## 详细文档

- [快速开始](server/QUICKSTART.md)
- [使用指南](server/README.md)
