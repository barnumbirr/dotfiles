# dotfiles
###### Inspired by [jaagr/dots](https://github.com/jaagr/dots)

> This simple yet effective technique lets you track the files you care about
> and it doesn't require any tools other than git. The files will be kept at
> their intended location, without the need to create symlinks or copies.
>
> Files are added to the repository by calling `dots add $HOME/.config/file`
> and when issuing `dots status` - only changes to files explicitly added will
> be shown.
>
> To get a list of files not tracked by git, use `dots untracked` or
> `dots untracked-at $HOME/path/to/foo/bar` to only show files in a specific
> subdirectory.
>
> Dead simple!

## Installation

```bash
$ alias dots="git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
$ git init --bare "$HOME"/.dotfiles
$ dots remote add origin git@github.com:barnumbirr/dotfiles.git
$ dots fetch
$ dots reset --hard origin/master
```

## Configuration

```bash
$ dots config status.showUntrackedFiles no

# Useful aliases
$ dots config alias.untracked "status -u ."
$ dots config alias.untracked-at "status -u"
```

## Usage

```bash
# Use the dots alias like you would use the git command
$ dots status
$ dots add --update ...
$ dots commit -m "..."
$ dots push

# Listing files (not tracked by git)
$ dots untracked
$ dots status -u .config/

# Listing files (tracked by git)
$ dots ls-files
$ dots ls-files .config/polybar/
```

## License

```
Copyright (C) 2024 Martin Simon

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```

## Buy me a coffee?

If you feel like buying me a coffee (or a beer?), donations are welcome:

```
BTC : bc1qq04jnuqqavpccfptmddqjkg7cuspy3new4sxq9
DOGE: DRBkryyau5CMxpBzVmrBAjK6dVdMZSBsuS
ETH : 0x2238A11856428b72E80D70Be8666729497059d95
LTC : MQwXsBrArLRHQzwQZAjJPNrxGS1uNDDKX6
```
