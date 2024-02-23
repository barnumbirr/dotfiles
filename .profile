# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ]; then
    export XDG_BIN_HOME="$HOME/bin"
    [[ ":$PATH:" != *"$HOME/bin"* ]] && PATH="$HOME/bin:${PATH}"
    /usr/bin/chmod -R +x "$HOME/bin"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then
    export XDG_LOCAL_BIN_HOME="$HOME/.local/bin"
    [[ ":$PATH:" != *"$HOME/.local/bin"* ]] && PATH="$HOME/.local/bin:${PATH}"
    /usr/bin/chmod -R +x "$HOME/.local/bin"
fi

# set PATH so it includes user's private sbin if it exists
if [ -d "$HOME/.local/sbin" ]; then
    export XDG_LOCAL_SBIN_HOME="$HOME/.local/sbin"
    [[ ":$PATH:" != *"$HOME/.local/sbin"* ]] && PATH="$HOME/.local/sbin:${PATH}"
    /usr/bin/chmod -R +x "$HOME/.local/sbin"
fi
