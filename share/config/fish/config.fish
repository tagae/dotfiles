#---[ S E T U P ]---

set -g fish_greeting ''


#---[ P A T H S ]---

test -d $HOME/.local/bin
and set PATH $HOME/.local/bin $PATH

test -d /usr/local/bin
and set PATH /usr/local/bin $PATH

test -d /usr/local/sbin
and set PATH /usr/local/sbin $PATH

test -d /opt/local/bin
and set PATH /opt/local/bin $PATH

test -d /opt/local/sbin
and set PATH /opt/local/sbin $PATH

test -d $HOME/.docker/bin
and set PATH $HOME/.docker/bin $PATH

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


#---[ A L I A S E S ]---

command -sq git
and alias g git

command -sq kubectl
and alias k kubectl


#---[ P R I V A C Y ]---

command -sq gpgconf
and test -S (gpgconf --list-dirs agent-socket)
or gpgconf --launch gpg-agent

test -n "$SSH_AUTH_SOCK"
or begin
    command -sq keychain
    and keychain --eval --quiet --quick | source
end

#---[ L O C A L ]---

test -f ~/.config/fish/secrets.fish
and source ~/.config/fish/secrets.fish
