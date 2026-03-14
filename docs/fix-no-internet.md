# 修复VPN连接后无法访问外网的问题

## 问题症状

- ✅ VPN显示已连接
- ❌ 无法访问外网
- ❌ 无法访问内网

## 快速诊断步骤

在服务器上执行以下命令进行诊断：

```bash
# 1. 检查WireGuard服务状态
systemctl status wg-quick@wg0

# 2. 检查WireGuard接口
wg show
ip link show wg0

# 3. 检查IP转发是否启用
sysctl net.ipv4.ip_forward
# 应该显示: net.ipv4.ip_forward = 1

# 4. 检查iptables NAT规则
iptables -t nat -L -n -v | grep MASQUERADE

# 5. 检查网络接口名（重要！）
ip route | grep default
# 查看输出中的接口名，可能是 ens3, ens5, eth0 等
```

## 常见原因和解决方案

### 原因1：网络接口名错误（最常见）

**问题**：配置文件中的 `eth0` 可能不是实际的网络接口名

**解决方法**：

```bash
# 1. 查找实际的网络接口名
ip route | grep default
# 输出示例：default via 172.16.0.1 dev ens3
# 这里的 ens3 就是实际接口名

# 2. 编辑WireGuard配置文件
nano /etc/wireguard/wg0.conf

# 3. 找到这两行，将 eth0 替换为实际接口名（如 ens3）：
# PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
# PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ens3 -j MASQUERADE

# 4. 保存后重启服务
systemctl restart wg-quick@wg0

# 5. 验证
wg show
```

### 原因2：IP转发未启用

**解决方法**：

```bash
# 1. 启用IP转发
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

# 2. 立即生效
sysctl -p

# 3. 验证
sysctl net.ipv4.ip_forward
# 应该显示: net.ipv4.ip_forward = 1
```

### 原因3：iptables NAT规则缺失

**解决方法**：

```bash
# 1. 查找实际网络接口名
INTERFACE=$(ip route | grep default | awk '{print $5}')
echo "网络接口: $INTERFACE"

# 2. 手动添加iptables规则
iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -A FORWARD -o wg0 -j ACCEPT

# 3. 保存规则（根据系统不同）
# Ubuntu/Debian:
iptables-save > /etc/iptables/rules.v4

# CentOS/RHEL:
service iptables save
# 或
iptables-save > /etc/sysconfig/iptables

# 4. 重启WireGuard服务
systemctl restart wg-quick@wg0
```

### 原因4：防火墙阻止转发

**解决方法**：

```bash
# 如果使用UFW
ufw default allow forward
ufw reload

# 如果使用firewalld
firewall-cmd --permanent --add-masquerade
firewall-cmd --reload
```

## 一键修复脚本

在服务器上创建并运行以下脚本：

```bash
# 创建修复脚本
cat > /root/fix-vpn.sh << 'EOF'
#!/bin/bash

echo "=== VPN网络修复脚本 ==="

# 1. 启用IP转发
echo "1. 启用IP转发..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -p

# 2. 查找实际网络接口
INTERFACE=$(ip route | grep default | awk '{print $5}')
echo "2. 检测到网络接口: $INTERFACE"

# 3. 更新WireGuard配置
if [ -f /etc/wireguard/wg0.conf ]; then
    echo "3. 更新WireGuard配置..."
    sed -i "s/-o eth0/-o $INTERFACE/g" /etc/wireguard/wg0.conf
    sed -i "s/-o ens3/-o $INTERFACE/g" /etc/wireguard/wg0.conf
    sed -i "s/-o ens5/-o $INTERFACE/g" /etc/wireguard/wg0.conf
fi

# 4. 添加iptables规则
echo "4. 配置iptables规则..."
iptables -t nat -C POSTROUTING -o $INTERFACE -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE

iptables -C FORWARD -i wg0 -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -i wg0 -j ACCEPT

iptables -C FORWARD -o wg0 -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -o wg0 -j ACCEPT

# 5. 重启WireGuard
echo "5. 重启WireGuard服务..."
systemctl restart wg-quick@wg0

# 6. 显示状态
echo ""
echo "=== 修复完成 ==="
echo "网络接口: $INTERFACE"
echo ""
echo "WireGuard状态:"
wg show
echo ""
echo "IP转发状态:"
sysctl net.ipv4.ip_forward
echo ""
echo "NAT规则:"
iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE
EOF

chmod +x /root/fix-vpn.sh
sudo /root/fix-vpn.sh
```

## 验证修复

修复后，在Mac客户端上：

1. **断开并重新连接VPN**
   - 在WireGuard应用中点击"停用"
   - 等待几秒后再次点击连接

2. **测试外网访问**
   ```bash
   # 在Mac终端
   curl ifconfig.me
   # 应该显示服务器IP: 47.83.117.107
   
   ping 8.8.8.8
   # 应该能ping通
   ```

3. **测试内网访问**
   - 尝试访问本地网络资源
   - 如果内网无法访问，可能需要配置路由（见下方）

## 如果内网仍然无法访问

如果修复后外网可以访问，但内网无法访问，需要配置路由：

### 方法一：修改客户端配置（仅代理外网流量）

在Mac的WireGuard应用中：

1. 点击"编辑"按钮
2. 找到"路由的IP地址"部分
3. 修改为：
   ```
   0.0.0.0/1, 128.0.0.0/1, ::/1, 8000::/1
   ```
   这样内网流量不走VPN，外网流量走VPN

### 方法二：添加内网路由（保持所有流量走VPN）

如果需要同时访问内网和外网，需要在服务器上添加路由规则。

## 常见网络接口名

不同系统的网络接口名可能不同：

- **传统**: `eth0`, `eth1`
- **CentOS 7+**: `ens3`, `ens5`, `ens33`
- **Ubuntu 18+**: `ens3`, `ens5`, `enp0s3`
- **云服务器**: 可能是 `eth0` 或其他

**查找方法**:
```bash
ip route | grep default
# 或
ip addr show | grep -E "^[0-9]+:" | grep -v lo
```

## 如果问题仍然存在

1. **查看详细日志**:
   ```bash
   journalctl -u wg-quick@wg0 -n 50
   ```

2. **检查服务器网络**:
   ```bash
   # 测试服务器能否访问外网
   ping 8.8.8.8
   curl ifconfig.me
   ```

3. **检查客户端路由**:
   ```bash
   # 在Mac终端
   netstat -rn | grep wg0
   ```

