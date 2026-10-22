# Kubernetes.

fish_add_path ~/.krew/bin

if command -sq kubectl
    abbr k kubectl
end

if command -sq kubecolor
    alias kubectl kubecolor
end

status is-interactive; or return

command -sq k9s
and set -x K9S_SKIN snazzy
