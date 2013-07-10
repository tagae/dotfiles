OS=$(uname)

### Extensions

autoload -U add-zsh-hook

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

## VCS
## (http://zsh.sourceforge.net/Doc/Release/User-Contributions.html)

autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git svn hg darcs cvs

zstyle ':vcs_info:*' formats \
    " $fg[blue](%f%s$fg[blue])$fg[white]-%b%u%c%f"

zstyle ':vcs_info:*' actionformats \
    " %f%s:-%b|%a%f"

#zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat \
#    "%b:%r"

add-zsh-hook precmd vcs_info

### Look & feel

# Prompt

setopt PROMPT_SUBST

# See SOLARIZED_THEME to either 'light' or 'dark' (default).

declare -A solarizedBG
solarizedBG=(light white dark black) # zsh syntax differs from bash
bkg=$solarizedBG[${SOLARIZED_THEME:-dark}]

ZSH_THEME_HOST="%n%{%B%F{blue}%}@%{%B%F{cyan}%}%m%{%B%F{green}%} "
ZSH_THEME_VCS="\${vcs_info_msg_0_}"
ZSH_THEME_JOBS="%j "
ZSH_THEME_ERRNO="%(?..%B%F{white}%K{red}[⚡ %?]%f%k%b )"
ZSH_THEME_DIR="%{%b%F{yellow}%K{${bkg}}%}%~%{%B%F{green}%}"
ZSH_THEME_INFO_START="%{%K{${bkg}}%B%F{green}%}"
ZSH_THEME_INFO_END="%E%{%f%k%b%}"

ZSH_THEME_PROMPT_START="%{%K{${bkg}}%}"
ZSH_THEME_PROMPT_PREFIX="%{%K{${bkg}}%}"
ZSH_THEME_PROMPT="%(!.# .➜ )"
ZSH_THEME_PROMPT_END="%{%f%k%b%}"

PROMPT="%{%f%k%b%}
$ZSH_THEME_INFO_START$ZSH_THEME_HOST$ZSH_THEME_JOBS$ZSH_THEME_ERRNO$ZSH_THEME_DIR$ZSH_THEME_VCS$ZSH_THEME_INFO_END
$ZSH_THEME_PROMPT_START$ZSH_THEME_PROMPT_PREFIX$ZSH_THEME_PROMPT$ZSH_THEME_PROMPT_END"

RPROMPT="!%{%B%F{cyan}%}%!%{%f%k%b%}"

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
