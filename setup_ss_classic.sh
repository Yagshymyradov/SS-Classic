#!/bin/bash

# Configuration
PORT=122
METHOD="aes-128-gcm"
PASSWORD="L6AjTB3sV47rUHvb9JYaTg"
REMARK="SS-Classic"

echo "--------------------------------------------------"
echo "Настройка Shadowsocks Classic..."
echo "--------------------------------------------------"

# 1. Обновление и установка shadowsocks-libev
echo "[1/5] Установка shadowsocks-libev..."
apt-get update -y
apt-get install -y shadowsocks-libev

# 2. Создание конфигурации
echo "[2/5] Настройка конфигурации..."
cat <<EOF > /etc/shadowsocks-libev/config.json
{
    "server": "0.0.0.0",
    "server_port": $PORT,
    "password": "$PASSWORD",
    "timeout": 300,
    "method": "$METHOD",
    "mode": "tcp_and_udp",
    "fast_open": true
}
EOF

# 3. Включение BBR (ускорение сети)
echo "[3/5] Включение BBR..."
if ! sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
fi

# 4. Настройка Firewall (открытие порта)
echo "[4/5] Открытие порта $PORT..."
if command -v ufw >/dev/null; then
    ufw allow $PORT/tcp || true
    ufw allow $PORT/udp || true
else
    iptables -I INPUT -p tcp --dport $PORT -j ACCEPT || true
    iptables -I INPUT -p udp --dport $PORT -j ACCEPT || true
fi

# 5. Перезапуск сервиса
echo "[5/5] Перезапуск сервиса..."
systemctl restart shadowsocks-libev
systemctl enable shadowsocks-libev

# Генерация ссылки
echo "--------------------------------------------------"
echo "Поиск внешнего IP..."
SERVER_IP=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me || echo "YOUR_IP")

# Base64 кодирование метода и пароля
LINK_BASE64=$(echo -n "$METHOD:$PASSWORD" | base64 | tr -d '\n' | tr -d '=')
SS_LINK="ss://${LINK_BASE64}@${SERVER_IP}:${PORT}#${REMARK}"

echo "--------------------------------------------------"
echo "✅ Shadowsocks успешно настроен!"
echo "--------------------------------------------------"
echo "IP:       $SERVER_IP"
echo "Порт:     $PORT"
echo "Пароль:   $PASSWORD"
echo "Метод:    $METHOD"
echo "--------------------------------------------------"
echo "Твоя ссылка (скопируй в приложение):"
echo "$SS_LINK"
echo "--------------------------------------------------"




