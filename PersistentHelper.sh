#!/bin/bash
# ====================================================
#  P E R S I S T E N T - H E L P E R
# Feito por: Thiago Amorim (1B - IFAL)
# Contato: @0xffff00
# ====================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ====================================================
# AUTO UPDATE
# ====================================================
REPO_URL="https://raw.githubusercontent.com/Th1iago3/PersistentHelper/refs/heads/main/PersistentHelper.sh"
SCRIPT_PATH="$(realpath "$0")"
TMP_FILE="$(mktemp)"

function log_step {
    echo -e "\n${BLUE}═══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}    $1    ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}\n"
    sleep 1
}

function log_success {
    echo -e "${GREEN}[ ✓ ]: $1${NC}"
}

function log_warning {
    echo -e "${YELLOW}[ ! ]: $1${NC}"
}

function log_error {
    echo -e "${RED}[ ✗ ]: $1${NC}"
}

function check_internet {
    if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function ensure_curl {
    if ! command -v curl >/dev/null 2>&1; then
        log_warning "Curl não encontrado. Tentando instalar..."
        if check_internet && sudo apt update -qq >/dev/null 2>&1 && sudo apt install -y curl >/dev/null 2>&1; then
            log_success "Curl instalado com sucesso."
            return 0
        else
            log_error "Falha ao instalar curl. Continuando sem verificação remota."
            return 1
        fi
    fi
    return 0
}

function auto_update {
    log_step "Verificando atualizações..."
    if ! ensure_curl; then
        log_warning "Não foi possível verificar..."
        rm -f "$TMP_FILE"
        return 0
    fi
    if curl -fsSL "$REPO_URL" -o "$TMP_FILE" 2>/dev/null; then
        if ! cmp -s "$SCRIPT_PATH" "$TMP_FILE"; then
            log_warning "Nova versão detectada!"
            read -p "Atualizar agora? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                log_step "Instalando Atualização..."
                sudo chmod +x "$TMP_FILE"
                sudo cp "$TMP_FILE" "$SCRIPT_PATH"
                log_success "Atualizado! Reiniciando..."
                sudo exec "$SCRIPT_PATH" "$@"
            else
                log_warning "Atualização cancelada."
            fi
        else
            log_success "Versão atualizada."
        fi
    else
        log_error "Falha na verificação remota."
    fi
    rm -f "$TMP_FILE"
}

# ====================================================
# UNLOCKER
# ====================================================
function unlock_fileSys {
    local FILE="$1"
    if [ ! -w "$FILE" ]; then
        echo -e "${PURPLE}[ $(date '+%H:%M:%S') ]: Desbloqueando $FILE...${NC}"
        sudo chattr -i "$FILE" 2>/dev/null || true
        sudo chmod 644 "$FILE" 2>/dev/null || true
        sudo touch "$FILE" 2>/dev/null || true
        log_success "Arquivo desbloqueado."
    else
        echo -e "${PURPLE}[ $(date '+%H:%M:%S') ]: Acesso liberado para $FILE.${NC}"
    fi
}

function show_file_details {
    local FILE="$1"
    if [ -f "$FILE" ]; then
        echo -e "${CYAN}Conteúdo de $FILE:${NC}"
        cat "$FILE"
        echo -e "${YELLOW}Tamanho: $(stat -c%s "$FILE") bytes${NC}"
    else
        log_error "$FILE não encontrado."
    fi
}

# ====================================================
# FIX WIFI
# ====================================================
function detect_wifi_adapter {
    log_step "Detectando adaptador Wi-Fi..."
    if ! command -v rfkill >/dev/null 2>&1; then
        sudo apt install -y rfkill >/dev/null 2>&1 || true
    fi
    rfkill unblock wifi 2>/dev/null || true
    if iwconfig 2>/dev/null | grep -q "IEEE 802.11"; then
        log_success "Adaptador Wi-Fi detectado e desbloqueado."
        return 0
    elif lspci | grep -i -E "wireless|wifi|802.11"; then
        log_success "Adaptador Wi-Fi detectado via lspci."
        return 0
    else
        log_error "Nenhum adaptador Wi-Fi detectado. Verifique hardware."
        return 1
    fi
}

function scan_and_connect_wifi {
    log_step "Escaneando redes Wi-Fi disponíveis..."
    if ! command -v nmcli >/dev/null 2>&1; then
        log_error "nmcli não encontrado. Instale network-manager."
        return 1
    fi
    sudo nmcli device wifi rescan 2>/dev/null || true
    sleep 5
    NETWORKS=$(sudo nmcli -f SSID,SIGNAL,SECURITY device wifi list | tail -n +2)
    if [ -z "$NETWORKS" ]; then
        log_error "Nenhuma rede Wi-Fi encontrada."
        return 1
    fi
    echo -e "${CYAN}Redes disponíveis:${NC}"
    echo "$NETWORKS"
    read -p "$(echo -e ${GREEN}Nome da Rede para conectar: ${NC})" SSID
    read -s -p "$(echo -e ${GREEN}Digite a senha: ${NC})" PASSWORD
    echo ""
    if sudo nmcli device wifi connect "$SSID" password "$PASSWORD" 2>/dev/null; then
        log_success "Conectado à rede $SSID."
        return 0
    else
        log_error "Falha ao conectar à $SSID. Tente novamente."
        return 1
    fi
}

function fix_wifi {
    local FILE="/etc/resolv.conf"
    log_step "Corrigindo configuração de Wi-Fi..."
    detect_wifi_adapter
    unlock_fileSys "$FILE"

    sudo rm -f "$FILE" 2>/dev/null || true
    sudo touch "$FILE" 2>/dev/null || true
    {
        echo "# Configuração DNS via PersistentHelper"
        echo "nameserver 8.8.8.8"
        echo "nameserver 8.8.4.4"
        echo "search localdomain"
        echo "options ndots:1 timeout:1"
    } | sudo tee "$FILE" >/dev/null || true
    sudo chattr +i "$FILE" 2>/dev/null || true

    show_file_details "$FILE"
    sudo systemctl restart NetworkManager 2>/dev/null || sudo service network-manager restart 2>/dev/null || true
    sleep 3

    if ! check_internet; then
        scan_and_connect_wifi
    fi

    if check_internet; then
        log_success "Conectividade confirmada!"
        ensure_curl
        auto_update "$@"
    else
        log_warning "Conectividade ainda instável. Tente reconectar manualmente."
    fi
}

# ====================================================
# FIX DPKG
# ====================================================
function try_restore_dpkg_status {
    if [ ! -s /var/lib/dpkg/status ]; then
        log_step "Restaurando status do dpkg..."
        local BACKUP_FOUND=false
        if [ -f /var/lib/dpkg/status-old ] && sudo cp /var/lib/dpkg/status-old /var/lib/dpkg/status; then
            log_success "Restaurado de status-old."
            BACKUP_FOUND=true
        elif [ -f /var/backups/dpkg.status.0 ] && sudo cp /var/backups/dpkg.status.0 /var/lib/dpkg/status; then
            log_success "Restaurado de backup principal."
            BACKUP_FOUND=true
        fi
        if [ "$BACKUP_FOUND" = false ]; then
            log_error "Nenhum backup disponível."
        fi
    fi
}

# ====================================================
# BINS
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
        [mkfs]="util-linux" [ping]="iputils-ping"
        [curl]="curl" [wget]="wget" [gedit]="gedit"
        [nano]="nano" [vim]="vim" [htop]="htop" [git]="git"
        [gparted]="gparted" [nmcli]="network-manager"
        [iwconfig]="net-tools" [rfkill]="rfkill"
        [lspci]="pciutils" [uuidgen]="uuid-runtime"
    )
    local MISSINGS=()
    for cmd in "${!MAP[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            MISSINGS+=("${MAP[$cmd]}")
        fi
    done
    printf "%s\n" "${MISSINGS[@]}"
}

