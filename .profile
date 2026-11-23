# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# set PATH so it includes user's private bin if it exists
# (no chmod sweep here: git tracks the executable bit for ~/bin)
if [ -d "$HOME/bin" ]; then
    export XDG_BIN_HOME="$HOME/bin"
    case ":$PATH:" in *"$HOME/bin"*) ;; *) PATH="$HOME/bin:${PATH}" ;; esac
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then
    export XDG_LOCAL_BIN_HOME="$HOME/.local/bin"
    case ":$PATH:" in *"$HOME/.local/bin"*) ;; *) PATH="$HOME/.local/bin:${PATH}" ;; esac
    find "$HOME/.local/bin" -type f ! -name '_*' -exec chmod +x {} +
fi

# set PATH so it includes user's private sbin if it exists
if [ -d "$HOME/.local/sbin" ]; then
    export XDG_LOCAL_SBIN_HOME="$HOME/.local/sbin"
    case ":$PATH:" in *"$HOME/.local/sbin"*) ;; *) PATH="$HOME/.local/sbin:${PATH}" ;; esac
    find "$HOME/.local/sbin" -type f ! -name '_*' -exec chmod +x {} +
fi

# if running bash, include .bashrc if it exists (PATH must already be
# final at this point: .bashrc invokes tools from the dirs above)
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc"
    fi
fi
