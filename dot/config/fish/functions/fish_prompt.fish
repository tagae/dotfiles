set fish_color_host yellow

set -g __fish_git_prompt_showdirtystate yes
set -g __fish_git_prompt_showstashstate yes
set -g __fish_git_prompt_showuntrackedfiles yes
set -g __fish_git_prompt_showupstream yes
set -g __fish_git_prompt_show_informative_status 1
set -g __fish_git_prompt_color_branch cyan
set -g __fish_git_prompt_color_dirtystate yellow
set -g __fish_git_prompt_color_stagedstate cyan
set -g __fish_git_prompt_color_invalidstate red
set -g __fish_git_prompt_color_untrackedfiles brown
set -g __fish_git_prompt_color_cleanstate green
set -g __fish_git_prompt_showupstream informative
set -g __fish_git_prompt_char_upstream_ahead ↑
set -g __fish_git_prompt_char_upstream_behind ↓
set -g __fish_git_prompt_char_upstream_prefix ''
set -g __fish_git_prompt_char_stashstate ↩
set -g __fish_git_prompt_char_stagedstate →
set -g __fish_git_prompt_char_dirtystate ⚡
set -g __fish_git_prompt_char_untrackedfiles …
set -g __fish_git_prompt_char_stagedstate ●
set -g __fish_git_prompt_char_conflictedstate ✖
set -g __fish_git_prompt_char_cleanstate ✔

function fish_prompt --description 'Write out the prompt'
    # hostname
    set_color $fish_color_host
    echo -n "@$hostname "

    # PWD
    set_color $fish_color_cwd
    echo -n (prompt_pwd)
    set_color normal

    # VCS
    printf '%s ' (__fish_vcs_prompt)

    # Suffix
    echo -n '> '
end
