#---[ S E T U P ]---

set -g fish_greeting ''

#---[ P A T H S ]---

fish_add_path $HOME/.local/bin
fish_add_path --path $HOME/.docker/bin

#---[ T O O L S ]---

if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv | source

    fish_add_path --path --move (brew --prefix git)/bin
    fish_add_path --path --move (brew --prefix coreutils)/libexec/gnubin
    fish_add_path --path --move (brew --prefix gnu-sed)/libexec/gnubin
    fish_add_path --path --move (brew --prefix make)/libexec/gnubin
    fish_add_path --path --move (brew --prefix m4)/bin
    fish_add_path --path --move (brew --prefix bison)/bin
    fish_add_path --path --move (brew --prefix gpatch)/bin
    fish_add_path --path --move (brew --prefix gawk)/libexec/gnubin

    test -d (brew --prefix bison)/lib
    and set -gx LDFLAGS -L(brew --prefix bison)/lib

    test -d (brew --prefix go)/libexec
    and set -x GOROOT (brew --prefix go)/libexec
end

fish_add_path $HOME/.dotfiles/bin
fish_add_path ~/.krew/bin
fish_add_path ~/.roswell/bin

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

#---[ A L I A S E S ]---

command -sq git
and alias g git

command -sq kubectl
and alias k kubectl

command -sq k9s
and alias k9s 'k9s --logoless'

#---[ P R I V A C Y ]---

command -sq gpgconf
and begin
    test -S (gpgconf --list-dirs agent-socket)
    or gpgconf --launch gpg-agent
end

command -sq keychain
and if string match -q (ps -p 1 -o comm=) systemd
    keychain --quiet --quick --inherit any --systemd
else
    keychain --quiet --quick --inherit any --eval | source
end

#---[ L O C A L ]---

test -f ~/.config/fish/secrets.fish
and source ~/.config/fish/secrets.fish
