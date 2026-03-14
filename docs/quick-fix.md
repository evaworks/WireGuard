# 快速修复指南

## 问题1: 防火墙配置错误

**错误信息**: `ERROR: Could not find a profile matching 'forward'`

**解决方法**:

```bash
# 忽略这个错误，UFW的forward策略通常已经默认允许
# 或者手动设置：
ufw default allow forward
```

这个错误不影响功能，因为iptables规则已经在WireGuard配置文件中通过PostUp/PostDown设置了。

## 问题2: WireGuard接口未启动

**错误信息**: `Unable to retrieve current interface configuration: No such device`

**解决方法**:

### 方法一：检查并启动服务

```bash
# 检查服务状态
systemctl status wg-quick@wg0

# 如果服务未运行，启动它
systemctl start wg-quick@wg0

# 检查接口是否存在
ip link show wg0

# 如果接口不存在，检查配置文件
cat /etc/wireguard/wg0.conf
```

### 方法二：手动启动接口

```bash
# 直接启动接口
wg-quick up wg0

# 检查状态
wg show
```

### 方法三：检查配置文件问题

```bash
# 检查配置文件语法
wg-quick strip wg0

# 如果配置文件有问题，检查网络接口名
ip route | grep default

# 如果接口名不是eth0，需要修改配置文件中的eth0为实际接口名
# 例如：如果是ens3，编辑配置文件
nano /etc/wireguard/wg0.conf
# 将所有的 eth0 替换为实际的接口名（如 ens3）
```

### 方法四：重新安装（如果以上都不行）

```bash
# 停止服务
systemctl stop wg-quick@wg0
systemctl disable wg-quick@wg0

# 删除配置
rm /etc/wireguard/wg0.conf

# 重新运行安装脚本（会重新生成配置）
cd /root/vpn/server
sudo ./install.sh
```

## 添加客户端时的完整流程

修复接口问题后，添加客户端：

```bash
# 1. 确保WireGuard服务正在运行
systemctl status wg-quick@wg0

# 2. 如果未运行，启动它
systemctl start wg-quick@wg0

# 3. 检查接口
wg show

# 4. 添加客户端
./manage.sh add client

# 5. 如果还有问题，查看日志
journalctl -u wg-quick@wg0 -f
```

## 常见网络接口名

不同系统的网络接口名可能不同：

- **传统**: `eth0`, `eth1`
- **CentOS 7+**: `ens3`, `ens5`, `ens33`
- **Ubuntu 18+**: `ens3`, `ens5`, `enp0s3`
- **云服务器**: 可能是 `eth0` 或其他

**查找实际接口名**:
```bash
# 方法1：查看默认路由
ip route | grep default

# 方法2：查看所有接口
ip addr show

# 方法3：查看网络接口
ls /sys/class/net/
```

**修改配置文件中的接口名**:
```bash
# 编辑配置文件
nano /etc/wireguard/wg0.conf

# 找到这两行，将 eth0 替换为实际接口名：
# PostUp = ... -o eth0 -j MASQUERADE
# PostDown = ... -o eth0 -j MASQUERADE

# 保存后重启服务
systemctl restart wg-quick@wg0
```

## 验证修复

修复后验证：

```bash
# 1. 检查服务状态
systemctl status wg-quick@wg0

# 2. 检查接口
ip link show wg0
wg show

# 3. 测试添加客户端
./manage.sh add test-client

# 4. 查看客户端配置
./manage.sh show test-client
```

## 如果问题仍然存在

1. **查看详细日志**:
   ```bash
   journalctl -u wg-quick@wg0 -n 50
   ```

2. **检查内核模块**:
   ```bash
   lsmod | grep wireguard
   modprobe wireguard
   ```

3. **检查防火墙**:
   ```bash
   # 检查端口是否开放
   netstat -ulnp | grep 51820
   # 或
   ss -ulnp | grep 51820
   ```

4. **重新上传修复后的脚本**:
   ```bash
   # 在本地Mac上
   ./upload-simple.sh
   
   # 然后在服务器上重新运行安装（可选）
   cd /root/vpn/server
   sudo ./install.sh
   ```

