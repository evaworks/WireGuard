#!/bin/bash

# VPN连接诊断脚本

echo "=========================================="
echo "  VPN连接诊断"
echo "=========================================="
echo ""

echo "1. WireGuard接口状态:"
wg show
echo ""

echo "2. IP转发状态:"
sysctl net.ipv4.ip_forward
echo ""

echo "3. NAT规则:"
iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE
echo ""

echo "4. FORWARD链规则:"
iptables -L FORWARD -n -v
echo ""

echo "5. INPUT链规则（WireGuard端口）:"
iptables -L INPUT -n -v | grep 51820
echo ""

echo "6. 网络接口信息:"
ip route | grep default
echo ""

echo "7. 测试服务器外网连接:"
ping -c 2 8.8.8.8
echo ""

echo "8. WireGuard服务状态:"
systemctl status wg-quick@wg0 --no-pager -l
echo ""

echo "9. 检查防火墙状态:"
if command -v ufw &> /dev/null; then
    ufw status verbose | head -20
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --list-all
fi
echo ""

echo "=========================================="
echo "诊断完成"
echo "=========================================="

