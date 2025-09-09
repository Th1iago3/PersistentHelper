#!/bin/bash
# ====================================================
# Script de Correção Completo - IFAL
# Feito por: Thiago Amorim (1B - IFAL)
# Contato: @0xffff00
# ====================================================

# Cores para logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

# Função de log com separador e delay
function log_step {
    echo -e "\n${BLUE}=====================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${BLUE}=====================================${NC}\n"
    sleep 1
}

# Função para mostrar detalhes do resolv.conf
function show_file_details {
    hexdump -C /etc/resolv.conf
    echo -e "${YELLOW} $(du -b /etc/resolv.conf | cut -f1) bytes${NC}"
}

# Executar comandos como labadm sem pedir senha interativa
function run_as_labadm {
    echo "ifal1234" | sudo -S -u labadm bash -c "$1"
}

# Corrigir Wi-Fi
function fix_wifi {
    log_step "[ 1 ]: Corrigindo Wi-Fi..."

    sudo rm -f /etc/resolv.conf
    echo -e "${GREEN}[ 1 ]: Arquivo resolv.conf removido.${NC}"

    sudo touch /etc/resolv.conf
    sudo chmod 644 /etc/resolv.conf

    log_step "[ 1 ]: Injetando servidores DNS..."
    sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
    sudo bash -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'

    sudo chattr +i /etc/resolv.conf
    show_file_details

    log_step "[ 1 ]: Reiniciando NetworkManager..."
    sudo systemctl restart NetworkManager
    echo -e "${GREEN}[ 1 ]: Wi-Fi corrigido com sucesso!${NC}"
}

# Corrigir Terminal (gnome-terminal, permissões e pacotes)
function fix_terminal {
    CURRENT_USER=$(whoami)
    log_step "[ 2 ]: Corrigindo Terminal do usuário: $CURRENT_USER"

    # Adicionar usuário atual ao grupo sudo usando labadm
    run_as_labadm "usermod -aG sudo $CURRENT_USER"
    echo -e "${GREEN}[ 2 ]: Usuário $CURRENT_USER adicionado ao grupo sudo.${NC}"

    # Corrigir permissões da home
    sudo chown "$CURRENT_USER:$CURRENT_USER" /home/"$CURRENT_USER"
    sudo chmod 755 /home/"$CURRENT_USER"
    echo -e "${GREEN}[ 2 ]: Permissões da home corrigidas.${NC}"

    # Instalar pacotes essenciais
    log_step "[ 2 ]: Instalando pacotes necessários para o Terminal..."
    run_as_labadm "apt-get update -y && apt-get install -y gnome-terminal bash sudo"

    # Reconfigurar GNOME terminal
    run_as_labadm "dpkg-reconfigure gnome-terminal --frontend=noninteractive"
    echo -e "${GREEN}[ 2 ]: GNOME Terminal reconfigurado.${NC}"

    log_step "[ 2 ]: Injetando correções no ambiente..."
    run_as_labadm "gsettings reset org.gnome.Terminal.Legacy.Settings default-show-menubar"
    run_as_labadm "gsettings set org.gnome.desktop.default-applications.terminal exec 'gnome-terminal'"
    echo -e "${GREEN}[ 2 ]: Terminal configurado com sucesso para $CURRENT_USER.${NC}"
}

# Verificar se está rodando com sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ E ]: Execute este script com sudo: sudo $0${NC}"
    exit 1
fi

# Menu principal
clear
echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}     P E R S I S T E N T - H E L P E R     ${NC}"
echo -e "${GREEN}        Thiago Amorim (1B - IFAL)    ${NC}"
echo -e "${GREEN}             @0xffff00               ${NC}"
echo -e "${BLUE}=====================================${NC}"
echo -e "${YELLOW}[ 1 ]: Corrigir Wi-Fi${NC}"
echo -e "${YELLOW}[ 2 ]: Corrigir Terminal${NC}"
echo -e "${YELLOW}[ 0 ]: Sair${NC}"
echo -e "${BLUE}=====================================${NC}"
read -p "Escolha uma opção: " OPTION

case $OPTION in
    1) fix_wifi ;;
    2) fix_terminal ;;
    0) echo -e "${RED}Saindo...${NC}" ;;
    *) echo -e "${RED}Opção inválida.${NC}" ;;
esac

echo -e "\n${BLUE}=====================================${NC}"
echo -e "${GREEN}Feito por: Thiago Amorim (1B - IFAL)${NC}"
echo -e "${GREEN}Contato: @0xffff00${NC}"
echo -e "${BLUE}=====================================${NC}"
