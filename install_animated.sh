#!/bin/bash

# ======= CORES =======
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


# ======= ANIMAÇÃO SPINNER =======
spin() {
    sp='/-\|'
    while true; do
        printf "\r${MAGENTA}[$sp]${RESET} $1"
        sp=${sp#?}${sp%${sp#?}}
        sleep 0.1
    done
}

# ======= LOGO =======
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


# ======= INSTALAÇÃO =======
install_rrwa() {
    logo
    echo -e "${GREEN}[+] Iniciando instalação...${RESET}"

    spin "Atualizando sistema..." &
    SP=$!
    apt update -y &>/dev/null
    apt upgrade -y &>/dev/null
    kill $SP
    echo ""

    echo -e "${GREEN}[+] Instalando dependências básicas...${RESET}"
    apt install -y git curl wget unzip nano &>/dev/null

    echo -e "${GREEN}[+] Instalando NodeJS 18...${RESET}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - &>/dev/null
    apt install -y nodejs build-essential &>/dev/null

    echo -e "${GREEN}[+] Baixando API...${RESET}"
    rm -rf "$APP_DIR"
    git clone https://github.com/remontti/RR-WhatsApp-API.git "$APP_DIR" &>/dev/null
    cd "$APP_DIR"

    echo -e "${GREEN}[+] Instalando dependências do projeto...${RESET}"
    npm install --force &>/dev/null

    echo -e "${GREEN}[+] Instalando Chromium do Puppeteer...${RESET}"
    npm install puppeteer &>/dev/null

    echo -e "${GREEN}[+] Aplicando correções automáticas no index.js...${RESET}"

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
    echo -e "${GREEN}✔ Instalação concluída!${RESET}"
    echo "Acesse: http://SEU-IP:8080"
    read -p "ENTER para voltar..."
}

# ======= EDITAR IPs PERMITIDOS =======
edit_ips() {
    logo
    echo -e "${YELLOW}IPs atuais permitidos:${RESET}"
    jq '.allowedIPs' "$CONFIG"
    echo ""
    read -p "Digite os novos IPs separados por vírgula (ex: 192.168.0.10, 10.0.0.5, *): " newips

    newips_json=$(echo "$newips" | sed 's/, */","/g')
    echo -e "${GREEN}[+] Salvando...${RESET}"

cat <<EOF > "$CONFIG"
{
  "port": $(jq '.port' $CONFIG),
  "allowedIPs": ["$newips_json"]
}
EOF

    systemctl restart rrwa.service
    echo -e "${GREEN}✔ IPs atualizados!${RESET}"
    read -p "ENTER..."
}

# ======= START / STOP / RESTART =======
start_service() {
    systemctl start rrwa.service
    echo -e "${GREEN}✔ Serviço iniciado!${RESET}"
    read -p "ENTER..."
}

stop_service() {
    systemctl stop rrwa.service
    echo -e "${RED}✔ Serviço parado.${RESET}"
    read -p "ENTER..."
}

restart_service() {
    systemctl restart rrwa.service
    echo -e "${GREEN}✔ Serviço reiniciado.${RESET}"
    read -p "ENTER..."
}

# ======= RESET SESSÃO =======
reset_session() {
    logo
    echo -e "${YELLOW}[!] Limpando sessão WhatsApp...${RESET}"
    rm -rf "$APP_DIR/.wwebjs_auth"
    systemctl restart rrwa.service
    echo -e "${GREEN}✔ Sessão resetada.${RESET}"
    read -p "ENTER..."
}

# ======= ALTERAR PORTA =======
change_port() {
    logo
    read -p "Nova porta: " port

    jq --arg p "$port" '.port = ($p|tonumber)' "$CONFIG" > "$CONFIG.tmp"
    mv "$CONFIG.tmp" "$CONFIG"

    systemctl restart rrwa.service
    echo -e "${GREEN}✔ Porta alterada para $port${RESET}"
    read -p "ENTER..."
}

# ======= DESINSTALAR =======
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

# ======= STATUS =======
show_status() {
    logo
    systemctl status rrwa.service
    read -p "ENTER..."
}

# ======= MENU =======
menu() {
    while true; do
        logo
        echo -e "${BLUE}1) Instalar API${RESET}"
        echo -e "${BLUE}2) Resetar sessão${RESET}"
        echo -e "${BLUE}3) Alterar porta${RESET}"
        echo -e "${BLUE}4) Editar IPs permitidos${RESET}"
        echo -e "${BLUE}5) Status API${RESET}"
        echo -e "${BLUE}6) Iniciar serviço${RESET}"
        echo -e "${BLUE}7) Parar serviço${RESET}"
        echo -e "${BLUE}8) Reiniciar serviço${RESET}"
        echo -e "${RED}9) Desinstalar${RESET}"
        echo -e "${YELLOW}0) Sair${RESET}"
        echo ""

        read -p "Escolha: " opt
        case $opt in
            1) install_rrwa ;;
            2) reset_session ;;
            3) change_port ;;
            4) edit_ips ;;
            5) show_status ;;
            6) start_service ;;
            7) stop_service ;;
            8) restart_service ;;
            9) uninstall_rrwa ;;
            0) exit ;;
            *) echo "Opção inválida" ;;
        esac
    done
}

menu
