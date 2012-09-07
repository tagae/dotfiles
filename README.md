Installation
============

Download the files with

    git clone git@github.com:tagae/dotfiles.git ~/.dotfiles

and install them as symlinks in your home directory with

    ~/.dotfiles/bin/dotfiles-update

You can run the previous command whenever needed.

To update dotfiles automatically after each `git pull` or `git commit`
do

    cd ~/.dotfiles/.git/hooks
    ln -si ../../bin/dotfiles-update post-merge
    ln -si ../../bin/dotfiles-update post-commit

With this you no longer need to manually invoke `dotfiles-update`,
since normally all changes (e.g. renaming of files) should be carried
out through `git` commands, which are ultimately committed.

Use
===

Importing Dotfiles
------------------

To import an existing `.file` into the dotfiles repository do

    ~/.dotfiles/bin/dotfiles-import ~/.file

This will add the file to the git repository, and place the
corresponding symlink in your home directory.

You can safely import dotfiles even if your `~/.dotfile` repository
has uncommitted changes, since the command `dotfiles-import` stashes
away those changes before doing its job, and restores the changes once
finished.


Platfrom-Specific Dotfiles
--------------------------

The names of dotfiles can be complemented with a platform name between
parenthesis, as in

    ~/.dotfiles/AppleVolumes (Linux)

This will let the dotfile framework know that this particular dotfile
is meant for Linux only, and should not be symlinked in other
platforms. The platform name is determined through `uname`.

When importing a platform-specific dotfile with `dotfiles-import`, you
can pass the `-p` option to add the current platform name as indicated
previously. For example, the previous dotfile could have been created
by executing the following command in a Linux platform:

    ~/.dotfiles/bin/dotfiles-import -p ~/.AppleVolumes

If you forget to pass the `-p` option when importing a
platform-specific dotfile, you can still fix the commit by renaming
the file through `git mv` and then doing a `git commit --amend -C
HEAD`.

Custom Updates
--------------

You can place custom updates as `.sh` bash scripts in the
`~/.dotfiles/bin/dotfiles-update.d` directory. These will be run as
the last steps performed by `dotfiles-update`.

The scripts are source directly by `dotfiles-update`, which means you
can reuse the environment already setup by that script. This is the
main reason for sourcing the scripts rather than executing them as
independent programs.

Note that custom scripts cannot interact with (e.g. expect input from)
the user, since they are executed as git hooks.
