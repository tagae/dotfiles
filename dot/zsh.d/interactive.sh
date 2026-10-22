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

# Avoid probing for VCS info in automount points.
zstyle ':vcs_info:*' disable-patterns '/mnt/[^/]+(|/)'

add-zsh-hook precmd vcs_info

### Look & feel

# Prompt

#autoload -U promptinit
#promptinit
setopt PROMPT_SUBST

# See SOLARIZED_THEME to either 'light' or 'dark' (default).

declare -A solarizedBG
solarizedBG=(light white dark black) # key-values (e.g. light->white)
bkg=$solarizedBG[${SOLARIZED_THEME:-dark}]

ZSH_THEME_INFO_START='%{%B%F{green}%}'
ZSH_THEME_INFO_END='%E%{%f%k%b%}'
ZSH_THEME_INFO_DIR='%{%b%F{yellow}%}%~%{%B%F{green}%}'
ZSH_THEME_INFO_ERRNO='%(?..%B%F{white}%K{red}[⚡ %?]%f%k%b )'
ZSH_THEME_INFO_HOST='%n%{%B%F{blue}%}@%{%B%F{cyan}%}%m%{%B%F{green}%} '
ZSH_THEME_INFO_JOBS='%j '
ZSH_THEME_INFO_VCS='${vcs_info_msg_0_}'

for var in ZSH_THEME_INFO_{START,HOST,JOBS,ERRNO,DIR,VCS,END}; do
    ZSH_THEME_INFO+="${(P)var}"
done

ZSH_THEME_PROMPT_START=""
ZSH_THEME_PROMPT_PREFIX=""
ZSH_THEME_PROMPT_CHAR="%(!.# .➜ )"
ZSH_THEME_PROMPT_END="%{%f%k%b%}"

for var in ZSH_THEME_PROMPT_{START,PREFIX,CHAR,END}; do
    ZSH_THEME_PROMPT+="${(P)var}"
done

PROMPT="%{%f%k%b%}$ZSH_THEME_INFO
$ZSH_THEME_PROMPT"

RPROMPT="!%{%B%F{cyan}%}%!%{%f%k%b%}"

# TODO: better way to test for function existence in zsh?
if whence __git_ps1 | grep function > /dev/null; then
    PS1='[%n@%m %c$(__git_ps1 " (%s)")]\$ '
fi

### Behaviour

## Options

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

## Completions

#autoload -U compinit
#compinit
#zstyle ':completion::complete:*' use-cache 1

## History

SAVEHIST=1000
HISTSIZE=1600

## Suffix aliases

alias -s tex="$EDITOR"
alias -s js="node"

### Specific initialisation

load ~/.zsh.d/host/${HOST%%.*}
load ~/.zsh.d/os/$OS
