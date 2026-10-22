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

    test -f ~/.dotfiles/dot/a-dotfile

Thus the imported dotfile is moved to the dotfiles repository

    test "$(< ~/.dotfiles/dot/a-dotfile)" = 'some content'

Thus the content of the imported dotfile is preserved

    test "$(git -C ~/.dotfiles show HEAD:dot/a-dotfile)" = 'some content'

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

    test -f ~/.dotfiles/dot/directory/file

Thus the dotfile is imported preserving the directory hierarchy


Feature - handling of invalid imports
#####################################

Given that symlink ~/.a-dotfile exists # imported dotfile from previous spec

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

Given a file ~/a-target
Given a symlink ~/.a-symlink pointing to ~/a-target

    ! dotfiles import ~/.a-symlink

Thus importing a symlink fails

###

Given a file ~/.dotfiles/dot/a-managed-dotfile
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


Feature - using a dotfile
#########################

Given file ~/.dotfiles/dot/a-dotfile

    rm ~/.a-dotfile # make sure the dotfile is not used

    dotfiles use ~/.dotfiles/dot/a-dotfile

Thus using a dotfile succeeds
And the symlink ~/.a-dotfile points to ~/.dotfiles/dot/a-dotfile

    dotfiles use ~/.dotfiles/dot/a-dotfile

Thus using an already used dotfile succeeds
And the symlink ~/.a-dotfile points to ~/.dotfiles/dot/a-dotfile


Feature - using a dotfile in a directory
########################################

Given a file ~/.dotfiles/dot/a-directory/a-dotfile

    dotfiles use ~/.dotfiles/dot/a-directory/a-dotfile

Thus using a dotfile in a directory succeeds
And the symlink ~/.a-directory/a-dotfile points to ~/.dotfiles/dot/a-directory/a-dotfile


Feature - using a dot-directory
###############################

Given a file ~/.dotfiles/dot/a-directory/a-dotfile
Given a file ~/.dotfiles/dot/a-directory/another-dotfile

    rm -rf ~/.a-directory # make sure the dot-directory is not used

    dotfiles use ~/.dotfiles/dot/a-directory

Thus using a directory succeeds
And the symlink ~/.a-directory points to ~/.dotfiles/dot/a-directory


Feature - forcing the use of a dotfile
######################################

Given a file ~/.dotfiles/dot/an-unforced-dotfile
Given a file ~/elsewhere
Given a symlink ~/.an-unforced-dotfile pointing to ~/elsewhere

    ! dotfiles use ~/.dotfiles/dot/an-unforced-dotfile

Thus using a dotfile whose destination links elsewhere fails without force

    test "$(realpath ~/.an-unforced-dotfile)" = "$(realpath ~/elsewhere)"

Thus the existing symlink is left untouched

###

Given a file ~/.dotfiles/dot/a-forced-dotfile
Given a file ~/elsewhere
Given a symlink ~/.a-forced-dotfile pointing to ~/elsewhere

    dotfiles use -f ~/.dotfiles/dot/a-forced-dotfile

Thus forcing the use of a dotfile whose destination links elsewhere succeeds

    test "$(realpath ~/.a-forced-dotfile)" = "$(realpath ~/.dotfiles/dot/a-forced-dotfile)"

Thus the symlink points to the managed dotfile

    test -f ~/elsewhere

Thus the previous target of the symlink is left untouched

###

Given a file ~/.dotfiles/dot/a-plain-dotfile
Given a file ~/.a-plain-dotfile with content 'precious'

    ! dotfiles use -f ~/.dotfiles/dot/a-plain-dotfile

Thus forcing the use of a dotfile whose destination is a plain file fails

    ! test -L ~/.a-plain-dotfile && test "$(< ~/.a-plain-dotfile)" = 'precious'

Thus the plain file is left untouched


Feature - handling of invalid uses
##################################

Given that file ~/.dotfiles/dot/non-existent does not exist

    ! dotfiles use ~/.dotfiles/dot/non-existent

Thus using a non-existent file fails

###

Given a file ~/file

    ! dotfiles use ~/file

Thus using an unmanaged file fails


Feature - ejection of a dotfile '(inverse of importing)'
########################################################

Given a file ~/.dotfiles/dot/a-dotfile with content 'some content'
Given a symlink ~/.a-dotfile pointing to ~/.dotfiles/dot/a-dotfile

    dotfiles eject ~/.a-dotfile

Thus ejection of a used dotfile succeeds

    test -f ~/.a-dotfile && ! test -L ~/.a-dotfile

Thus the symlink is replaced by the ejected dotfile

    ! test -e ~/.dotfiles/dot/a-dotfile

Thus the managed copy of the dotfile is removed

    test "$(< ~/.a-dotfile)" = 'some content'

Thus the content of the ejected dotfile is preserved

    ! git -C ~/.dotfiles ls-files --error-unmatch dot/a-dotfile 1>/dev/null 2>/dev/null

Thus the dotfile is no longer tracked by version control

    git -C ~/.dotfiles log --format=%B -n 1 | grep -q '.*eject.*a-dotfile.*'

Thus the last commit message mentions the ejection of the dotfile


Feature - ejection of a file in a dot-directory
###############################################

Given a file ~/.dotfiles/dot/directory/file
Given a symlink ~/.directory/file pointing to ~/.dotfiles/dot/directory/file
Given that ~/.dotfiles/dot/directory contains 1 file

    dotfiles eject ~/.directory/file

Thus ejecting a file that resides in a dot-directory succeeds

    test -f ~/.directory/file && ! test -L ~/.directory/file

Thus the symlink is replaced by the ejected dotfile

    ! test -e ~/.dotfiles/dot/directory/file

Thus the managed copy of the dotfile is removed

    ! test -e ~/.dotfiles/dot/directory

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
