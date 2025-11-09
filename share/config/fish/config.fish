#---[ V A R S ]---

set -g fish_greeting ''

# https://specifications.freedesktop.org/basedir-spec/latest/

set -q XDG_CONFIG_HOME    || set -gx XDG_CONFIG_HOME "$HOME/.config"
set -q XDG_CACHE_HOME     || set -gx XDG_CACHE_HOME "$HOME/.cache"
set -q XDG_DATA_HOME      || set -gx XDG_DATA_HOME "$HOME/.local/share"
set -q XDG_STATE_HOME     || set -gx XDG_STATE_HOME "$HOME/.local/state"


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

    test -d (brew --prefix libiconv)/lib
    and set -gx LDFLAGS -L/opt/homebrew/opt/libiconv/lib $LDFLAGS
    and set -gx CPPFLAGS -I/opt/homebrew/opt/libiconv/include $CPPFLAGS

    test -d (brew --prefix go)/libexec
    and set -x GOROOT (brew --prefix go)/libexec

    test -d ~/Library/pnpm
    and set -x PNPM_HOME $HOME/Library/pnpm
    and fish_add_path --path --move $PNPM_HOME
end

fish_add_path /opt/local/bin
fish_add_path $HOME/.dotfiles/bin
fish_add_path ~/.krew/bin
fish_add_path ~/.roswell/bin

command -sq emacs
and set -x EDITOR 'emacs -nw'

command -sq less
and set -x PAGER less

command -sq direnv
and direnv hook fish | source

command -sq rbenv
and rbenv init - | source

fish_add_path $HOME/.pyenv/bin

command -sq pyenv
and set -x PYENV_ROOT $HOME/.pyenv
and pyenv init - | source

command -sq go
and set -x GOPATH $HOME/Applications/opt/go
and set PATH $PATH $GOPATH/bin

#---[ A L I A S E S ]---

command -sq git
and alias g git

command -sq kubectl
and alias k kubectl

command -sq k9s

#---[ A P P E A R A N C E ]---

status is-interactive
and command -sq vivid
and set -x LS_COLORS (vivid --color-mode 8-bit generate one-dark)

#---[ P R I V A C Y ]---

command -sq gpgconf
and begin
    test -S (gpgconf --list-dirs agent-socket)
    or gpgconf --launch gpg-agent
end

command -sq keychain
and keychain --quiet --eval | source

#---[ L O C A L ]---

test -f ~/.config/fish/secrets.fish
and source ~/.config/fish/secrets.fish

# pnpm
set -gx PNPM_HOME "/Users/tagae/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
