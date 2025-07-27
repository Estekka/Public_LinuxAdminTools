#!/bin/bash
# .bashrc robuste pour administrateurs systèmes
# Compatible avec les distributions RedHat/CentOS/Fedora
# Auteur: Pierre Sardou

# Si non-interactif, sortir
case $- in
    *i*) ;;
      *) return;;
esac

# Historique
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
HISTTIMEFORMAT="%F %T "
HISTIGNORE="ls:ll:la:cd:pwd:exit:clear:history"
shopt -s histappend
shopt -s cmdhist

# Vérifier la taille de la fenêtre après chaque commande
shopt -s checkwinsize
shopt -s no_empty_cmd_completion    # Pas de complétion sur une ligne vide

# Comportement du shell
shopt -s autocd        # cd automatique en tapant un répertoire
shopt -s cdspell       # correction automatique des fautes de frappe dans cd
shopt -s dirspell      # correction des fautes de frappe dans le nom des répertoires
shopt -s globstar      # ** dans un chemin correspond à tous les fichiers et répertoires

# Activer la complétion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# PS1 intelligent avec couleurs, git, et exit code
__prompt_command() {
    local EXIT="$?"
    local RED='\[\e[31m\]'
    local GREEN='\[\e[32m\]'
    local YELLOW='\[\e[33m\]'
    local BLUE='\[\e[34m\]'
    local MAGENTA='\[\e[35m\]'
    local CYAN='\[\e[36m\]'
    local WHITE='\[\e[37m\]'
    local RESET='\[\e[0m\]'
    local BOLD='\[\e[1m\]'

    # Information sur la charge système et les utilisateurs
    local LOAD=$(uptime | awk '{print $(NF-2)}' | tr -d ',')
    local USERS=$(who | wc -l)

    # Détection du statut Git
    local GIT_BRANCH=""
    if command -v git >/dev/null 2>&1; then
        GIT_BRANCH=$(git branch 2>/dev/null | grep '^*' | colrm 1 2)
        if [ -n "$GIT_BRANCH" ]; then
            local GIT_STATUS=$(git status --porcelain 2>/dev/null)
            if [ -n "$GIT_STATUS" ]; then
                GIT_BRANCH="${RED}(${GIT_BRANCH} ✗)${RESET}"
            else
                GIT_BRANCH="${GREEN}(${GIT_BRANCH} ✓)${RESET}"
            fi
        fi
    fi

    # Détection de root
    local USER_COLOR="$GREEN"
    if [ "$EUID" -eq 0 ]; then
        USER_COLOR="$RED"
    fi

    # Exécution dans un conteneur?
    local CONTAINER=""
    if [ -f /.dockerenv ] || grep -q docker /proc/self/cgroup 2>/dev/null; then
        CONTAINER="${CYAN}[🐳]${RESET}"
    fi

    # Détection d'environnements virtuels
    local VENV=""
    if [ -n "$VIRTUAL_ENV" ]; then
        VENV="${BLUE}($(basename "$VIRTUAL_ENV"))${RESET} "
    fi

    # Code d'exit
    local EXIT_STATUS=""
    if [ $EXIT -ne 0 ]; then
        EXIT_STATUS="${RED}[$EXIT]${RESET} "
    fi

    # PS1 final
    PS1="${CONTAINER}${VENV}${EXIT_STATUS}${USER_COLOR}\u${RESET}@${BOLD}${YELLOW}\h${RESET}:${BLUE}\w${RESET} ${GIT_BRANCH}\n"
    
    # Ajout de la charge système et des utilisateurs aux serveurs
    if [ -n "$SSH_CONNECTION" ] || [ "$USER" = "root" ]; then
        PS1="${PS1}${MAGENTA}[${LOAD} | ${USERS} users]${RESET} \\$ "
    else
        PS1="${PS1}\\$ "
    fi
}
PROMPT_COMMAND=__prompt_command

