#---[ S E T U P ]---

set -g fish_greeting ''


#---[ P A T H S ]---

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

test -d $HOME/.dotfiles/bin
and set PATH $HOME/.dotfiles/bin $PATH

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
and pyenv init --path | source

command -sq go
and set -x GOPATH $HOME/Applications/opt/go
and set PATH $PATH $GOPATH/bin

test -d ~/.krew/bin
and set PATH ~/.krew/bin $PATH

test -d ~/.roswell/bin
and set PATH ~/.roswell/bin $PATH

test -d /usr/local/opt/curl/bin
and set PATH /usr/local/opt/curl/bin $PATH

# fish_add_path /usr/local/opt/openjdk/bin


#---[ A L I A S E S ]---

command -sq git
and alias g git

command -sq kubectl
and alias k kubectl


#---[ P R I V A C Y ]---

command -sq gpgconf
and set -xg SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
and gpgconf --launch gpg-agent

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

#set -x GPG_TTY (tty)


#---[ L O C A L ]---

test -f ~/.config/fish/secrets.fish
and source ~/.config/fish/secrets.fish
