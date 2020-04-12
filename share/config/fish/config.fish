#---[ S E T U P ]---

set -g fish_greeting ''


#---[ P A T H S ]---

test -d $HOME/.dotfiles/bin
and set PATH $HOME/.dotfiles/bin $PATH

test -d $HOME/Applications/bin
and set PATH $HOME/Applications/bin $PATH

test -d /usr/local/bin
and set PATH /usr/local/bin $PATH

test -d /usr/local/sbin
and set PATH /usr/local/sbin $PATH

test -d /opt/local/bin
and set PATH /opt/local/bin $PATH

test -d /opt/local/sbin
and set PATH /opt/local/sbin $PATH


#---[ T O O L S ]---

command -sq emacs
and set -x EDITOR emacs

command -sq less
and set -x PAGER less

command -sq direnv
and direnv hook fish | source

command -sq rbenv
and rbenv init - | source

command -sq pyenv
and set -x PYENV_ROOT /usr/local/var/pyenv
and pyenv init - | source
and pyenv virtualenv-init - | source

command -sq go
and set -x GOPATH $HOME/Applications/opt/go
and set PATH $PATH $GOPATH/bin


#---[ A L I A S E S ]---

command -sq git
and alias g git

command -sq kubectl
and alias k kubectl

command -sq htop
and alias top htop

command -sq prettyping
and alias ping prettyping

command -sq lsd
and alias ls lsd

# We pass -F to ignore the system-wide configuration (/etc/ssh/ssh_config),
# which typically has the setting
#
#     SendEnv LANG LC_*
#
# This setting is inconvenient because locales are not necessarily supported
# across hosts.
#
command -sq ssh
and test -f ~/.ssh/config
and alias ssh 'ssh -F ~/.ssh/config'

#---[ L O C A L ]---

test -f ~/.config/fish/secrets.fish
and source ~/.config/fish/secrets.fish
