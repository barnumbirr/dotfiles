# ~/.bashrc: executed by bash(1) for non-login shells.
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

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

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
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    elif [[ $(uname) == 'Darwin' ]]; then
        if [ -f "$(brew --prefix)"/etc/bash_completion ]; then
            . "$(brew --prefix)"/etc/bash_completion
        fi
    fi
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# If running in console 1, start X display server
if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] ; then
    exec startx
fi

# Get current branch in Git repository
function parse_git_branch() {
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
function parse_git_dirty {
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
elif [[ -f /usr/bin/dircolors && -f ~/.dircolors ]]; then
    eval "$(dircolors -b ~/.dircolors)"
fi

# Cross-platform Sublime Text CLI
st () {
    OS=$(uname -a)
    case $OS in
        Linux)
            OS='Linux'
            command subl "$@"
            ;;
        *microsoft*)
            OS='Windows Subsystem for Linux (WSL)'
            command /mnt/c/Program\ Files/Sublime\ Text/subl.exe "$@"
            echo -ne "\033]0;Debian\a"
            ;;
        WindowsNT)
            OS='Windows'
            command /mnt/c/Program\ Files/Sublime\ Text/subl.exe "$@"
            ;;
        *) ;;
    esac
}

# Fix 'gpg: signing failed: Inappropriate ioctl for device'
export GPG_TTY=$(tty)

# Start SSH Agent and add keys
if command -v keychain > /dev/null 2>&1; then
    if [ -f ~/.ssh/agent.env ]; then
        . ~/.ssh/agent.env > /dev/null
        if ! kill -0 "$SSH_AGENT_PID" > /dev/null 2>&1; then
            echo "Stale agent file found. Spawning new agent… "
            eval "$(ssh-agent | tee ~/.ssh/agent.env)"
            eval "$(keychain --stop others --quiet --quick --eval\
                    --agents gpg,ssh --inherit any --timeout 31622400\
                    ~/.ssh/id_martinsimon ~/.ssh/id_kosmonaut\
                    ~/.ssh/id_teleclinic 632C2AA6CF21205A 98763DC54A0266EF\
                    17B14A453E2EFAC0)"
        fi
    else
        echo "Starting ssh-agent"
        eval "$(ssh-agent | tee ~/.ssh/agent.env)"
        eval "$(keychain --stop others  --quiet --quick --eval --agents gpg,ssh\
            --inherit any --timeout 31622400\
            ~/.ssh/id_martinsimon ~/.ssh/id_kosmonaut ~/.ssh/id_teleclinic\
            632C2AA6CF21205A 98763DC54A0266EF 17B14A453E2EFAC0)"
    fi
fi

# WSL specific
if [[ "$(< /proc/sys/kernel/osrelease)" == *microsoft* ]]; then
    export LIBGL_ALWAYS_INDIRECT=1
    export WSL_VERSION=$(wsl.exe -l -v | grep -a '[*]' | sed 's/[^0-9]*//g')
    export WSL_HOST=$(tail -1 /etc/resolv.conf | cut -d' ' -f2)
    export DISPLAY=$WSL_HOST:0
fi

short() {
    local SHORTENER_URL="https://0xff.tf"
    local SHORTENER_SECRET_KEY=""

    shorten=$(curl --silent --fail -X POST \
              -H "Authorization: ${SHORTENER_SECRET_KEY}"\
              -H "URL: ${VAULT_URL}/${vault_key}" ${SHORTENER_URL}) || {
        echo "ERROR: failed to shorten" >&2
        exit 1
    }

    short_url=$(jq -r .short <<< $shorten)

    echo "${short_url}"
}

vault() {
    local VAULT_URL="https://vault.tf"
    local VAULT_SECRET_KEY=""
    local SHORTENER_URL="https://0xff.tf"
    local SHORTENER_SECRET_KEY=""

    upload=$(curl --silent --fail --data-binary @${1:--}\
         -H "Authorization: ${VAULT_SECRET_KEY}" ${VAULT_URL}/documents) || {
        echo "ERROR: failed to paste" >&2
        exit 1
    }

    vault_key=$(jq -r .key <<< $upload)

    shorten=$(curl --silent --fail -X POST \
              -H "Authorization: ${SHORTENER_SECRET_KEY}"\
              -H "URL: ${VAULT_URL}/${vault_key}" ${SHORTENER_URL}) || {
        echo "ERROR: failed to shorten" >&2
        exit 1
    }

    short_url=$(jq -r .short <<< $shorten)

    echo "${short_url}"
}
