# Git abbreviations for fish.
#
# `g` expands to `git`, and also abbreviates subcommands.
#
#   g a    ->  git add
#   g cm   ->  git commit --message
#
# Every abbreviation starts with the stem of its subcommand. A one-word
# subcommand takes the shortest prefix that no other stem shares. A two-word
# subcommand (check-out, cherry-pick, work-tree, ref-log, short-log,
# rev-parse) takes a letter from each word (`co`, `cp`, `wt`, `rl`, `sl`,
# `rp`). A subcommand used very often may claim a shorter stem than that
# (`c` for commit, `s` for status). Letters after the stem select flags
# (`cm` = commit --message). Adding a subcommand may lengthen an existing
# stem. Stems:
#
#   a     add             l     log        rp    rev-parse
#   bl    blame           m     merge      s     status
#   br    branch          p     push       sh    show
#   c     commit          pl    pull       sl    shortlog
#   cl    clean           r     rebase     sw    switch
#   co    checkout        rem   remote     t     tag
#   cp    cherry-pick     rese  reset      wt    worktree
#   d     diff            res   restore
#   f     fetch           rl    reflog
#   g     grep

status is-interactive; or return

abbr -a g git

# --- Staging -----------------------------------------------------------------
abbr -a --command git a  add
abbr -a --command git aa add --all
abbr -a --command git ap add --patch
abbr -a --command git au add --update
abbr -a --command git an add --intent-to-add

# --- Branches ----------------------------------------------------------------
abbr -a --command git br  branch --verbose
abbr -a --command git brd branch --delete
abbr -a --command git brD branch --delete --force

# --- Committing --------------------------------------------------------------
abbr -a --command git c    commit
abbr -a --command git cm   --set-cursor "commit --message '%'"
abbr -a --command git cma  --set-cursor "commit --message '%' --all"
abbr -a --command git ca   commit --amend
abbr -a --command git can  commit --amend --no-edit
abbr -a --command git cana commit --amend --no-edit --all
abbr -a --command git canr commit --amend --no-edit --reset-author
abbr -a --command git cf   commit --fixup
abbr -a --command git cfa  --set-cursor "commit --fixup % --all"

# --- Cleaning ----------------------------------------------------------------
abbr -a --command git cld clean -d --dry-run --exclude .idea/ --exclude .env.local --exclude .envrc --exclude .env
abbr -a --command git clx clean -d -x --dry-run --exclude .idea/ --exclude .env.local --exclude .envrc --exclude .env
abbr -a --command git clD clean -d --force --exclude .idea/ --exclude .env.local --exclude .envrc --exclude .env
abbr -a --command git clX clean -d -x --force --exclude .idea/ --exclude .env.local --exclude .envrc --exclude .env

# --- Checking out ------------------------------------------------------------
abbr -a --command git co  checkout
abbr -a --command git cop checkout --patch

# --- Cherry-picking ----------------------------------------------------------
abbr -a --command git cp  cherry-pick
abbr -a --command git cpc cherry-pick --continue
abbr -a --command git cpa cherry-pick --abort

# --- Diff --------------------------------------------------------------------
abbr -a --command git d   diff
abbr -a --command git ds  diff --staged
abbr -a --command git dw  diff --color-words=.
abbr -a --command git dst diff --stat

# --- Fetching ----------------------------------------------------------------
abbr -a --command git f  fetch
abbr -a --command git fa fetch --all
abbr -a --command git ft fetch --tags

# --- Searching ---------------------------------------------------------------
abbr -a --command git g grep --line-number

# --- Log ---------------------------------------------------------------------
abbr -a --command git l   log --oneline --graph --decorate
abbr -a --command git la  log --oneline --graph --decorate --all
abbr -a --command git lc  log --oneline --graph --decorate --left-right --cherry-pick
abbr -a --command git ll  "log --pretty=format:'%C(yellow)%h%Creset %C(green)%ad%Creset %s%C(auto)%d%Creset %C(blue)[%an]%Creset' --graph --date=short"
abbr -a --command git lp  log --patch
abbr -a --command git lst log --stat

