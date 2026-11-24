# shellcheck shell=bash
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
HISTCONTROL=ignorespace:erasedups

# Write history after every command, so a killed terminal keeps it
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

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
bind "set bell-style visible"

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
        printf '\e[?5h';
        sleep 0.2;
        printf '\e[?5l';
        read -r -s -n1 -t1 && break;
    done;
}

# Set default editor
EDITOR=$(command -v micro || command -v nano)
export EDITOR

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
        # shellcheck source=/dev/null
        source /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        # shellcheck source=/dev/null
        source /etc/bash_completion
    elif [[ $(uname) == 'Darwin' ]]; then
        if [ -f "$(brew --prefix)"/etc/bash_completion ]; then
            # shellcheck source=/dev/null
            source "$(brew --prefix)"/etc/bash_completion
        fi
    fi
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# "$HOME"/.aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f "$HOME"/.aliases ]; then
    # shellcheck source=/dev/null
    source "$HOME"/.aliases
fi

# Bash completion for `dots` alias
if declare -F _completion_loader > /dev/null; then
    _completion_loader git
    complete -o bashdefault -o default -o nospace -F __git_wrap__git_main dots
fi

# If running in console 1, start X display server
if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] ; then
    exec startx
fi

OS=$(uname -a)

# Keep `git config --global` writes out of the tracked ~/.config/git/config
[ -e "$HOME/.gitconfig" ] || printf '# Machine-local git settings, untracked. Shared settings: ~/.config/git/config (dotfiles).\n' > "$HOME/.gitconfig"

# Check for git once at startup
_has_git=$(command -v git > /dev/null 2>&1 && echo 1)

# Current git branch and its state, from one `git status`
parse_git_branch() {
    [[ -z "$_has_git" ]] && return
    local status line branch bits='' has_renamed=0 has_new=0 has_untracked=0 has_deleted=0 has_modified=0
    status=$(git status --branch --porcelain 2>/dev/null) || return
    while IFS= read -r line; do
        case "${line:0:2}" in
            \#\#) branch=${line#\#\# }; branch=${branch#No commits yet on }; branch=${branch%%...*}
                [[ "$line" == *"[ahead"* ]] && bits="*" ;;
            R?)          has_renamed=1 ;;
            A?|?A)       has_new=1 ;;
            \?\?)        has_untracked=1 ;;
            D?|?D)       has_deleted=1 ;;
            M?|?M)       has_modified=1 ;;
        esac
    done <<< "$status"
    ((has_renamed))  && bits=">${bits}"
    ((has_new))      && bits="+${bits}"
    ((has_untracked)) && bits="?${bits}"
    ((has_deleted))  && bits="x${bits}"
    ((has_modified)) && bits="!${bits}"
    [[ "$branch" == "HEAD (no branch)" ]] && branch="(HEAD detached at $(git rev-parse --short HEAD))"
    echo " (${branch}${bits:+ $bits})"
}

# Beautiful command prompt.
PS1='[${debian_chroot:+($debian_chroot)}\u@\h:\w$(parse_git_branch)]\$ '

# Set dircolors
if [[ $(uname) == 'Darwin' ]]; then
    export LSCOLORS=ExFxBxDxCxegedabagacad
elif [[ -f /usr/bin/dircolors && -f "$HOME"/.dircolors ]]; then
    eval "$(dircolors -b "$HOME"/.dircolors)"
fi

# Windows Terminal retitles the tab with the .exe a command ran and can't restore it (WT #14575):
# reset it to the distro name, keeping the command's exit status
_wt_title() {
    local rc=$?
    printf '\033]0;%s\a' "$WSL_DISTRO_NAME"
    return $rc
}

# Cross-platform Sublime Text CLI
st () {
    case $OS in
        *microsoft*) /mnt/c/Program\ Files/Sublime\ Text/subl.exe "${@:-.}"; _wt_title ;;
        *) command subl "${@:-.}" ;;
    esac
}

# Cross-platform Zed CLI
zed () {
    command zed "${@:-.}"
    case $OS in *microsoft*) _wt_title ;; esac
}

# Fix 'gpg: signing failed: Inappropriate ioctl for device'
GPG_TTY=$(tty)
export GPG_TTY

# SSH and GPG agents via the vendored keychain 2.8.5. No --stop others: it kills any process naming an agent
if [ -x "$HOME/bin/keychain" ]; then
    # keychain test-signs every GPG key (~1.2 s): run it only when the agent holds no keys
    [ -f "$HOME/.keychain/$HOSTNAME-sh" ] && . "$HOME/.keychain/$HOSTNAME-sh" > /dev/null
    if ! ssh-add -l > /dev/null 2>&1; then
        _agents=ssh
        command -v gpg-agent > /dev/null 2>&1 && _agents=gpg,ssh
        eval "$("$HOME/bin/keychain" --quiet --quick --eval \
                --agents "$_agents" --ignore-missing --timeout 525600 \
                "$HOME/.ssh/id_personal" "$HOME/.ssh/id_kosmonaut" "$HOME/.ssh/id_work" \
                D0132247B7A2BFC9 98763DC54A0266EF EFCAAF15EC4016D0)"
        unset _agents
    fi
fi

# Reset the window title after SSH
ssh() {
    case $OS in
        *microsoft*) command ssh "$@"; _wt_title ;;
        Linux*)
            local rc
            printf '\e[22t'
            command ssh "$@"; rc=$?
            printf '\e[23t'
            return $rc
            ;;
        *) command ssh "$@" ;;
    esac
}

# Latest release of a GitHub repository: gh-release owner/repo
gh-release() {
    gh release view -R "$1" --json tagName,url -q '.tagName + " (" + .url + ")"'
}

# Generate passwords
pgen() {
    < /dev/urandom LC_ALL=C tr -dc '[:graph:]' | head -c "${1:-24}"; echo
}

# Go up a specified number of directories (i.e. `up 4`)
up() { local d; printf -v d '../%.0s' $(seq "${1:-1}"); cd "$d" || return; }

# Backup 'target' $1 to 'target.bak' using either cp or mv
bak() {
    local -a cmd=(cp -a)
    [[ "$1" == "-m" ]] && { cmd=(mv); shift; }
    local target="${1%/}" # Remove trailing / if present

    [[ -n "$target" ]] || { echo "Usage: bak [-m] <target>"; return 1; }
    [[ -e "$target.bak" ]] && { echo "bak: $target.bak already exists"; return 1; }

    "${cmd[@]}" -v "$target" "$target.bak"
}

# Revert previously bak'd 'target'
unbak() {
    local target="${1%/}" # Remove trailing / if present
    local restored="${target%.bak}"

    [[ -n "$target" ]]        || { echo "Usage: unbak <target>.bak"; return 1; }
    [[ "$target" == *.bak ]]  || { echo "No .bak extension, ignoring '$target'"; return 1; }
    [[ ! -e "$restored" ]]    || { echo "'$restored' already exists, refusing to restore '$target'"; return 1; }

    mv -v "$target" "$restored"
}

# Load ENV variables from file, exported
if [[ -f "$HOME/.env" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$HOME/.env"
    set +a
fi

if [ -f "$HOME"/.cargo/env ]; then
    # shellcheck source=/dev/null
    source "$HOME"/.cargo/env
fi
