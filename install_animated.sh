#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

APP_DIR="/opt/RR-WhatsApp-API"
SERVICE="/etc/systemd/system/rrwa.service"
CONFIG="$APP_DIR/config.json"

spin() {
    sp='/-\|'
    while true; do
        printf "\r${MAGENTA}[$sp]${RESET} $1"
        sp=${sp#?}${sp%${sp#?}}
        sleep 0.1
    done
}

logo() {
    clear
    echo -e "${CYAN}"
    echo "██████╗ ██████╗     ██╗    ██╗██╗  ██╗ █████╗ ████████╗██╗  ██╗"
    echo "██╔══██╗██╔══██╗    ██║    ██║██║  ██║██╔══██╗╚══██╔══╝██║  ██║"
    echo "██████╔╝██████╔╝    ██║ █╗ ██║███████║███████║   ██║   ███████║"
    echo "██╔══██╗██╔══██╗    ██║███╗██║██╔══██║██╔══██║   ██║   ██╔══██║"
    echo "██║  ██║██║  ██║    ╚███╔███╔╝██║  ██║██║  ██║   ██║   ██║  ██║"
    echo "╚═╝  ╚═╝╚═╝  ╚═╝     ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝"
    echo -e "                 ${YELLOW}RR-WhatsApp-API - By Bento${RESET}"
    echo ""
}

install_rrwa() {
    logo
    echo -e "${GREEN}[+] Iniciando instalação...${RESET}"

    spin "Atualizando sistema..." &
    SP=$!
    apt update -y &>/dev/null
    apt upgrade -y &>/dev/null
    kill $SP

    echo -e "\n${GREEN}[+] Instalando dependências básicas...${RESET}"
    apt install -y git curl wget unzip nano &>/dev/null

    echo -e "${GREEN}[+] Instalando Node 18...${RESET}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - &>/dev/null
    apt install -y nodejs build-essential &>/dev/null

    echo -e "${GREEN}[+] Baixando repositório...${RESET}"
    rm -rf "$APP_DIR"
    git clone https://github.com/remontti/RR-WhatsApp-API.git "$APP_DIR" &>/dev/null
    cd "$APP_DIR"

    echo -e "${GREEN}[+] Instalando dependências do projeto...${RESET}"
    npm install --force &>/dev/null

    echo -e "${GREEN}[+] Baixando Chromium correto (puppeteer)...${RESET}"
    npm install puppeteer &>/dev/null

    echo -e "${GREEN}[+] Corrigindo index.js automaticamente...${RESET}"

sed -i 's/new Client({/new Client({ \
    puppeteer: { \
        executablePath: require("puppeteer").executablePath(), \
        headless: true, \
        args: ["--no-sandbox","--disable-dev-shm-usage"] \
    },/' index.js

    echo -e "${GREEN}[+] Criando config padrão...${RESET}"
cat <<EOF > "$CONFIG"
{
  "port": 8080,
  "allowedIPs": ["*"]
}
EOF

    echo -e "${GREEN}[+] Criando serviço systemd...${RESET}"
cat <<EOF > "$SERVICE"
[Unit]
Description=RR WhatsApp API Service (By Bento)
After=network.target

[Service]
ExecStart=/usr/bin/node $APP_DIR/index.js
WorkingDirectory=$APP_DIR
Restart=always
User=root
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable rrwa.service
    systemctl restart rrwa.service

    logo
    echo -e "${GREEN}✔ Tudo instalado e rodando!${RESET}"
    echo "Acesse: http://SEU-IP:8080"
    read -p "ENTER para voltar ao menu..."
}

reset_session() {
    logo
    echo -e "${YELLOW}[!] Apagando sessão WhatsApp...${RESET}"
    rm -rf "$APP_DIR/.wwebjs_auth"
    systemctl restart rrwa.service
    echo -e "${GREEN}✔ Sessão resetada.${RESET}"
    read -p "ENTER..."
}

change_port() {
    logo
    read -p "Nova porta: " port
    sed -i "s/\"port\": .*/\"port\": $port,/" "$CONFIG"
    systemctl restart rrwa.service
    echo -e "${GREEN}✔ Porta alterada para $port${RESET}"
    read -p "ENTER..."
}

uninstall_rrwa() {
    logo
    echo -e "${RED}[!] Removendo tudo...${RESET}"
    systemctl stop rrwa.service
    systemctl disable rrwa.service
    rm -f "$SERVICE"
    systemctl daemon-reload
    rm -rf "$APP_DIR"
    echo -e "${GREEN}✔ Removido!${RESET}"
    read -p "ENTER..."
}

show_status() {
    logo
    systemctl status rrwa.service
    read -p "ENTER..."
}

menu() {
    while true; do
        logo
        echo -e "${BLUE}1) Instalar API${RESET}"
        echo -e "${BLUE}2) Resetar sessão${RESET}"
        echo -e "${BLUE}3) Alterar porta${RESET}"
        echo -e "${BLUE}4) Status do serviço${RESET}"
        echo -e "${RED}5) Desinstalar${RESET}"
        echo -e "${YELLOW}0) Sair${RESET}"
        echo ""
        read -p "Escolha: " opt

        case $opt in
            1) install_rrwa ;;
            2) reset_session ;;
            3) change_port ;;
            4) show_status ;;
            5) uninstall_rrwa ;;
            0) exit ;;
            *) echo "Opção inválida" ;;
        esac
    done
}

menu
