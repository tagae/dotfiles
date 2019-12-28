#!/usr/bin/env bash

#
# This file contains the behavioural specification of the `dotfiles` command.
#

source "$(dirname "$0")"/spec.sh


Feature - installation
######################

Given variable REPO containing the path of the dotfiles git repository

    git clone --quiet "$REPO" ~/.dotfiles

Thus the dotfiles repository can be cloned

# The following is neeed for git to succeed in committing changes to the
# dotfiles repository.
#
# TODO: the dotfiles system should streamline the case of not having a proper ~/.gitconfig.

git -C ~/.dotfiles config user.name Test
git -C ~/.dotfiles config user.email test@address

# define the subject under test
dotfiles() {
    env - PATH="$PATH" HOME="$HOME" ~/.dotfiles/bin/dotfiles "$@" > ~/stdout 2> ~/stderr
}


Feature - import of dotfile in home directory
#############################################

Given a file ~/.a-dotfile with content 'some content'

    dotfiles import ~/.a-dotfile

Thus importing a dotfile from the home directory succeeds

    test -L ~/.a-dotfile

Thus the imported dotfile is replaced by a symlink

    test -f ~/.dotfiles/share/a-dotfile

Thus the imported dotfile is moved to the dotfiles repository

    test "$(< ~/.dotfiles/share/a-dotfile)" = 'some content'

Thus the content of the imported dotfile is preserved

    test "$(git -C ~/.dotfiles show HEAD:share/a-dotfile)" = 'some content'

Thus the imported dotfile is checked into version control

    git -C ~/.dotfiles log --format=%B -n 1 | grep -q '.*import.*a-dotfile.*'

Thus the last commit message mentions the importing of the dotfile


Feature - import of a file in a dot-directory
#############################################

Given a file ~/.directory/file

    dotfiles import ~/.directory/file

Thus importing a file that resides in a dot-directory succeeds

    test -L ~/.directory/file && ! test -L ~/.directory

Thus the imported dotfile is replaced by a symlink in the original directory

    test -f ~/.dotfiles/share/directory/file

Thus the dotfile is imported preserving the directory hierarchy


Feature - handling of invalid imports
#####################################

Given an existing symlink ~/.a-dotfile # imported dotfile from previous spec

    ! dotfiles import ~/.a-dotfile

Thus importing an already imported dotfile fails

###

Given that file ~/.non-existent does not exist

    ! dotfiles import ~/.non-existent

Thus importing a non-existent file fails

###

Given a file ~/plain-file

    ! dotfiles import ~/plain-file

Thus importing a non-dotfile fails

###

Given a symlink ~/.a-symlink pointing to ~/a-target

    ! dotfiles import ~/.a-symlink

Thus importing a symlink fails

###

Given a file ~/.dotfiles/share/a-managed-dotfile
Given a file ~/.a-managed-dotfile

    ! dotfiles import ~/.a-managed-dotfile

Thus importing an homonym of a managed dotfile fails

###

Given a file ~/../.out-of-home

    ! dotfiles import ~/../.out-of-home

Thus importing a dotfile that resides outisde of the home directory fails

###

Given a file ~/plain-directory/.file

    ! dotfiles import ~/plain-directory/.file

Thus importing a dotfile that is not a child of a dot-directory fails


Feature - using an imported dotfile
###################################

# use dotfile imported in previous spec
Given an existing file ~/.dotfiles/share/a-dotfile
Given an existing symlink ~/.a-dotfile

    dotfiles use ~/.dotfiles/share/a-dotfile

Thus using an already used dotfile succeeds

    rm ~/.a-dotfile # stop using dotfile

    dotfiles use ~/.dotfiles/share/a-dotfile

Thus using an unused dotfile succeeds


Feature - handling of invalid uses
##################################

Given that file ~/.dotfiles/share/non-existent does not exist

    ! dotfiles use ~/.dotfiles/share/non-existent

Thus using a non-existent file fails

###

Given a file ~/file

    ! dotfiles use ~/file

Thus using an unmanaged file fails


Feature - ejection of a dotfile '(inverse of importing)'
########################################################

# dotfile imported and used from previous specs
Given an existing file ~/.dotfiles/share/a-dotfile
Given an existing symlink ~/.a-dotfile

    dotfiles eject ~/.a-dotfile

Thus ejection of a used dotfile succeeds

    test -f ~/.a-dotfile && ! test -L ~/.a-dotfile

Thus the symlink is replaced by the ejected dotfile

    ! test -e ~/.dotfiles/share/a-dotfile

Thus the managed copy of the dotfile is removed

    test "$(< ~/.a-dotfile)" = 'some content'

Thus the content of the ejected dotfile is preserved

    ! git -C ~/.dotfiles ls-files --error-unmatch share/a-dotfile 1>/dev/null 2>/dev/null

Thus the dotfile is no longer tracked by version control

    git -C ~/.dotfiles log --format=%B -n 1 | grep -q '.*eject.*a-dotfile.*'

Thus the last commit message mentions the ejection of the dotfile


Feature - ejection of a file in a dot-directory
###############################################

# dotfile imported and used from previous specs
Given that the symlink ~/.directory/file points to ~/.dotfiles/share/directory/file
Given that ~/.dotfiles/share/directory contains 1 file

    dotfiles eject ~/.directory/file

Thus ejecting a file that resides in a dot-directory succeeds

    test -f ~/.directory/file && ! test -L ~/.directory/file

Thus the symlink is replaced by the ejected dotfile

    ! test -e ~/.dotfiles/share/directory/file

Thus the managed copy of the dotfile is removed

    ! test -e ~/.dotfiles/share/directory

Thus the empty directory that contained the managed file is removed


Feature - handling of invalid ejections
#######################################

Given that file ~/.non-existent does not exist

    ! dotfiles eject ~/.non-existent

Thus ejecting a non-existent file fails

###

Given a file ~/.file

    ! dotfiles eject ~/.file

Thus ejecting an unmanaged dotfile fails

###

Given a symlink ~/.a-symlink pointing to ~/a-target

    ! dotfiles eject ~/.a-symlink

Thus ejecting a symlink pointing to an unmanaged file fails

End
