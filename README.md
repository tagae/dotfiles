Yet another [GitHub dotfiles repository](http://dotfiles.github.com/).

Installation
============

Download the files with

    git clone git@github.com:tagae/dotfiles.git ~/.dotfiles

and install them as symlinks in your home directory with

    ~/.dotfiles/bin/dotfiles-update

You can run the previous command whenever needed.

The `dotfiles-update` command will install itself as `post-merge` and
`post-commit` hook of the repository. This way, all pulled or
committed changes will be followed by a corresponding
`dotfiles-update`, and you will not need to manually execute the
command again.


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
command line, not only the first one.

If you forget to use the `-p` option when importing a
platform-specific dotfile, you can still fix the commit by renaming
the file through `git mv` and doing a `git commit --amend -C HEAD`.

Custom Updates
--------------

You can place custom update scripts in the
`~/.dotfiles/bin/dotfiles-update.d` directory. These will be run as
the last steps performed by `dotfiles-update`.

Note that custom scripts should not interact with (e.g. expect input
from) the user, since they are usually executed as git hooks.

If you want an environment similar to the one `dotfiles-update` uses,
include the following line at the beginning of your script:

    source ~/.dotfiles/bin/lib/dotfiles.sh
