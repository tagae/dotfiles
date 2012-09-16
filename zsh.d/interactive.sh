OS=$(uname)

### Extensions

## oh-my-zsh

if [[ -d ~/.oh-my-zsh ]]; then
    export ZSH=$HOME/.oh-my-zsh
    if [[ -r $ZSH/oh-my-zsh.sh ]]; then
        ZSH_THEME="robbyrussell"
        plugins=(
            zsh-syntax-highlighting
            git svn
            ruby
            ant
            node npm)
        if [ $OS = "Darwin" ]; then
            plugins=( "${plugins[@]}" osx brew macports )
        fi
        source $ZSH/oh-my-zsh.sh
    fi
fi

### Look & feel

# Default host color
sh-theme-hostcolor () { echo $bg[black]$fg[white] }

# Prompt
PROMPT="%{\$(sh-theme-hostcolor)%} %n@%B%m %b%f%k %j%(?.. %B%K{red}[⚡ %?]%f%k%b) %~
%(!.# .➜ ) "

### Zsh behaviour

## Options

setopt auto_cd auto_pushd
setopt pushd_ignore_dups
setopt no_hup no_check_jobs
setopt dvorak
setopt append_history
#setopt share_history
unsetopt share_history
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_find_no_dups
setopt hist_verify
setopt hist_reduce_blanks
setopt extended_glob
setopt nobanghist
unsetopt correct_all
#setopt no_multios

## Command line

bindkey -e

## History

SAVEHIST=1000
HISTSIZE=1600

## Suffix aliases
alias -s tex="$EDITOR"
alias -s js="node"

### Specific initialisation

load ~/.zsh.d/host/${HOST%%.*}
load ~/.zsh.d/os/$OS
