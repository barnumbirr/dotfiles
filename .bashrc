# "$HOME"/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
        *) return;;
esac

# Disable ctrl-s and ctrl-q.
stty -ixon

# Infinite history.
HISTSIZE=
HISTFILESIZE=

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Allows you to cd into directory merely by typing the directory name.
shopt -s autocd

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# Disable the bell
if [[ $iatest > 0 ]]; then bind "set bell-style visible"; fi

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Make sure 256 color terminals are enabled
case $TERM in "") TERM=xterm-256color;; esac

# Set Micro editor true color support
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

# enable programmable completion features (you don't need to enable
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
case $OS in
    Linux)
        git config --global include.path "$HOME"/.config/git/linux.gitconfig
        ;;
    *microsoft*)
        git config --global include.path "$HOME"/.config/git/wsl.gitconfig
        ;;
    *)
        ;;
esac

# Get current branch in Git repository
parse_git_branch() {
    BRANCH=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
    if [ ! "${BRANCH}" == "" ]
    then
        STAT=$(parse_git_dirty)
        echo " (${BRANCH}${STAT})"
    else
        echo ""
    fi
}

# Get current status of Git repository
parse_git_dirty() {
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
    OS=$(uname -a)
    case $OS in
        Linux)
            /usr/bin/subl "$@"
            ;;
        *microsoft*)
            # CSI 22/23 don't seem to be supported in Windows Terminal 1.18.3181.0
            # Push current window title to stack
            # echo -ne '\e[22t'
            /mnt/c/Program\ Files/Sublime\ Text/subl.exe "$@"
            # Revert to previous window title after the ssh command
            #echo -ne '\e[23t'
            # Manually set title
            echo -ne "\033]0;Debian\a"
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
                    "$HOME/.ssh/id_martinsimon" "$HOME/.ssh/id_kosmonaut" "$HOME/.ssh/id_doctena"\
                    632C2AA6CF21205A 98763DC54A0266EF EFCAAF15EC4016D0)"
        fi
    else
        echo "Starting ssh-agent"
        eval "$(ssh-agent | tee "$HOME"/.ssh/agent.env)"
        eval "$(keychain --stop others  --quiet --quick --eval --agents gpg,ssh\
            --inherit any --timeout 31622400\
            "$HOME/.ssh/id_martinsimon" "$HOME/.ssh/id_kosmonaut" "$HOME/.ssh/id_doctena"\
            632C2AA6CF21205A 98763DC54A0266EF EFCAAF15EC4016D0)"
    fi
fi

# Reset the window title after SSH
ssh() {
    echo -ne '\e[22t'
    /usr/bin/ssh "$@"
    echo -ne '\e[23t'
}

# WSL specific
if [[ "$(< /proc/sys/kernel/osrelease)" == *microsoft* ]]; then
    export LIBGL_ALWAYS_INDIRECT=1
    export WSL_VERSION=$(wsl.exe -l -v | grep -a '[*]' | sed 's/[^0-9]*//g')
    export WSL_HOST=$(tail -1 /etc/resolv.conf | cut -d' ' -f2)
    export DISPLAY=$WSL_HOST:0
fi

# Load ENV variables from file
# https://stackoverflow.com/a/66118031
set -a
source <(cat "$HOME"/.env | sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g")
set +a