# Alias utiles
alias ls='ls --color=auto'
alias ll='ls -la'
alias l='ls -lh'
alias la='ls -A'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -c'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias mkdir='mkdir -pv'
alias path='echo -e ${PATH//:/\\n}'
alias ports='netstat -tulanp'
alias h='history'
alias j='jobs -l'
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%d-%m-%Y"'
alias wget='wget -c'
alias nethogs='nethogs eth0'
alias iotop='iotop -o'

# Alias sécurité
alias rm='rm -I --preserve-root'
alias chmod='chmod --preserve-root'
alias chown='chown --preserve-root'
alias c='clear'
alias update-rhel='sudo yum update -y'
alias update-redhat='sudo yum update -y'
alias update-fedora='sudo dnf update -y'

# Alias pour systemd
alias sc='systemctl'
alias sc-status='systemctl status'
alias sc-start='systemctl start'
alias sc-stop='systemctl stop'
alias sc-restart='systemctl restart'
alias sc-enable='systemctl enable'
alias sc-disable='systemctl disable'
alias sc-reload='systemctl daemon-reload'
alias sc-list='systemctl list-unit-files --state=enabled'
alias jc='journalctl'
alias jc-f='journalctl -f'
alias jc-u='journalctl -u'

# Fonctions utiles
# Créer un répertoire et s'y déplacer
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extraire n'importe quel type d'archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' ne peut pas être extrait via extract()" ;;
        esac
    else
        echo "'$1' n'est pas un fichier valide"
    fi
}

# Recherche avec grep récursif
ftext() {
    grep -r "$1" .
}

# Information complète sur le système
sysinfo() {
    echo -e "\nInformation sur le système:\n"
    echo -e "Kernel: $(uname -r)"
    echo -e "Hostname: $(hostname)"
    echo -e "Uptime: $(uptime -p)"
    echo -e "Utilisateurs: $(who | wc -l)"
    echo -e "Charge système: $(cat /proc/loadavg | cut -d ' ' -f1-3)"
    echo -e "CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d ':' -f2 | sed 's/^ *//')"
    echo -e "Mémoire: $(free -h | grep Mem | awk '{print $3 " / " $2}')"
    echo -e "Espace disque: $(df -h / | awk 'NR==2 {print $3 " / " $2}')"
    echo -e "Services actifs: $(systemctl list-units --type=service --state=active | grep .service | wc -l)"
    echo -e "Connexions réseau: $(netstat -tuan | grep ESTABLISHED | wc -l)"
    echo -e "IPv4 publique: $(curl -s ifconfig.me 2>/dev/null || echo 'Non disponible')"
    
    if command -v firewall-cmd >/dev/null 2>&1; then
        echo -e "Firewall: $(firewall-cmd --state)"
    elif command -v ufw >/dev/null 2>&1; then
        echo -e "Firewall: $(ufw status | head -1)"
    fi
    
    if [ -f /etc/redhat-release ]; then
        echo -e "Distribution: $(cat /etc/redhat-release)"
    elif [ -f /etc/os-release ]; then
        echo -e "Distribution: $(grep PRETTY_NAME /etc/os-release | cut -d '"' -f2)"
    fi
    
    echo -e "\nDernières connexions SSH:"
    last -a | head -5
    echo
}

# Vérification rapide de sécurité
secscan() {
    echo -e "\nVérification de sécurité rapide:\n"
    echo -e "Utilisateurs avec UID 0:"
    grep 'x:0:' /etc/passwd
    
    echo -e "\nConnexions actives:"
    w
    
    echo -e "\nProcessus suspects (CPU/MEM élevés):"
    ps aux | awk '{if($3>0.5 || $4>0.5) print $0}'
    
    echo -e "\nConnexions réseau actives:"
    netstat -tunapM | grep ESTABLISHED
    
    echo -e "\nDerniers utilisateurs ajoutés:"
    grep -v nologin /etc/passwd | tail -5
    
    echo -e "\nAutorités SSH:"
    if [ -d ~/.ssh ]; then
        ls -la ~/.ssh/
    fi
    
    echo -e "\nTâches cron pour l'utilisateur actuel:"
    crontab -l 2>/dev/null || echo "Pas de tâches cron"
    
    echo -e "\nFichiers setuid/setgid:"
    find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -la {} \; 2>/dev/null | head -10
    
    echo
}

