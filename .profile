# shellcheck shell=sh
# ~/.profile: executed by the command interpreter for login shells.

# Installers (uv) put binaries here, not in the tracked ~/bin
export XDG_BIN_HOME="$HOME/.local/bin"

# Private bin directories on PATH; each one listed later comes first
for d in "$HOME/bin" "$HOME/.local/bin" "$HOME/.local/sbin"; do
    [ -d "$d" ] || continue
    case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
done
unset d

# Make the scripts in ~/.local executable (names starting with _ are left alone)
find "$HOME/.local/bin" "$HOME/.local/sbin" -type f ! -name '_*' -exec chmod +x {} + 2>/dev/null

# if running bash, include .bashrc (last, so it sees the final PATH)
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        # shellcheck source=/dev/null
        . "$HOME/.bashrc"
    fi
fi
