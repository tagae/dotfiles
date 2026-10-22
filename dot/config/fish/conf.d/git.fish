# Git abbreviations for fish.
#
# `g` expands to `git`, and also abbreviates subcommands.
#
#   g a      ->  git add
#   g cm     ->  git commit --message

status is-interactive; or return

abbr -a g git

# --- Status ------------------------------------------------------------------
abbr -a --command git s   status
abbr -a --command git ss  status --short --branch

# --- Diff --------------------------------------------------------------------
abbr -a --command git d   diff
abbr -a --command git ds  diff --staged
abbr -a --command git dw  diff --color-words=.
abbr -a --command git dst diff --stat

# --- Log ---------------------------------------------------------------------
abbr -a --command git l   log --oneline --graph --decorate
abbr -a --command git la  log --oneline --graph --decorate --all
abbr -a --command git lc  log --oneline --graph --decorate --left-right --cherry-pick
abbr -a --command git ll  "log --pretty=format:'%C(yellow)%h%Creset %C(green)%ad%Creset %s%C(auto)%d%Creset %C(blue)[%an]%Creset' --graph --date=short"
abbr -a --command git lb  "for-each-ref --sort=-committerdate --format='%(color:cyan)%(authordate:relative)%09%(color:red)%(authorname)%09%(color:white)%(color:bold)%(refname:short)' refs/remotes"
abbr -a --command git lp  log --patch
abbr -a --command git lst log --stat
abbr -a --command git bl  blame

# --- Staging -----------------------------------------------------------------
abbr -a --command git a   add
abbr -a --command git aa  add --all
abbr -a --command git ap  add --patch
abbr -a --command git au  add --update
abbr -a --command git an  add --intent-to-add

# --- Committing --------------------------------------------------------------
abbr -a --command git c     commit
abbr -a --command git cm    --set-cursor "commit --message '%'"
abbr -a --command git cam   --set-cursor "commit --all --message '%'"
abbr -a --command git ca    commit --amend
abbr -a --command git fix   commit --amend --no-edit
abbr -a --command git caa   commit --amend --no-edit --reset-author
abbr -a --command git fup   commit --fixup

# --- Branches ----------------------------------------------------------------
abbr -a --command git b   branch -v
abbr -a --command git ba  branch --all
abbr -a --command git bd  branch --delete
abbr -a --command git bD  branch --delete --force

# --- Switching ---------------------------------------------------------------
abbr -a --command git sw  switch
abbr -a --command git swc switch --create
abbr -a --command git co  checkout
abbr -a --command git cop checkout --patch

# --- Restoring ---------------------------------------------------------------
abbr -a --command git re  restore
abbr -a --command git res restore --staged

# --- Fetching ----------------------------------------------------------------
abbr -a --command git f   fetch
abbr -a --command git fa  fetch --all
abbr -a --command git ft  fetch --tags

# --- Pulling -----------------------------------------------------------------
abbr -a --command git pl  pull --rebase

# --- Pushing -----------------------------------------------------------------
abbr -a --command git p   push
abbr -a --command git pu  --function __git_abbr_push_upstream
abbr -a --command git pf  push --force-with-lease
abbr -a --command git pt  push --tags

# --- Remotes -----------------------------------------------------------------
abbr -a --command git rem   remote --verbose
abbr -a --command git rema  remote add
abbr -a --command git remn  --set-cursor 'remote rename origin %'
abbr -a --command git remng remote rename origin github

# --- Merging -----------------------------------------------------------------
# Linear history: merges are fast-forward only (`mff`); there is no --no-ff.
abbr -a --command git m   merge
abbr -a --command git mff merge --ff-only
abbr -a --command git ma  merge --abort

# --- Rebasing ----------------------------------------------------------------
abbr -a --command git rb  rebase
abbr -a --command git rbi rebase --interactive
abbr -a --command git rbc rebase --continue
abbr -a --command git rba rebase --abort

# --- Cherry-picking ----------------------------------------------------------
abbr -a --command git cp  cherry-pick
abbr -a --command git cpc cherry-pick --continue
abbr -a --command git cpa cherry-pick --abort

# --- Stashing ----------------------------------------------------------------
abbr -a --command git sh  stash
abbr -a --command git shp stash pop
abbr -a --command git shl stash list

# --- Undoing -----------------------------------------------------------------
abbr -a --command git rv  revert
abbr -a --command git rs1 reset --soft HEAD~1

# --- Worktrees ---------------------------------------------------------------
abbr -a --command git wt   worktree
abbr -a --command git wtl  worktree list
abbr -a --command git wta  --set-cursor 'worktree add ../%'
abbr -a --command git wtb  --set-cursor 'worktree add -b % ../'
abbr -a --command git wtr  worktree remove
abbr -a --command git wtR  worktree remove --force
abbr -a --command git wtm  worktree move
abbr -a --command git wtp  worktree prune

# --- Inspection --------------------------------------------------------------
abbr -a --command git rl   reflog
abbr -a --command git gr   grep --line-number
abbr -a --command git slog shortlog --summary --numbered
abbr -a --command git top  rev-parse --show-toplevel
abbr -a --command git up   "rev-parse --abbrev-ref '@{upstream}'"

# --- Tags --------------------------------------------------------------------
abbr -a --command git t   tag
abbr -a --command git tc  tag --contains
abbr -a --command git tl  tag --list --sort=-creatordate

# --- Cleaning ----------------------------------------------------------------
abbr -a --command git cld  clean -dn
abbr -a --command git clD  clean -df
abbr -a --command git clx clean -dxn --exclude .idea/ --exclude .env.local --exclude .envrc --exclude .env
abbr -a --command git clX clean -dxf --exclude .idea/ --exclude .env.local --exclude .envrc --exclude .env

# --- Dynamic: branch and remote names ----------------------------------------
# `g push origin @`  -> current branch
# `g switch @@`      -> default branch (<remote>/HEAD, falls back to main)
# `g pu`             -> push --set-upstream <remote> HEAD
#
# <remote> is `remote.pushDefault` if set, else `origin` or `github` (in that
# order) if present, else the first remote.
function __git_abbr_branch
    git branch --show-current
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
    if test -n "$ref"
        string replace $remote/ '' -- $ref
    else
        echo main
    end
end

function __git_abbr_push_upstream
    echo push --set-upstream (__git_abbr_remote) HEAD
end

abbr -a --command git @  --function __git_abbr_branch
abbr -a --command git @@ --function __git_abbr_default_branch

# --- Outside git: jump to repo root ------------------------------------------
abbr -a gcd 'cd (git rev-parse --show-toplevel)'
