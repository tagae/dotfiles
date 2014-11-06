Prerequisites
-------------

All needed packages can be installed by evaluating `setup.el'.

This configuration is based on package `better-defaults'.  It suffices
to install it through MELPA; there is no need to require it, since it
autoloads everything.

Package state directory
-----------------------

Packages which save state information should be configured to store
their files under `package-state-dir' (normally ~/.emacs.d/state).

The name of the file should be that of the package which owns the file
(unless a package saves more than one file, in which case they can be
distinguished by means of suffixes.


TODO
----

* Check `dash' package to implement the diverse .el files. Seems nice.


Sources of inspiration
----------------------

Among too many to list exhaustively,

https://github.com/martintrojer/dotfiles/blob/master/.emacs.d/full-init.el
https://github.com/technomancy/emacs-starter-kit
https://github.com/magnars/.emacs.d
