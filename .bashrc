# "$HOME"/.bashrc: executed by bash(1) for non-login shells.
# See /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
        *) return;;
esac

# Disable ctrl-s and ctrl-q.
stty -ixon

# If missing, create empty history file
if [[ -z ${HISTFILE+x} ]]; then
    [[ ! -f "$HOME/.bash_history" ]] && touch "$HOME/.bash_history"
else
    [[ ! -f "$HISTFILE" ]] && touch "$HISTFILE"
fi

# Infinite history.
HISTSIZE=
HISTFILESIZE=

# Don't put duplicate lines or lines starting with space in the history.
# erasedups causes all previous lines matching the current line to be removed
# from the history list before that line is saved.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# If we're disconnected, capture whatever is in history
trap 'history -a' SIGHUP

# Append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Allows you to cd into directory merely by typing the directory name.
shopt -s autocd

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# Perform spelling correction on directory names
shopt -s cdspell
shopt -s dirspell

# Disable the bell
iatest=$(expr index "$-" i)
if [[ "$iatest" -gt 0 ]]; then bind "set bell-style visible"; fi

# Make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Make sure 256 color terminals are enabled
case $TERM in "") TERM=xterm-256color;; esac

# Flash the terminal until the user presses a key
# Usage: long_running_command; flash
# https://en.wikipedia.org/wiki/ANSI_escape_code#In_shell_scripting
flash () {
    while true; do
        printf \\e[?5h;
        sleep 0.2;
        printf \\e[?5l;
        read -r -s -n1 -t1 && break;
    done;
}

# Set default editor
E=$(which micro)
export EDITOR="${E}"

# Set micro editor true color support
export COLORTERM=truecolor
export MICRO_TRUECOLOR=1

# Colorful man pages
man() {
    env \
    LESS_TERMCAP_mb="$(printf "\e[1;31m")" \
    LESS_TERMCAP_md="$(printf "\e[1;31m")" \
    LESS_TERMCAP_me="$(printf "\e[0m")" \
    LESS_TERMCAP_se="$(printf "\e[0m")" \
    LESS_TERMCAP_so="$(printf "\e[1;44;33m")" \
    LESS_TERMCAP_ue="$(printf "\e[0m")" \
    LESS_TERMCAP_us="$(printf "\e[1;32m")" \
    man "$@"
}

# Enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        source /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        source /etc/bash_completion
    elif [[ $(uname) == 'Darwin' ]]; then
        if [ -f "$(brew --prefix)"/etc/bash_completion ]; then
            source "$(brew --prefix)"/etc/bash_completion
        fi
    fi
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# "$HOME"/.aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f "$HOME"/.aliases ]; then
    source "$HOME"/.aliases
fi

# Bash completion for `dots` alias
_completion_loader git
complete -o bashdefault -o default -o nospace -F __git_wrap__git_main dots

# If running in console 1, start X display server
if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] ; then
    exec startx
fi

# Cross-platform .gitconfig
OS=$(uname -a)
if command -v git > /dev/null 2>&1; then
    case $OS in
        *microsoft*)
            git config --global include.path "$HOME"/.config/git/wsl.gitconfig
            ;;
        Linux*)
            git config --global include.path "$HOME"/.config/git/linux.gitconfig
            ;;
    esac
fi

# Get current branch in Git repository
parse_git_branch() {
    if command -v git > /dev/null 2>&1; then
        BRANCH=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
        if [ ! "${BRANCH}" == "" ]
        then
            STAT=$(parse_git_dirty)
            echo " (${BRANCH}${STAT})"
        else
            echo ""
        fi
    fi
}

# Get current status of Git repository
parse_git_dirty() {
    if command -v git > /dev/null 2>&1; then
        status=$(git status 2>&1 | tee)
        dirty=$(echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?")
        untracked=$(echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?")
        ahead=$(echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?")
        newfile=$(echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?")
        renamed=$(echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?")
        deleted=$(echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?")
        bits=''
        if [ "${renamed}" == "0" ]; then
            bits=">${bits}"
        fi
        if [ "${ahead}" == "0" ]; then
            bits="*${bits}"
        fi
        if [ "${newfile}" == "0" ]; then
            bits="+${bits}"
        fi
        if [ "${untracked}" == "0" ]; then
            bits="?${bits}"
        fi
        if [ "${deleted}" == "0" ]; then
            bits="x${bits}"
        fi
        if [ "${dirty}" == "0" ]; then
            bits="!${bits}"
        fi
        if [ ! "${bits}" == "" ]; then
            echo " ${bits}"
        else
            echo ""
        fi
    fi
}

# Beautiful command prompt.
export PS1='[${debian_chroot:+($debian_chroot)}\u@\h:\w$(parse_git_branch)]\$ '

# Set dircolors
if [[ $(uname) == 'Darwin' ]]; then
    export LSCOLORS=ExFxBxDxCxegedabagacad
elif [[ -f /usr/bin/dircolors && -f "$HOME"/.dircolors ]]; then
    eval "$(dircolors -b "$HOME"/.dircolors)"
fi

# Cross-platform Sublime Text CLI
st () {
    case $OS in
        *microsoft*)
            # CSI 22/23 don't seem to be supported in Windows Terminal 1.18.3181.0
            # Push current window title to stack
            # echo -ne '\e[22t'
            /mnt/c/Program\ Files/Sublime\ Text/subl.exe "${@:-.}"
            # Revert to previous window title after the ssh command
            #echo -ne '\e[23t'
            # Manually set title
            echo -ne "\033]0;Debian\a"
            ;;
        Linux*)
            /usr/bin/subl "${@:-.}"
            ;;
        *)
            ;;
    esac
}

# Fix 'gpg: signing failed: Inappropriate ioctl for device'
export GPG_TTY=$(tty)

# Start SSH Agent and add keys
if command -v keychain > /dev/null 2>&1; then
    if [ -f "$HOME"/.ssh/agent.env ]; then
        source "$HOME"/.ssh/agent.env > /dev/null
        if ! kill -0 "$SSH_AGENT_PID" > /dev/null 2>&1; then
            echo "Stale agent file found. Spawning new agent… "
            eval "$(ssh-agent | tee "$HOME"/.ssh/agent.env)"
            eval "$(keychain --stop others --quiet --quick --eval\
                    --agents gpg,ssh --inherit any --timeout 31622400\
                    "$HOME/.ssh/id_personal" "$HOME/.ssh/id_kosmonaut" "$HOME/.ssh/id_work"\
                    D0132247B7A2BFC9 98763DC54A0266EF EFCAAF15EC4016D0)"
        fi
    else
        echo "Starting ssh-agent"
        eval "$(ssh-agent | tee "$HOME"/.ssh/agent.env)"
        eval "$(keychain --stop others --quiet --quick --eval --agents gpg,ssh\
            --inherit any --timeout 31622400\
            "$HOME/.ssh/id_personal" "$HOME/.ssh/id_kosmonaut" "$HOME/.ssh/id_work"\
            D0132247B7A2BFC9 98763DC54A0266EF EFCAAF15EC4016D0)"
    fi
fi

# Reset the window title after SSH
ssh() {
    echo -ne '\e[22t'
    /usr/bin/ssh "$@"
    echo -ne '\e[23t'
}

# Generate passwords
pgen() {
    < /dev/urandom tr -dc '[:graph:]' | head -c "${1:-24}"; echo
}

# Go up a specified number of directories (i.e. `up 4`)
up () {
    local d=""
    limit=$1
    for ((i=1 ; i <= limit ; i++))
        do
            d=$d/..
        done
    d=$(echo $d | sed 's/^\///')
    if [ -z "$d" ]; then
        d=..
    fi
    cd "$d" || return
}

# Backup 'target' $1 to 'target.bak' using either cp or mv
bak() {
    local mode="cp"
    local target="${1%/}"

    if [[ "$1" == "-m" ]]; then
        mode="mv"
        shift
        target="${1%/}"
    fi

    if [[ -z "$target" ]]; then
        echo "Usage: bak [-m] <target>"
        return 1
    fi

    "$mode" --verbose "$target" "$target.bak"
}

# Revert previously bak'd 'target'
unbak() {
    local target="${1%/}" # Remove trailing / if present
    if [[ "$target" == *.bak ]]; then
        mv --verbose --interactive "$target" "${target%.bak}"
    else
        echo "No .bak extension, ignoring '$target'"
    fi
}

# Load ENV variables from file
# https://stackoverflow.com/a/66118031
if [[ -f "$HOME/.env" ]]; then
    set -a
    #source <(sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" "$HOME"/.env)
    source <(grep -vE '^\s*#|^\s*$' "$HOME/.env" | sed "s/'/'\\\\''/g")
    set +a
fi
