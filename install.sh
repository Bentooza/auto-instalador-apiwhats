#!/bin/bash
set -e

# Variável com URL do seu repositório Git
GIT_REPO="https://github.com/seu-usuario/RR-WhatsApp-API.git"

echo "Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

echo "Instalando dependências do sistema..."
sudo apt install -y curl wget git build-essential unzip xvfb libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libxkbcommon0 libxcomposite1 libxdamage1 libxrandr2 libgbm1 libasound2 libpangocairo-1.0-0 libpango-1.0-0 libgtk-3-0 chromium

echo "Instalando Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

echo "Clonando repositório..."
git clone $GIT_REPO /opt/RR-WhatsApp-API || (cd /opt/RR-WhatsApp-API && git pull)

cd /opt/RR-WhatsApp-API

echo "Criando pastas necessárias..."
mkdir -p session
mkdir -p public

echo "Instalando dependências npm..."
PUPPETEER_SKIP_DOWNLOAD=true npm install --force

echo "Configurando Puppeteer para usar Chromium do sistema..."
npm install puppeteer-core --ignore-scripts

echo "Criando .gitignore..."
cat > .gitignore <<EOL
node_modules/
session/
*.log
.DS_Store
Thumbs.db
.env
EOL

echo "Criando serviço systemd..."
cat | sudo tee /etc/systemd/system/rrwa.service > /dev/null <<EOL
[Unit]
Description=RR WhatsApp API Service (By Bento)
After=network.target

[Service]
ExecStart=/usr/bin/node /opt/RR-WhatsApp-API/index.js
WorkingDirectory=/opt/RR-WhatsApp-API
Restart=always
User=$(whoami)
Environment=NODE_ENV=production
Environment=PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
StandardOutput=inherit
StandardError=inherit

[Install]
WantedBy=multi-user.target
EOL

echo "Recarregando systemd e iniciando serviço..."
sudo systemctl daemon-reload
sudo systemctl enable rrwa.service
sudo systemctl start rrwa.service

echo "Instalação completa! A API deve iniciar automaticamente e ao reiniciar o servidor."
sudo systemctl status rrwa.service
