#!/bin/bash
# ====================================================
#  P E R S I S T E N T - H E L P E R - IFAL
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
        hexdump -C /etc/resolv.conf | head -n 10
        echo -e "${YELLOW}$(stat -c%s /etc/resolv.conf) bytes${NC}"
    else
        echo -e "${RED}/etc/resolv.conf não existe${NC}"
    fi
}

function run_as_labadm {
    echo "ifal1234" | sudo -S -u labadm bash -c "$1"
}

# ====================================================
# FIX WIFI
# ====================================================
function fix_wifi {
    log_step "[ 1 ]: Corrigindo Wi-Fi..."
    sudo rm -f /etc/resolv.conf
    sudo install -m 644 /dev/null /etc/resolv.conf
    {
        echo "nameserver 8.8.8.8"
        echo "nameserver 8.8.4.4"
    } | sudo tee /etc/resolv.conf >/dev/null
    sudo chattr +i /etc/resolv.conf 2>/dev/null || true
    show_file_details
    sudo systemctl restart NetworkManager 2>/dev/null || \
    sudo service network-manager restart 2>/dev/null || true
    echo -e "${GREEN}[ 1 ]: Wi-Fi corrigido com sucesso!${NC}"
}

# ====================================================
# FIX DPKG STATUS
# ====================================================
function try_restore_dpkg_status {
    if [ ! -s /var/lib/dpkg/status ]; then
        log_step "Status do dpkg ausente. Tentando restaurar..."
        if [ -f /var/lib/dpkg/status-old ]; then
            sudo cp /var/lib/dpkg/status-old /var/lib/dpkg/status
            echo -e "${YELLOW}Restaurado de status-old${NC}"
        elif [ -f /var/backups/dpkg.status.0 ]; then
            sudo cp /var/backups/dpkg.status.0 /var/lib/dpkg/status
            echo -e "${YELLOW}Restaurado de /var/backups/dpkg.status.0${NC}"
        else
            echo -e "${RED}Nenhum backup do status encontrado.${NC}"
        fi
    fi
}

# ====================================================
# DETECT BINARIES
# ====================================================
function detect_and_map_missing_bins {
    declare -A MAP=(
        [ls]="coreutils" [cp]="coreutils" [mv]="coreutils"
        [chmod]="coreutils" [chown]="coreutils"
        [apt]="apt" [apt-get]="apt" [dpkg]="dpkg"
        [systemctl]="systemd" [init]="sysvinit-core"
        [bash]="bash" [grep]="grep" [sed]="sed" [awk]="gawk"
        [hostname]="net-tools" [ifconfig]="net-tools"
        [ip]="iproute2" [update-initramfs]="initramfs-tools"
        [grub-install]="grub-pc" [mount]="util-linux"
        [umount]="util-linux" [fdisk]="util-linux"
        [mkfs]="util-linux"
    )
    MISSINGS=()
    for cmd in "${!MAP[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            MISSINGS+=("${MAP[$cmd]}")
        fi
    done
    echo "${MISSINGS[@]}"
}

# ====================================================
# FIX TERMINAL
# ====================================================
function fix_terminal {
    CURRENT_USER=$(logname 2>/dev/null || whoami)
    log_step "[ 2 ]: Corrigindo Terminal + Utils para $CURRENT_USER"

    run_as_labadm "usermod -aG sudo $CURRENT_USER" 2>/dev/null || true
    sudo chown -R "$CURRENT_USER:$CURRENT_USER" /home/"$CURRENT_USER" 2>/dev/null || true
    sudo chmod 755 /home/"$CURRENT_USER" 2>/dev/null || true

    run_as_labadm "apt-get update -y --fix-missing || true"
    run_as_labadm "dpkg --configure -a || true"
    run_as_labadm "apt-get install -f -y || true"
    run_as_labadm "apt-get install -y --reinstall gnome-terminal bash sudo || true"
    run_as_labadm "update-initramfs -u -k all || true"

    sudo apt-get update -y --fix-missing || true
    try_restore_dpkg_status
    sudo dpkg --configure -a || true
    sudo apt-get install -f -y || true
    sudo apt-get clean || true
    sudo apt-get autoclean -y || true

    ESSENTIALS=(coreutils util-linux dpkg apt bash libc6 initramfs-tools net-tools iproute2 grep sed gawk grub-pc)
    MISSING_CMDS=($(detect_and_map_missing_bins))
    TO_INSTALL=($(printf "%s\n" "${ESSENTIALS[@]}" "${MISSING_CMDS[@]}" | sort -u))

    if [ ${#MISSING_CMDS[@]} -gt 0 ]; then
        log_step "Detectado pacotes ausentes: ${MISSING_CMDS[*]}"
    fi

    for p in "${TO_INSTALL[@]}"; do
        sudo apt-get install -y --reinstall "$p" || sudo apt-get install -y "$p" || true
    done

    sudo dpkg --configure -a || true
    sudo apt-get install -f -y || true
    sudo update-initramfs -u -k all || true

    echo -e "${GREEN}[ 2 ]: Terminal + utils corrigidos para $CURRENT_USER.${NC}"
}

# ====================================================
# FIX ALL
# ====================================================
function fix_all {
    log_step "[ 3 ]: Correção Total (Wi-Fi + Terminal + Utils)"
    fix_wifi
    fix_terminal
    echo -e "${GREEN}[ 3 ]: Correção total concluída!${NC}"
}

# ====================================================
# MAIN
# ====================================================
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ E ]: Execute com sudo: sudo $0${NC}"
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
