# SSH agent.
#
# Sorts after 30-gnupg.fish, whose agent may provide the socket.

if test -S ~/.ssh/agent.sock
    # A forwarded agent takes precedence.
    set -q SSH_CONNECTION
    and set -q SSH_AUTH_SOCK
    or set -gx SSH_AUTH_SOCK ~/.ssh/agent.sock
else if command -sq keychain
    keychain --quiet --eval | source
end
