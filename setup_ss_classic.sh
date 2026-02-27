#!/bin/bash

# 1. Удаление 3x-ui (если установлен)
echo "Cleaning up 3x-ui..."
systemctl stop x-ui 2>/dev/null
systemctl disable x-ui 2>/dev/null
rm -rf /usr/local/x-ui /etc/x-ui /usr/bin/x-ui 2>/dev/null

# 2. Обновление и установка Shadowsocks
echo "Installing shadowsocks-libev..."
apt-get update
apt-get install -y shadowsocks-libev

# 3. Создание конфигурации
echo "Configuring Shadowsocks..."
cat <<EOF > /etc/shadowsocks-libev/config.json
{
    "server": "0.0.0.0",
    "server_port": 122,
    "password": "L6AjTB3sV47rUHvb9JYaTg",
    "timeout": 300,
    "method": "aes-128-gcm",
    "mode": "tcp_and_udp",
    "fast_open": true
}
EOF

# 4. Включение BBR (ускорение сети)
echo "Enabling BBR..."
if ! sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
fi

# 5. Настройка Firewall (открытие порта)
echo "Opening port 122..."
iptables -I INPUT -p tcp --dport 122 -j ACCEPT
iptables -I INPUT -p udp --dport 122 -j ACCEPT

# 6. Перезапуск сервиса
echo "Starting service..."
systemctl restart shadowsocks-libev
systemctl enable shadowsocks-libev

echo "--------------------------------------------------"
echo "Done! Your SS link is:"
echo "ss://YWVzLTEyOC1nY206TDZBalRCM3NWNDNyVUh2YjlKWWFUZw==@\$(curl -s https://api.ipify.org):122#SS-Classic"
echo "--------------------------------------------------"
