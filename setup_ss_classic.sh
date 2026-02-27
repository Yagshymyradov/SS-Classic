#!/bin/bash

# Цвета для красоты
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Настройка Shadowsocks (Classic) ===${NC}"

# 1. Запрос параметров (с дефолтными значениями)
read -p "Введите порт [по умолчанию 122]: " SS_PORT
SS_PORT=${SS_PORT:-122}

read -p "Введите пароль [по умолчанию L6AjTB3sV47rUHvb9JYaTg]: " SS_PASS
SS_PASS=${SS_PASS:-L6AjTB3sV47rUHvb9JYaTg}

read -p "Введите метод шифрования [по умолчанию aes-128-gcm]: " SS_METHOD
SS_METHOD=${SS_METHOD:-aes-128-gcm}

# 2. Очистка 3x-ui (если есть)
echo "Очистка старых панелей..."
systemctl stop x-ui 2>/dev/null
systemctl disable x-ui 2>/dev/null
rm -rf /usr/local/x-ui /etc/x-ui /usr/bin/x-ui 2>/dev/null

# 3. Установка Shadowsocks
echo "Установка shadowsocks-libev..."
apt-get update
apt-get install -y shadowsocks-libev

# 4. Создание конфига
echo "Применение настроек..."
cat <<EOF > /etc/shadowsocks-libev/config.json
{
    "server": "0.0.0.0",
    "server_port": $SS_PORT,
    "password": "$SS_PASS",
    "timeout": 300,
    "method": "$SS_METHOD",
    "mode": "tcp_and_udp",
    "fast_open": true
}
EOF

# 5. Ускорение BBR
echo "Включение BBR..."
if ! sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
fi

# 6. Открытие портов
echo "Настройка Firewall (порт $SS_PORT)..."
iptables -I INPUT -p tcp --dport $SS_PORT -j ACCEPT
iptables -I INPUT -p udp --dport $SS_PORT -j ACCEPT

# 7. Запуск
systemctl restart shadowsocks-libev
systemctl enable shadowsocks-libev

# 8. Генерация ссылки
echo -e "${GREEN}--------------------------------------------------${NC}"
echo "Готово! Твои данные:"
echo "IP: \$(curl -s https://api.ipify.org)"
echo "Порт: $SS_PORT"
echo "Пароль: $SS_PASS"
echo "Метод: $SS_METHOD"
echo ""
# Генерируем ссылку автоматически через Python (т.к. нужно base64)
LINK_BASE64=\$(echo -n "$SS_METHOD:$SS_PASS" | base64)
echo "Твоя ссылка:"
echo -e "${GREEN}ss://\$LINK_BASE64@\$(curl -s https://api.ipify.org):$SS_PORT#SS-Custom${NC}"
echo -e "${GREEN}--------------------------------------------------${NC}"
