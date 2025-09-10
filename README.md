
<h1 align="center">🛠️ Persistent Helper</h1>
<p align="center">
Script em <b>Bash</b> para corrigir automaticamente problemas comuns no Linux: <br>
<strong>Wi-Fi / DNS</strong> • <strong>Terminal</strong> • <strong>Pacotes quebrados</strong>
</p>

---

## 👨‍💻 Autor
- 👤 **Thiago Amorim** (@0xffff00)  
- 📚 Turma: 1B - IFAL  

---

## 🚀 Funcionalidades
✔️ Corrige **Wi-Fi / resolv.conf / DNS**  
✔️ Repara **GNOME Terminal e permissões do usuário**  
✔️ Conserta **pacotes quebrados** (`dpkg`, `apt-get`, `initramfs`)  
✔️ Adiciona usuário ao grupo **sudo** automaticamente  
✔️ **Menu interativo** com 3 opções:  

[ 1 ] Corrigir Wi-Fi\
[ 2 ] Corrigir Terminal\
[ 3 ] Correção Total (Wi-Fi + Terminal + Pacotes)\
[ 0 ] Sair

---

## ⚙️ Pré-requisitos
- Linux com **systemd + NetworkManager**  
- Permissões de **sudo**  
- Pacotes básicos já instalados:  
  - `bash`  
  - `coreutils`  
  - `util-linux`  
  - `git`  

---

## 📥 Instalação
Clone este repositório:
```bash
git clone https://github.com/Th1iago3/PersistentHelper
cd PersistentHelper
chmod +x PersistentHelper.sh
sudo bash PersistentHelper.sh
````

---

## 🧩 Estrutura do Script

* **fix\_wifi** → recria `resolv.conf`, aplica DNS do Google, protege contra alterações e reinicia o NetworkManager.
* **fix\_terminal** → corrige permissões do usuário, instala pacotes essenciais, reconfigura GNOME Terminal e corrige pacotes quebrados.
* **fix\_all** → executa **Wi-Fi + Terminal + Pacotes** de uma só vez.

---

## 🎯 Exemplo de Uso

```bash
sudo ./PersistentHelper.sh
```

🔹 O script abrirá o menu principal para escolher a ação desejada.

---

## 📌 Licença

Distribuído livremente para fins educacionais.

<p align="center">
Feito com ❤️ por <b>Thiago Amorim</b> (1B - IFAL) <br>
Contato: <a href="https://github.com/Th1iago3">@0xffff00</a>
</p>

---