# Moniteur réseau simple
netmon() {
    watch -n1 "netstat -tunap | grep ESTABLISHED"
}

# Vérification des services
check_services() {
    local services=("sshd" "httpd" "nginx" "mariadb" "postgresql" "firewalld")
    
    echo -e "\nStatut des services principaux:\n"
    for service in "${services[@]}"; do
        systemctl is-active --quiet $service
        if [ $? -eq 0 ]; then
            echo -e "$service: \e[32mActif\e[0m"
        else
            echo -e "$service: \e[31mInactif\e[0m"
        fi
    done
    echo
}

# Analyser les fichiers logs
checklog() {
    local log=${1:-/var/log/messages}
    if [ -f "$log" ]; then
        echo -e "\nDernières entrées de $log:\n"
        sudo tail -n 50 "$log" | grep -i "error\|warn\|fail\|denied\|refused"
    else
        echo -e "\nFichier $log non trouvé. Logs disponibles:"
        ls -la /var/log/ | grep -v "\.gz$"
    fi
}

# Fonction pour voir rapidement les ports ouverts
open_ports() {
    echo -e "\nPorts en écoute sur le système:\n"
    ss -tulpn | grep LISTEN
}

# Fonction pour sauvegarder un fichier
backup() {
    if [ -f "$1" ]; then
        local date=$(date +%Y%m%d-%H%M%S)
        cp "$1" "${1}_${date}.bak"
        echo "Sauvegarde créée: ${1}_${date}.bak"
    else
        echo "Erreur: $1 n'existe pas"
    fi
}

# Variables d'environnement
export EDITOR=vim
export VISUAL=vim
export LANG=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8
export HISTIGNORE="ls:ll:la:cd:pwd:exit:clear:history"

# Définir une fonction pour évaluer les expressions mathématiques
calc() {
    bc -l <<< "$@"
}

# Message de bienvenue (dans une fonction pour éviter l'affichage à chaque sous-shell)
welcome_message() {
    echo -e "\e[1;34mBienvenue sur \e[1;33m$(hostname)\e[0m"
    echo -e "\e[1;32mUtilisateur:\e[0m $(whoami) | \e[1;32mDate:\e[0m $(date '+%d/%m/%Y %H:%M:%S')"
    echo -e "\e[1;32mUptime:\e[0m $(uptime -p) | \e[1;32mCharge:\e[0m $(uptime | awk '{print $(NF-2), $(NF-1), $NF}')"
    if [ -f /etc/redhat-release ]; then
        echo -e "\e[1;32mOS:\e[0m $(cat /etc/redhat-release)"
    fi
    echo -e "\e[1;32mMémoire:\e[0m $(free -h | awk '/^Mem/ {print $3 " utilisé sur " $2}')"
    echo -e "\e[1;32mDisque:\e[0m $(df -h / | awk 'NR==2 {print $3 " utilisé sur " $2 " (" $5 ")"}')"
    echo -e "\e[0;36mTapez 'sysinfo' pour les détails complets du système\e[0m"
    echo -e "\e[0;36mTapez 'secscan' pour une vérification rapide de sécurité\e[0m"
    echo -e "\e[0;36mTapez 'check_services' pour vérifier les services principaux\e[0m"
}

# Afficher le message de bienvenue seulement pour les shells interactifs et non pour les sous-shells
if [[ $- == *i* ]] && [[ -z "$PROMPT_COMMAND_EXECUTED" ]]; then
    export PROMPT_COMMAND_EXECUTED=1
    welcome_message
fi
