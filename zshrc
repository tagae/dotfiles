# ~/.zshrc: zsh(1) configuration

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Load auxiliary functions
[ -r ~/.sh.d/ancillary ] && source ~/.sh.d/ancillary

# Load specific initialisations
load ~/.sh.d/interactive
load ~/.zsh.d/interactive

true # finish with success
