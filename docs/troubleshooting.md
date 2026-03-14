# WireGuard VPN 故障排查指南

本文档提供常见问题的诊断和解决方案。

## 连接问题

### 问题：无法连接到VPN服务器

**症状**: 客户端显示连接失败或超时

**排查步骤**:

1. **检查服务器服务状态**
   ```bash
   sudo systemctl status wg-quick@wg0
   sudo wg show
   ```

2. **检查防火墙规则**
   ```bash
   # UFW
   sudo ufw status
   sudo ufw allow 51820/udp
   
   # firewalld
   sudo firewall-cmd --list-all
   sudo firewall-cmd --permanent --add-port=51820/udp
   sudo firewall-cmd --reload
   
   # iptables
   sudo iptables -L -n | grep 51820
   ```

3. **检查服务器端口监听**
   ```bash
   sudo netstat -ulnp | grep 51820
   # 或
   sudo ss -ulnp | grep 51820
   ```

4. **测试端口连通性**（从客户端）
   ```bash
   # Linux/Mac
   nc -u -v <服务器IP> 51820
   
   # 或使用telnet
   telnet <服务器IP> 51820
   ```

5. **检查服务器公网IP配置**
   ```bash
   cat /etc/wireguard/server_info.txt
   # 确认Endpoint地址是否正确
   ```

**解决方案**:
- 确保防火墙开放UDP 51820端口
- 检查服务器提供商的安全组/防火墙设置
- 确认服务器公网IP或域名配置正确
- 重启WireGuard服务：`sudo systemctl restart wg-quick@wg0`

### 问题：连接成功但无法访问外网

**症状**: VPN显示已连接，但无法访问网站或ping不通外网

**排查步骤**:

1. **检查IP转发**
   ```bash
   sysctl net.ipv4.ip_forward
   # 应该显示: net.ipv4.ip_forward = 1
   ```

2. **检查iptables NAT规则**
   ```bash
   sudo iptables -t nat -L -n -v
   # 应该看到MASQUERADE规则
   ```

3. **检查路由表**
   ```bash
   ip route show
   # 应该看到wg0相关的路由
   ```

4. **测试VPN内网连通性**
   ```bash
   # 在客户端
   ping 10.0.0.1  # 应该能ping通服务器VPN IP
   ```

5. **检查DNS解析**
   ```bash
   # 在客户端
   nslookup google.com
   # 或
   dig google.com
   ```

**解决方案**:

1. **启用IP转发**
   ```bash
   echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
   sysctl -p
   ```

2. **修复iptables NAT规则**
   ```bash
   # 找到主网络接口（通常是eth0或ens3）
   ip route | grep default
   
   # 手动添加NAT规则（替换eth0为实际接口名）
   sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
   sudo iptables -A FORWARD -i wg0 -j ACCEPT
   sudo iptables -A FORWARD -o wg0 -j ACCEPT
   ```

3. **更新WireGuard配置中的接口名**
   编辑 `/etc/wireguard/wg0.conf`，将 `eth0` 替换为实际的主网络接口名。

### 问题：客户端显示连接但实际未连接

**症状**: 客户端显示已连接，但IP地址未改变

**排查步骤**:

1. **检查客户端配置**
   - 确认 `AllowedIPs` 包含 `0.0.0.0/0`（代理所有流量）
   - 检查 `Endpoint` 地址是否正确

2. **检查路由**
   ```bash
   # Windows
   route print
   
   # Linux/Mac
   ip route show
   # 或
   netstat -rn
   ```

3. **验证DNS**
   ```bash
   # 检查DNS服务器
   nslookup
   ```

**解决方案**:
- 修改客户端配置，确保 `AllowedIPs = 0.0.0.0/0, ::/0`
- 在客户端重新导入配置并重启连接

## 性能问题

### 问题：VPN速度慢

**排查步骤**:

1. **测试服务器带宽**
   ```bash
   # 在服务器上
   speedtest-cli
   ```

2. **检查服务器负载**
   ```bash
   top
   htop
   iostat
   ```

3. **测试延迟**
   ```bash
   # 从客户端
   ping <服务器IP>
   ping 10.0.0.1
   ```

4. **检查MTU设置**
   ```bash
   # 在客户端
   ping -s 1472 -M do 10.0.0.1
   # 如果失败，尝试减小MTU
   ```

**解决方案**:

1. **优化MTU**
   在客户端配置中添加：
   ```ini
   [Interface]
   ...
   MTU = 1420
   ```

2. **更换DNS服务器**
   ```ini
   [Interface]
   ...
   DNS = 1.1.1.1, 8.8.8.8
   ```

