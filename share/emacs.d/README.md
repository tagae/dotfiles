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
