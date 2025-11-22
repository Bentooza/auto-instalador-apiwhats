#!/bin/bash

APP_DIR="/opt/RR-WhatsApp-API"
SERVICE="/etc/systemd/system/rrwa.service"
CONFIG="$APP_DIR/config.json"

echo "=========================================="
echo " Instalando RR-WhatsApp-API (By Bento AUTO)"
echo "=========================================="

# Update do sistema
apt update -y && apt upgrade -y

# Dependências básicas
apt install -y git curl wget unzip nano

# Node 18 (compatível com Debian 12)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs build-essential

# Dependências do Chromium (necessárias para puppeteer)
apt install -y chromium libatk-bridge2.0-0 libcups2 libxcomposite1 libxdamage1 \
libxrandr2 libgbm1 libasound2 libpangocairo-1.0-0 libxkbcommon0 libpango1.0-0 \
libnss3 libatk1.0-0 libgtk-3-0

# Baixar código
rm -rf "$APP_DIR"
git clone https://github.com/remontti/RR-WhatsApp-API.git "$APP_DIR"

cd "$APP_DIR"
npm install --force

# Criar config
cat <<EOF > "$CONFIG"
{
  "port": 8080,
  "allowedIPs": ["*"]
}
EOF

# Criar service
cat <<EOF > "$SERVICE"
[Unit]
Description=RR WhatsApp API Service (By Bento AUTO)
After=network.target

[Service]
ExecStart=/usr/bin/node $APP_DIR/index.js
WorkingDirectory=$APP_DIR
Restart=always
User=root
Environment=NODE_ENV=production
Environment=CHROME_BIN=/usr/bin/chromium

[Install]
WantedBy=multi-user.target
EOF

# Ativar serviço
systemctl daemon-reload
systemctl enable rrwa.service
systemctl start rrwa.service

echo "=========================================="
echo " RR-WhatsApp-API instalada com sucesso!"
echo " By Bento - AUTO INSTALL"
echo " Acesse: http://SEU-IP:8080"
echo "=========================================="
