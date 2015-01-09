Setup
=====

It might be convenient to start Emacs once in `--daemon` mode, and then always
use `emacsclient` (possibly through a shell alias) to invoke the editor as
needed.


Directories
===========

* `after-init`: package setup code, executed as an `after-init-hook`
* `after-load`: package setup code, executed through `eval-after-load`
* `hooks`: code executed by package-provided hooks
* `site-lisp`: custom libraries
* `state`: where all package-produced files should go
* `system-hacks`: alterations of main Emacs functionality



Conventions
===========

File organization
-----------------

Packages which save state information should be configured to store
their files under `package-state-dir` (by default, `~/.emacs.d/state`).

Inside the state directory, the name of the file should be that of the package
which owns the file, optionally followed by an informative suffix.


Coding conventions
------------------

The best way to avoid accidentally overriding another function with the same
name, is to use a moniker or prefix. For example, `sg/` (file system like) or
`sg:` (Common Lisp like).

See https://github.com/bbatsov/emacs-lisp-style-guide


TODO
====

* Would organisation benefit from using `cask`?
* Check `dash` and `s` package to implement the diverse .el files.
  Both seem nice.


Inspiration
===========

Among too many to list exhaustively,

- https://github.com/bbatsov/prelude
- https://github.com/martintrojer/dotfiles/blob/master/.emacs.d/full-init.el
- https://github.com/technomancy/emacs-starter-kit
- https://github.com/magnars/.emacs.d
- https://github.com/n3mo/.emacs.d
- https://github.com/duncanmak/emacs.d/blob/master/init.el
