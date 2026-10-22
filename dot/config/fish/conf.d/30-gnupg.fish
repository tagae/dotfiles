# GnuPG: start the agent unless it is already listening.
#
# Sorts after 20-homebrew.fish, which provides `gpgconf`, and before 40-ssh.fish, which may rely on
# the agent's socket.

command -sq gpgconf
and begin
    test -S (gpgconf --list-dirs agent-socket)
    or gpgconf --launch gpg-agent
end
