#!/bin/bash

# Feito Por: @0xffff00 (Thiago Amorim, 1B IFAL)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function print_step {
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${BLUE}=====================================${NC}"
}

function show_file_details {
    hexdump -C /etc/resolv.conf
    echo -e "${YELLOW} $(du -b /etc/resolv.conf | cut -f1) bytes${NC}"
}

# Verificar se rodando como root (necessário para sudo, mas usaremos sudo nos comandos)
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ E ]: Por favor, execute este script com sudo: sudo $0${NC}"
    exit 1
fi

print_step "[ N ]: Inicializando..."
sudo rm -f /etc/resolv.conf
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[ N ]: Inicializado com sucesso!${NC}"
else
    echo -e "${RED}Erro ao remover o arquivo. Verifique permissões.${NC}"
    exit 1
fi

print_step "[ N ]: Inicializando NetworkManager..."
sudo touch /etc/resolv.conf
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[ N ]: Sucesso! Network Inicializada...${NC}"
else
    echo -e "${RED}Erro ao gerar arquivo.${NC}"
    exit 1
fi

print_step "[ N ]: Configurando Permissões..."
sudo chmod 644 /etc/resolv.conf
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[ N ]: Sucesso! Permissões Configuradas... (rw-r--r--)${NC}"
else
    echo -e "${RED}Erro ao definir permissões.${NC}"
    exit 1
fi

print_step "[ N ]: Injetando Bypass..."
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo bash -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'
if [ $? -eq 0 ]; then
    echo -e "${GREEN}${NC}"
    show_file_details 
else
    echo -e "${RED}Erro ao escrever no arquivo.${NC}"
    exit 1
fi

sudo chattr +i /etc/resolv.conf
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Arquivo protegido com sucesso! (imutável)${NC}"
    show_file_details 
else
    echo -e "${RED}Erro ao proteger o arquivo.${NC}"
    exit 1
fi

print_step "Reiniciando NetworkManager para aplicar mudanças"
sudo systemctl restart NetworkManager
if [ $? -eq 0 ]; then
    echo -e "${GREEN}NetworkManager reiniciado com sucesso!${NC}"
else
    echo -e "${RED}Erro ao reiniciar NetworkManager. Verifique se o serviço existe.${NC}"
    exit 1
fi

# Fim
echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}Wi-Fi Corrigido. Bom Uso! ${NC}"
echo -e "${GREEN}Feito Por: @0xffff00 (Thiago Amorim, 1B IFAL)${NC}"
echo -e "${BLUE}=====================================${NC}"

