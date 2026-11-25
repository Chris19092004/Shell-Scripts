# 🐚 Shell Scripts

![Shell](https://img.shields.io/badge/Shell_Script-Bash-4EAA25?logo=gnubash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black)
![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?logo=archlinux&logoColor=white)
![Status](https://img.shields.io/badge/status-em%20progresso-yellow)

> Minha coleção de shell scripts para instalar sistemas, configurar ambientes e automatizar tarefas repetitivas no Linux.

---

## 📚 Sumário

- [Sobre o repositório](#-sobre-o-repositório)
- [Por que aprender Shell Script?](#-por-que-aprender-shell-script)
- [Scripts disponíveis](#-scripts-disponíveis)
- [Detalhes dos scripts](#-detalhes-dos-scripts)
- [Como usar](#-como-usar)
- [Avisos importantes](#-avisos-importantes)
- [Convenções](#-convenções)
- [Roadmap](#-roadmap)
- [Recursos para estudar](#-recursos-para-estudar)

---

## 📖 Sobre o repositório

Este repositório reúne os **shell scripts** que escrevo para o meu dia a dia. Ele cobre, principalmente:

- **Instalação de sistemas Linux**, como o Arch, do particionamento ao bootloader;
- **Pós-instalação**, deixando o sistema pronto para uso, com usuário, pacotes, serviços e ferramentas configurados;
- **Automação de tarefas repetitivas**, como manutenção, backups e organização de arquivos.

Hoje ele tem os dois scripts de instalação do Arch Linux, mas a ideia é que cresça aos poucos, conforme novas necessidades aparecerem.

## 🤔 Por que aprender Shell Script?

O shell é a interface mais direta com o sistema operacional, e saber escrever scripts transforma o terminal de uma ferramenta de uso manual em uma ferramenta de automação. Alguns motivos pelos quais essa é uma ótima habilidade:

- **Está em toda parte.** O shell está presente em praticamente qualquer sistema Linux ou Unix, sem instalar nada. Em servidores remotos, containers e ambientes mínimos, como o *live* de instalação do Arch, o shell costuma ser a ferramenta que você tem à mão.
- **É a "linguagem cola".** Scripts combinam programas que já existem por meio de pipes e redirecionamentos, seguindo a filosofia Unix de ferramentas pequenas que fazem uma coisa bem feita. Por exemplo, os 10 maiores arquivos de uma pasta saem em uma linha:
  ```bash
  du -ah . | sort -rh | head -n 10
  ```
- **Automatiza o repetitivo e reduz erros.** Tudo que você faz mais de duas vezes no terminal merece virar um script. Ele executa sempre os mesmos passos, na mesma ordem, sem esquecimentos.
- **Reprodutibilidade.** Um script de instalação é a documentação executável de como o seu sistema é montado. Reinstalar uma máquina deixa de ser horas de cliques e passa a ser rodar um comando, e o processo todo fica versionado com Git.
- **É rápido de escrever e de testar.** O que você já digita no terminal vira script quase sem mudanças:
  ```bash
  #!/bin/bash
  set -euo pipefail

  origem="$HOME/Documentos"
  destino="$HOME/backups/documentos_$(date +%F).tar.gz"

  mkdir -p "$(dirname "$destino")"
  tar -czf "$destino" "$origem"
  echo "Backup criado em $destino"
  ```
- **É a base de DevOps e administração de sistemas.** Pipelines de CI/CD, Dockerfiles, *entrypoints* de containers, tarefas agendadas (`cron` e *timers* do `systemd`) e *git hooks* usam shell o tempo todo.
- **Ensina como o sistema funciona.** Para automatizar uma instalação, você precisa entender partições, sistemas de arquivos, serviços, permissões e gerenciadores de pacotes. Escrever os scripts é uma forma prática de aprender tudo isso.
- **Poucas dependências.** Um script Bash roda onde o Bash estiver, sem runtime extra, bibliotecas ou ambiente virtual.

### Quando o Shell Script não é a melhor escolha

Shell é excelente para orquestrar comandos e automatizar o sistema, mas não para tudo. Para lógica complexa, estruturas de dados elaboradas, manipulação pesada de JSON ou programas grandes, uma linguagem como o Python costuma ser mais adequada. Saber quando trocar de ferramenta também faz parte da habilidade.

### Personalização

Os scripts refletem o meu setup. Antes de usar, revise e ajuste:

| O que | Onde |
|-------|------|
| Disco de destino | Argumento do `arch_install.sh` (padrão `/dev/sda`) |
| Tamanho do EFI e do swap | Comandos `sgdisk` do `arch_install.sh` |
| Fuso horário, *locales*, teclado e *hostname* | Bloco `chroot` do `arch_install.sh` |
| Nome do usuário | Variável `TARGET_USER` no `arch_postInstallation.sh` |
| Pacotes (pacman, AUR e Flatpak) | Comandos de instalação do `arch_postInstallation.sh` |

## ⚠️ Avisos importantes

- **O `arch_install.sh` apaga TODO o conteúdo do disco indicado.** Confira o disco com `lsblk` antes de executar.
- Os scripts foram feitos para **UEFI**. Não funcionam em instalações BIOS/MBR.
- Estão ajustados para o meu uso (fuso `America/Sao_Paulo`, teclado `br-abnt2`, pacotes escolhidos por mim). **Leia e adapte antes de rodar.**
- Os dois scripts são **parcialmente interativos**: pedem a senha de root e a do usuário.
- O `arch_postInstallation.sh` assume o layout criado pelo `arch_install.sh`. Em outra instalação, a parte do Snapper pode não funcionar.
- O script de pós-instalação baixa e executa o instalador do Nix direto da internet (`curl | sh`). Revise se isso não for aceitável para você.
- **Teste primeiro em uma máquina virtual** (QEMU, VirtualBox, etc.) antes de rodar em hardware real.
- **RODE POR SUA CONTA E RISCO!**

## 🧭 Convenções

Padrões que sigo nos scripts, para mantê-los seguros e legíveis:

- **Modo estrito:** `#!/bin/bash` seguido de `set -euo pipefail`. O script para no primeiro erro (`-e`), trata variável não definida como erro (`-u`) e falha se qualquer comando de um pipe falhar (`pipefail`).
- **Parâmetros com valor padrão**, como `DISK="${1:-/dev/sda}"`, em vez de valores fixos espalhados pelo código.
- **Variáveis em maiúsculas** para configurações no topo do script, como `TARGET_USER`.
- **`trap` para limpeza**, garantindo que alterações temporárias sejam desfeitas mesmo em caso de falha.
- **Comentários em português** explicando o que cada bloco faz e por quê.
- **Mensagens de progresso** com `echo`, para acompanhar a execução.
- **Validação com [ShellCheck](https://www.shellcheck.net/)** para pegar erros comuns antes de executar.


## 💡 Sugestões

Encontrou um erro, uma melhoria ou uma ideia de script? Fique à vontade para abrir uma *issue* ou um *pull request*.
