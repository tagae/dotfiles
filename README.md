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
has uncommitted changes, since `dotfiles-import` stashes away those
changes before doing its job, and restores the changes once finished.


Platfrom-Specific Dotfiles
--------------------------

The names of dotfiles can be complemented with a platform name between
parenthesis, as in

    ~/.dotfiles/lircrc (Linux)

This will let the dotfile framework know that this particular dotfile
is meant for Linux only, and should not be symlinked in other
platforms. The platform name is determined through `uname`.

When importing a platform-specific dotfile with `dotfiles-import`, you
can use the `-p <platform>` option to specify the platform name that
will go within parenthesis. For example, the previous dotfile could
have been created by executing

    ~/.dotfiles/bin/dotfiles-import -p Linux ~/.lircrc

Mind that the `-p` option will apply to _all_ imports specified in the
command line.

If you forget to use the `-p` option when importing a
platform-specific dotfile, you can still fix the commit by renaming
the file through `git mv` and doing a `git commit --amend -C HEAD`.

Custom Updates
--------------

You can place custom update scripts in the
`~/.dotfiles/bin/dotfiles-update.d` directory. These will be run as
the last steps performed by `dotfiles-update`.

Note that custom scripts should not interact with (e.g. expect input
from) the user, since they can be executed as git hooks.

If you want to have an environment similar to that `dotfiles-update`
uses, include the following line at the beginning of your script:

    source ~/.dotfiles/bin/lib/dotfiles.sh
