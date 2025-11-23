#!/bin/bash

# CORES
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

progress_bar() {
    local duration=$1
    already_done() { for ((done=0; done<$1; done++)); do printf "█"; done }
    remaining() { for ((remain=0; remain<$1; remain++)); do printf " "; done }
    percentage() { printf "| %s%%" $(( ($1*100)/$2 )); }

    for ((i=0;i<=duration;i++)); do
        done=$(( (i*50)/duration ))
        remain=$(( 50-done ))
        printf "\r${MAGENTA}["; already_done $done; remaining $remain
        printf "]"
        percentage $i $duration
        printf "${RESET}"
        sleep 0.05
    done
    echo ""
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
    echo -e "${GREEN}[+] Atualizando sistema...${RESET}"
    progress_bar 30
    apt update -y &>/dev/null
    apt install -y git curl wget unzip nano &>/dev/null

    echo -e "${GREEN}[+] Instalando Node 18...${RESET}"
    progress_bar 20
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - &>/dev/null
    apt install -y nodejs build-essential &>/dev/null

    echo -e "${GREEN}[+] Instalando Chromium leve (do Debian)...${RESET}"
    progress_bar 15
    apt install -y chromium &>/dev/null

    echo -e "${GREEN}[+] Baixando repositório...${RESET}"
    rm -rf "$APP_DIR"
    git clone https://github.com/remontti/RR-WhatsApp-API.git "$APP_DIR" &>/dev/null
    cd "$APP_DIR"

    echo -e "${GREEN}[+] Instalando dependências do projeto...${RESET}"
    progress_bar 40
    npm install --production --force &>/dev/null
    npm install puppeteer-core --force &>/dev/null

    echo -e "${GREEN}[+] Ajustando index.js para usar Chromium nativo...${RESET}"
    sed -i 's/new Client({/new Client({ \
        puppeteer: { \
            executablePath: "\/usr\/bin\/chromium", \
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
    echo -e "${GREEN}✔ Instalação concluída com sucesso!${RESET}"
    echo "Acesse: http://SEU-IP:8080"
    read -p "ENTER..."
}

reset_session() {
    logo
    echo -e "${YELLOW}[!] Resetando sessão do WhatsApp...${RESET}"
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
    echo -e "${GREEN}✔ Porta alterada.${RESET}"
    read -p "ENTER..."
}

edit_allowed_ips() {
    logo
    echo "IPs atuais permitidos:"
    cat "$CONFIG"
    echo ""
    read -p "Digite os IPs separados por vírgula: " ips
    sed -i "s/\"allowedIPs\": .*/\"allowedIPs\": [$ips]/" "$CONFIG"
    systemctl restart rrwa.service
    echo -e "${GREEN}✔ IPs atualizados!${RESET}"
    read -p "ENTER..."
}

start_api() {
    logo
    systemctl start rrwa.service
    echo -e "${GREEN}✔ Serviço iniciado!${RESET}"
    read -p "ENTER..."
}

show_status() {
    logo
    systemctl status rrwa.service
    read -p "ENTER..."
}

uninstall_rrwa() {
    logo
    echo -e "${RED}[!] Removendo sistema...${RESET}"
    systemctl stop rrwa.service
    systemctl disable rrwa.service
    rm -f "$SERVICE"
    rm -rf "$APP_DIR"
    systemctl daemon-reload
    echo -e "${GREEN}✔ Removido.${RESET}"
    read -p "ENTER..."
}

menu() {
    while true; do
        logo
        echo -e "${BLUE}1) Instalar API${RESET}"
        echo -e "${BLUE}2) Resetar sessão${RESET}"
        echo -e "${BLUE}3) Alterar porta${RESET}"
        echo -e "${BLUE}4) Alterar IPs permitidos${RESET}"
        echo -e "${BLUE}5) Iniciar serviço${RESET}"
        echo -e "${BLUE}6) Status do serviço${RESET}"
        echo -e "${RED}7) Desinstalar${RESET}"
        echo -e "${YELLOW}0) Sair${RESET}"
        echo ""
        read -p "Escolha: " opt

        case $opt in
            1) install_rrwa ;;
            2) reset_session ;;
            3) change_port ;;
            4) edit_allowed_ips ;;
            5) start_api ;;
            6) show_status ;;
            7) uninstall_rrwa ;;
            0) exit ;;
            *) echo "Opção inválida" ;;
        esac
    done
}

menu