3. **检查服务器带宽限制**
   - 联系服务器提供商检查带宽限制
   - 检查是否有流量限制

### 问题：连接不稳定，经常断开

**排查步骤**:

1. **检查服务器日志**
   ```bash
   sudo journalctl -u wg-quick@wg0 -f
   ```

2. **检查网络稳定性**
   ```bash
   # 持续ping测试
   ping -c 100 <服务器IP>
   ```

3. **检查Keepalive设置**
   查看客户端配置中的 `PersistentKeepalive` 设置

**解决方案**:

1. **增加Keepalive间隔**
   客户端配置中应该已有：
   ```ini
   [Peer]
   ...
   PersistentKeepalive = 25
   ```

2. **检查NAT超时设置**
   某些路由器NAT超时时间较短，可能需要更频繁的keepalive

## 配置问题

### 问题：客户端配置导入失败

**排查步骤**:

1. **检查配置文件格式**
   ```bash
   # 检查配置文件语法
   wg-quick strip wg0
   ```

2. **检查密钥格式**
   - 私钥和公钥应该是base64编码的字符串
   - 私钥以 `=` 结尾
   - 公钥不以 `=` 结尾

3. **检查文件权限**
   ```bash
   ls -l client_name.conf
   # 应该显示 600 权限
   ```

**解决方案**:
- 使用 `manage.sh show <客户端名称>` 重新生成配置
- 确保配置文件完整，没有缺失部分
- 检查特殊字符和编码问题

### 问题：添加客户端后无法连接

**排查步骤**:

1. **检查服务器配置**
   ```bash
   sudo wg show
   # 应该显示新添加的客户端公钥
   ```

2. **检查服务器配置文件**
   ```bash
   sudo cat /etc/wireguard/wg0.conf
   # 确认客户端Peer配置已添加
   ```

3. **重新加载配置**
   ```bash
   sudo wg syncconf wg0 <(wg-quick strip wg0)
   ```

**解决方案**:
- 使用 `manage.sh` 脚本添加客户端，它会自动更新服务器配置
- 手动添加客户端后需要重新加载WireGuard配置
- 确保客户端IP地址不冲突

## 防火墙问题

### 问题：防火墙阻止连接

**排查步骤**:

1. **检查UFW状态**
   ```bash
   sudo ufw status verbose
   ```

2. **检查firewalld**
   ```bash
   sudo firewall-cmd --list-all
   ```

3. **检查iptables**
   ```bash
   sudo iptables -L -n -v
   sudo iptables -t nat -L -n -v
   ```

**解决方案**:

1. **UFW配置**
   ```bash
   sudo ufw allow 51820/udp
   sudo ufw allow forward
   sudo ufw reload
   ```

2. **firewalld配置**
   ```bash
   sudo firewall-cmd --permanent --add-port=51820/udp
   sudo firewall-cmd --permanent --add-masquerade
   sudo firewall-cmd --reload
   ```

3. **云服务器安全组**
   - 登录云服务器控制台
   - 在安全组中添加UDP 51820端口规则
   - 允许所有来源或特定IP段

## 日志和调试

### 查看服务器日志

```bash
# WireGuard服务日志
sudo journalctl -u wg-quick@wg0 -f

# 系统日志
sudo dmesg | grep wireguard

# 网络日志
sudo tcpdump -i wg0 -n
```

### 查看客户端日志

**Linux**
```bash
sudo journalctl -u wg-quick@wg0 -f
```

**Windows/macOS/iOS/Android**
在客户端应用中查看日志或连接详情

### 调试模式

```bash
# 启用详细日志
sudo wg set wg0 log-level verbose

# 查看实时连接信息
sudo wg show wg0 dump
```

## 常见错误信息

### "Protocol not supported"
- **原因**: 内核不支持WireGuard
- **解决**: 更新内核或安装wireguard-dkms

### "Permission denied"
- **原因**: 权限不足
- **解决**: 使用sudo运行命令

### "Address already in use"
- **原因**: 端口被占用
- **解决**: 更改WireGuard监听端口或停止占用端口的服务

### "Invalid key"
- **原因**: 密钥格式错误
- **解决**: 重新生成密钥对

## 获取帮助

如果以上方法都无法解决问题：

1. 检查 [WireGuard官方文档](https://www.wireguard.com/)
2. 查看 [WireGuard Wiki](https://wiki.archlinux.org/title/WireGuard)
3. 提交GitHub Issue（附上日志和配置信息，注意隐藏敏感信息）

## 安全提醒

- 不要将配置文件或密钥分享给他人
- 定期轮换密钥
- 使用强密码保护服务器
- 保持系统和软件更新
- 监控异常连接和流量

