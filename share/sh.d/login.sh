### Login script common to bash and zsh

# PATHs
# prependpath PATH /usr/local/bin
# prependpath PATH /sbin
# prependpath PATH /usr/sbin
# prependpath PATH /usr/ucb
# prependpath PATH /opt/local/bin /opt/local/sbin
# prependpath PATH /Users/tagae/Applications/opt/npm/bin
# prependpath PYTHONPATH $HOME/Applications/lib/python2.6/site-packages

## Resource control

# Maximum stack size.
# ulimit -s 64000

# Maximum amount of virtual memory available to the shell.
# ulimit -v $((1024*1024))

# Enable core dumps in case something goes wrong.
ulimit -c unlimited

### User-specific configuration

## Gnome keyring
## 2015-04-28 [tagae]: Disabled (ssh-agent and gpg-agent preferred)
# eval $(/usr/bin/gnome-keyring-daemon)
# export SSH_AUTH_SOCK
# export GPG_AGENT_INFO
