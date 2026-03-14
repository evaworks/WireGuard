# WireGuard VPN 一键安装

一行命令，快速搭建 VPN 服务器。

## 快速开始

```bash
curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/vpn/master/install.sh | sudo bash
```

### 自定义参数

```bash
# 指定端口和域名
curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/vpn/master/install.sh | sudo bash -s -- --port 51820 --domain your-server.com
```

## 使用方法

详见 [server/README.md](server/README.md)

## 系统要求

- Ubuntu 18.04+ / Debian 10+ / CentOS 7+ / RHEL 8+
- Root 权限

## 上传到 GitHub

1. 创建 GitHub 仓库
2. 上传以下文件：
   - `install.sh` (根目录)
   - `server/manage.sh`
   - `server/wg0.conf.template`
3. 将 `YOUR_USERNAME/vpn` 替换为你的仓库地址

## License

MIT
