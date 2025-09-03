# 🛠️ Fix Wi-Fi / DNS Resolver - Linux Script

> Script em **Bash** para corrigir problemas relacionados ao arquivo `/etc/resolv.conf` em distribuições Linux,  
com foco em sistemas que utilizam o **NetworkManager**.  
Ele recria o arquivo de configuração de DNS, aplica permissões corretas, protege contra alterações indevidas  
e reinicia o serviço de rede para garantir conectividade.

---

## 📌 Autor
- 👤 **Thiago Amorim** (@0xffff00)  
- 📚 1B IFAL  

---

## 🚀 Funcionalidades
✅ Remove o arquivo antigo `/etc/resolv.conf`  
✅ Cria um novo arquivo com as permissões corretas (`rw-r--r--`)  
✅ Define **DNS do Google** (`8.8.8.8` e `8.8.4.4`)  
✅ Protege o arquivo contra modificações (`chattr +i`)  
✅ Reinicia o **NetworkManager** para aplicar mudanças  

---

## ⚙️ Pré-requisitos
Antes de executar, certifique-se de ter:
- Um sistema Linux com **systemd + NetworkManager**  
- Permissões de **sudo**  
- Pacotes básicos já instalados (`bash`, `coreutils`, `util-linux`)  

---

## 📥 Instalação

Clone este repositório:
```bash
git clone https://github.com/seu-usuario/seu-repositorio.git
cd seu-repositorio
chmod +x PersistentHelper.sh
sudo bash PersistentHelper.sh