# --- Pushing -----------------------------------------------------------------
abbr -a --command git p  push
abbr -a --command git pf push --force-with-lease
abbr -a --command git pF push --force
abbr -a --command git pt push --tags

# --- Pulling -----------------------------------------------------------------
abbr -a --command git pl pull

# --- Rebasing ----------------------------------------------------------------
abbr -a --command git r  rebase
abbr -a --command git ri rebase --interactive
abbr -a --command git rc rebase --continue
abbr -a --command git ra rebase --abort

# --- Remotes -----------------------------------------------------------------
abbr -a --command git rem   remote --verbose
abbr -a --command git rema  remote add
abbr -a --command git remn  --set-cursor 'remote rename origin %'
abbr -a --command git remng remote rename origin github

# --- Resetting ---------------------------------------------------------------
abbr -a --command git rt1 reset HEAD~1
abbr -a --command git rts1 reset --soft HEAD~1
abbr -a --command git rtH1 reset --hard HEAD~1

# --- Restoring ---------------------------------------------------------------
abbr -a --command git res  restore
abbr -a --command git ress restore --staged

# --- Reflog ------------------------------------------------------------------
abbr -a --command git rl reflog

# --- Repository paths --------------------------------------------------------
abbr -a --command git rpt rev-parse --show-toplevel
abbr -a --command git rpu "rev-parse --abbrev-ref '@{upstream}'"

# --- Show --------------------------------------------------------------------
abbr -a --command git sh  show
abbr -a --command git shn show --name-only

# --- Shortlog ----------------------------------------------------------------
abbr -a --command git sl shortlog --summary --numbered

# --- Status ------------------------------------------------------------------
abbr -a --command git s  status
abbr -a --command git ss status --short --branch

# --- Switching ---------------------------------------------------------------
abbr -a --command git sw  switch
abbr -a --command git swc switch --create
abbr -a --command git hm  --function __git_abbr_detach_to_remote_default # switch to headless main

# --- Tags --------------------------------------------------------------------
abbr -a --command git t  tag
abbr -a --command git tc tag --contains
abbr -a --command git tl tag --list --sort=-creatordate

# --- Worktrees ---------------------------------------------------------------
abbr -a --command git wt  worktree
abbr -a --command git wtl worktree list
abbr -a --command git wta --set-cursor 'worktree add ../%'
abbr -a --command git wtb --set-cursor 'worktree add -b % ../'
abbr -a --command git wtr worktree remove
abbr -a --command git wtR worktree remove --force
abbr -a --command git wtm worktree move
abbr -a --command git wtp worktree prune

# --- Outside git: jump to repo root ------------------------------------------
abbr -a gcd 'cd (git rev-parse --show-toplevel)'

# --- Helpers -----------------------------------------------------------------

function __git_abbr_detach_to_remote_default
    echo switch --detach (__git_abbr_remote)/(__git_abbr_default_branch)
end

function __git_abbr_remote
    set -l remote (git config remote.pushDefault)
    if test -z "$remote"
        set -l remotes (git remote 2>/dev/null)
        for candidate in origin github
            if contains -- $candidate $remotes
                set remote $candidate
                break
            end
        end
        test -z "$remote"; and set remote $remotes[1]
    end
    echo $remote
end

function __git_abbr_default_branch
    set -l remote (__git_abbr_remote)
    set -l ref (git symbolic-ref --short refs/remotes/$remote/HEAD 2>/dev/null)
    if test -z "$ref"
        # <remote>/HEAD is unset (e.g. a remote added without cloning): ask the
        # remote for its default branch, which also records it for next time.
        git remote set-head $remote --auto >/dev/null 2>&1
        set ref (git symbolic-ref --short refs/remotes/$remote/HEAD 2>/dev/null)
    end
    if test -n "$ref"
        string replace $remote/ '' -- $ref
    else
        echo main
    end
end