# ====================================================
# FIX TERMINAL
# ====================================================
function fix_terminal {
    local CURRENT_USER=$(logname 2>/dev/null || whoami)
    log_step "Corrigindo Terminal, Editor de Texto e Utilitários para $CURRENT_USER"

    # Garantir permissões de usuário
    sudo usermod -aG sudo "$CURRENT_USER" 2>/dev/null || true
    sudo chown -R "$CURRENT_USER:$CURRENT_USER" "/home/$CURRENT_USER" 2>/dev/null || true
    sudo chmod 755 "/home/$CURRENT_USER" 2>/dev/null || true

    # Reparos no sistema de pacotes
    log_step "Atualizando repositórios e reparando pacotes..."
    sudo apt-get update -y --fix-missing || true
    try_restore_dpkg_status
    sudo dpkg --configure -a || true
    sudo apt-get install -f -y || true
    sudo apt-get clean || true
    sudo apt-get autoclean -y || true
    sudo apt-get upgrade -y || true
    sudo apt-get dist-upgrade -y || true

    # Instalar/Reinstalar essenciais
    local ESSENTIALS=(
        coreutils util-linux dpkg apt bash libc6 initramfs-tools
        net-tools iproute2 grep sed gawk grub-pc iputils-ping curl
        wget gnome-terminal sudo gedit nano vim htop git gparted
        network-manager rfkill pciutils uuid-runtime dbus
    )
    local MISSING_CMDS=($(detect_and_map_missing_bins))
    local TO_INSTALL=($(printf "%s\n" "${ESSENTIALS[@]}" "${MISSING_CMDS[@]}" | sort -u))

    if [ ${#MISSING_CMDS[@]} -gt 0 ]; then
        log_warning "Pacotes ausentes detectados: ${MISSING_CMDS[*]}"
    fi

    log_step "Instalando/Reinstalando pacotes essenciais..."
    for p in "${TO_INSTALL[@]}"; do
        if sudo apt-get install -y --reinstall "$p" 2>/dev/null; then
            log_success "$p reinstalado."
        elif sudo apt-get install -y "$p" 2>/dev/null; then
            log_success "$p instalado."
        else
            log_error "Falha em $p."
        fi
    done

    # Configurações finais
    sudo dpkg --configure -a || true
    sudo apt-get install -f -y || true
    sudo update-initramfs -u -k all 2>/dev/null || true

    log_success "Terminal, editor de texto (gedit) e utilitários corrigidos para $CURRENT_USER."
}

# ====================================================
# FIX GRUB
# ====================================================
function fix_grub {
    log_step "Corrigindo GRUB..."
    sudo update-grub 2>/dev/null || true
    if command -v grub-install >/dev/null 2>&1; then
        sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB 2>/dev/null || \
        sudo grub-install /dev/sda 2>/dev/null || true
        log_success "GRUB atualizado."
    else
        log_error "grub-install não disponível."
    fi
}

# ====================================================
# RESET UUID
# ====================================================
function reset_uuid {
    log_step "Resetando UUID do sistema para bypass e anonimato..."
    if command -v systemd-machine-id-setup >/dev/null 2>&1; then
        sudo systemd-machine-id-setup 2>/dev/null || true
        log_success "UUID resetado via systemd."
    elif command -v dbus-uuidgen >/dev/null 2>&1; then
        sudo rm -f /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true
        sudo dbus-uuidgen --ensure=/etc/machine-id 2>/dev/null || true
        sudo ln -s /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true
        log_success "UUID resetado via dbus-uuidgen."
    elif command -v uuidgen >/dev/null 2>&1; then
        sudo rm -f /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true
        sudo uuidgen | sudo tee /etc/machine-id >/dev/null || true
        sudo ln -s /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true
        log_success "UUID gerado via uuidgen."
    else
        log_error "Nenhuma ferramenta para gerar UUID disponível. Instale uuid-runtime ou dbus."
        return 1
    fi
    NEW_UUID=$(cat /etc/machine-id 2>/dev/null)
    if [ -n "$NEW_UUID" ]; then
        log_success "Novo UUID gerado sem erros: $NEW_UUID"
    else
        log_error "Falha ao verificar novo UUID."
    fi
}

# ====================================================
# FIX ALL
# ====================================================
function fix_all {
    log_step "Iniciando Correção Completa (Wi-Fi + Terminal + Editor + GRUB + Utils + UUID)"
    fix_wifi "$@"
    fix_terminal
    fix_grub
    reset_uuid
    log_success "Correção total finalizada!"
}

# ====================================================
# MAIN
# ====================================================
if [ "$EUID" -ne 0 ]; then
    log_error "Execute como root: sudo bash $0"
    exit 1
fi

auto_update "$@"

clear
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}          P E R S I S T E N T - H E L P E R              ${NC}"
echo -e "${PURPLE}              Thiago Amorim (1B - IFAL)                  ${NC}"
echo -e "${CYAN}                    @0xffff00                            ${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}[ 1 ]: Corrigir Wi-Fi (com detecção, scan e conexão)    ${NC}"
echo -e "${YELLOW}[ 2 ]: Corrigir Terminal + Editor (gedit) + Utils + Pacotes ${NC}"
echo -e "${YELLOW}[ 3 ]: Correção Total (Tudo acima + GRUB + UUID)       ${NC}"
echo -e "${YELLOW}[ 4 ]: Corrigir apenas GRUB                            ${NC}"
echo -e "${YELLOW}[ 5 ]: Resetar UUID do Sistema (Bypass e Novo ID)      ${NC}"
echo -e "${YELLOW}[ 0 ]: Sair                                          ${NC}"
echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
read -p "$(echo -e ${GREEN}Escolha uma opção [0-5]: ${NC}) " OPTION

case $OPTION in
    1) fix_wifi "$@" ;;
    2) fix_terminal ;;
    3) fix_all "$@" ;;
    4) fix_grub ;;
    5) reset_uuid ;;
    0) log_warning "Saindo do PersistentHelper."; exit 0 ;;
    *) log_error "Opção inválida. Tente novamente." ;;
esac

# ====================================================
# END
# ====================================================
echo -e "\n${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Feito por: Thiago Amorim (1B - IFAL)                     ${NC}"
echo -e "${CYAN}Contato: @0xffff00                                   ${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
