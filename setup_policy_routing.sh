#!/bin/bash

# 设置变量（可修改）
IF50="enx00e04c681b82"
IP50="192.168.123.50"
GW50="192.168.123.158"
TABLE50="rt50"
PRIORITY50=100

IF99="enp57s0"
IP99="192.168.123.99"
GW99="192.168.123.18"
TABLE99="rt99"
PRIORITY99=101

# 添加自定义路由表（如果还没添加过）
grep -q "$PRIORITY50 $TABLE50" /etc/iproute2/rt_tables || echo "$PRIORITY50 $TABLE50" | sudo tee -a /etc/iproute2/rt_tables
grep -q "$PRIORITY99 $TABLE99" /etc/iproute2/rt_tables || echo "$PRIORITY99 $TABLE99" | sudo tee -a /etc/iproute2/rt_tables

# 清理旧规则（避免重复）
sudo ip rule del from $IP50 table $TABLE50 2>/dev/null
sudo ip rule del from $IP99 table $TABLE99 2>/dev/null
sudo ip route flush table $TABLE50
sudo ip route flush table $TABLE99

# 设置 rt50 路由表
sudo ip route add 192.168.123.0/24 dev $IF50 src $IP50 table $TABLE50
sudo ip route add default via $GW50 dev $IF50 table $TABLE50
sudo ip rule add from $IP50 table $TABLE50

# 设置 rt99 路由表
sudo ip route add 192.168.123.0/24 dev $IF99 src $IP99 table $TABLE99
sudo ip route add default via $GW99 dev $IF99 table $TABLE99
sudo ip rule add from $IP99 table $TABLE99

echo "[✓] 策略路由配置完成。"
