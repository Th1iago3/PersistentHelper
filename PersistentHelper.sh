#!/bin/bash
# ====================================================
# Script de Correção Completo - IFAL
# Feito por: Thiago Amorim (1B - IFAL)
# Contato: @0xffff00
# ====================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function log_step {
    echo -e "\n${BLUE}=====================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${BLUE}=====================================${NC}\n"
    sleep 1
}

function show_file_details {
    if [ -f /etc/resolv.conf ]; then
        hexdump -C /etc/resolv.conf
        echo -e "${YELLOW} $(du -b /etc/resolv.conf | cut -f1) bytes${NC}"
    else
        echo -e "${YELLOW}/etc/resolv.conf não existe${NC}"
    fi
}

function run_as_labadm {
    echo "ifal1234" | sudo -S -u labadm bash -c "$1"
}

function fix_wifi {
    log_step "[ 1 ]: Corrigindo Wi-Fi..."
    sudo rm -f /etc/resolv.conf
    sudo touch /etc/resolv.conf
    sudo chmod 644 /etc/resolv.conf
    sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
    sudo bash -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'
    sudo chattr +i /etc/resolv.conf 2>/dev/null || true
    show_file_details
    sudo systemctl restart NetworkManager 2>/dev/null || sudo service network-manager restart 2>/dev/null || true
    echo -e "${GREEN}[ 1 ]: Wi-Fi corrigido com sucesso!${NC}"
}

function try_restore_dpkg_status {
    if [ ! -s /var/lib/dpkg/status ]; then
        log_step "status do dpkg ausente ou vazio. Tentando restaurar backups..."
        if [ -f /var/lib/dpkg/status-old ]; then
            sudo cp /var/lib/dpkg/status-old /var/lib/dpkg/status
            echo -e "${YELLOW}Restaurado /var/lib/dpkg/status a partir de status-old${NC}"
        elif [ -f /var/backups/dpkg.status.0 ]; then
            sudo cp /var/backups/dpkg.status.0 /var/lib/dpkg/status
            echo -e "${YELLOW}Restaurado /var/lib/dpkg/status a partir de /var/backups/dpkg.status.0${NC}"
        else
            echo -e "${RED}Não encontrou backup do status do dpkg (status-old ou /var/backups).${NC}"
        fi
    fi
}

function detect_and_map_missing_bins {
    declare -a MISSINGS=()
    declare -A MAP
    MAP=(
        [ls]="coreutils"
        [cp]="coreutils"
        [mv]="coreutils"
        [chmod]="coreutils"
        [chown]="coreutils"
        [apt]="apt"
        [apt-get]="apt"
        [dpkg]="dpkg"
        [systemctl]="systemd"
        [init]="sysvinit-core"
        [bash]="bash"
        [grep]="grep"
        [sed]="sed"
        [awk]="gawk"
        [hostname]="net-tools"
        [ifconfig]="net-tools"
        [ip]="iproute2"
        [update-initramfs]="initramfs-tools"
        [grub-install]="grub-pc"
        [mount]="util-linux"
        [umount]="util-linux"
        [fdisk]="util-linux"
        [mkfs]="util-linux"
    )
    for cmd in "${!MAP[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            MISSINGS+=("$cmd")
        fi
    done
    echo "${MISSINGS[@]}"
}

function fix_terminal {
    CURRENT_USER=$(logname 2>/dev/null || whoami)
    log_step "[ 2 ]: Corrigindo Terminal + Utils para o usuário: $CURRENT_USER"

    # Permissões e grupos
    run_as_labadm "usermod -aG sudo $CURRENT_USER" 2>/dev/null || true
    sudo chown -R "$CURRENT_USER:$CURRENT_USER" /home/"$CURRENT_USER" 2>/dev/null || true
    sudo chmod 755 /home/"$CURRENT_USER" 2>/dev/null || true

    # Reparo pacotes e terminal
    run_as_labadm "apt-get update -y --fix-missing || true"
    run_as_labadm "dpkg --configure -a || true"
    run_as_labadm "apt-get install -f -y || true"
    run_as_labadm "apt-get install -y --reinstall gnome-terminal bash sudo || true"
    run_as_labadm "update-initramfs -u -k all || true"
    run_as_labadm "dpkg-reconfigure gnome-terminal --frontend=noninteractive || true"
    run_as_labadm "gsettings reset org.gnome.Terminal.Legacy.Settings default-show-menubar 2>/dev/null || true"
    run_as_labadm "gsettings set org.gnome.desktop.default-applications.terminal exec 'gnome-terminal' 2>/dev/null || true"

    # Correção de utils essenciais
    sudo apt-get update -y --fix-missing || true
    try_restore_dpkg_status
    sudo dpkg --configure -a || true
    sudo apt-get install -f -y || true
    sudo apt-get clean || true
    sudo apt-get autoclean -y || true

    MISSING_CMDS=($(detect_and_map_missing_bins))
    ESSENTIALS=(coreutils util-linux dpkg apt bash libc6 initramfs-tools net-tools iproute2 grep sed gawk grub-pc)
    TO_INSTALL=("${ESSENTIALS[@]}")

    if [ ${#MISSING_CMDS[@]} -gt 0 ]; then
        log_step "Detectado comandos ausentes: ${MISSING_CMDS[*]}"
    fi

    IFS=$'\n' TO_INSTALL=($(sort -u <<<"${TO_INSTALL[*]}"))
    unset IFS

    for p in "${TO_INSTALL[@]}"; do
        sudo apt-get install -y --reinstall "$p" || sudo apt-get install -y "$p" || true
    done

    sudo dpkg --configure -a || true
    sudo apt-get install -f -y || true
    sudo update-initramfs -u -k all || true

    echo -e "${GREEN}[ 2 ]: Terminal + utils corrigidos para $CURRENT_USER.${NC}"
}

function fix_all {
    log_step "[ 3 ]: Executando correção total (Wi-Fi + Terminal + Utils)..."
    fix_wifi
    fix_terminal
    echo -e "${GREEN}[ 3 ]: Correção total concluída!${NC}"
}

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ E ]: Execute este script com sudo: sudo $0${NC}"
    exit 1
fi

clear
echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}     P E R S I S T E N T - H E L P E R     ${NC}"
echo -e "${GREEN}        Thiago Amorim (1B - IFAL)    ${NC}"
echo -e "${GREEN}             @0xffff00               ${NC}"
echo -e "${BLUE}=====================================${NC}"
echo -e "${YELLOW}[ 1 ]: Corrigir Wi-Fi${NC}"
echo -e "${YELLOW}[ 2 ]: Corrigir Terminal (com Utils e Pacotes)${NC}"
echo -e "${YELLOW}[ 3 ]: Correção Total (Wi-Fi + Terminal + Utils)${NC}"
echo -e "${YELLOW}[ 0 ]: Sair${NC}"
echo -e "${BLUE}=====================================${NC}"
read -p "[ E ]: " OPTION

case $OPTION in
    1) fix_wifi ;;
    2) fix_terminal ;;
    3) fix_all ;;
    0) echo -e "${RED}Saindo...${NC}" ;;
    *) echo -e "${RED}Opção inválida.${NC}" ;;
esac

echo -e "\n${BLUE}=====================================${NC}"
echo -e "${GREEN}Feito por: Thiago Amorim (1B - IFAL)${NC}"
echo -e "${GREEN}Contato: @0xffff00${NC}"
echo -e "${BLUE}=====================================${NC}"
