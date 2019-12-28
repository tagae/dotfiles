dotfiles
========

Yet another [GitHub dotfiles repository].

Dotfiles are managed in a git repository and symlinked from there to your home
directory.

![](https://github.com/tagae/dotfiles/workflows/test/badge.svg)


Installation
------------

Issue

    git clone --branch <your branch> git@github.com:tagae/dotfiles.git ~/.dotfiles

Any directory can be used as destination.

The `bin` directory in the repository contains the `dotfiles` command, which
you can use to perform a number of actions on your dotfiles.


Importing Dotfiles
------------------

To import an existing `~/.file` into the dotfiles repository, do

    dotfiles import ~/.file

This will move the file into the git-managed repository, and replace it by a
symlink to the moved file.


Using dotfiles
--------------

To use a dotfile from the repository, do

    dotfiles use ~/.dotfiles/share/file

This will create a `~/.file` symlink pointing to `~/.dotfiles/share/file`.


Ejecting dotfiles
-----------------

To stop managing a dotfile and turn it back into a plain dotfile living in your
home directory, do

    dotfiles eject ~/.file

This will replace the symbolic link `~/.file` by the actual file itself.

This action is the reverse of `import`, except for the git history, which only
grows.


[GitHub dotfiles repository]: http://dotfiles.github.com/
