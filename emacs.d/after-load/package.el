;; Add MELPA package archive.
(add-to-list 'package-archives
             '("melpa" . "http://melpa.milkbox.net/packages/") t)

;; Change name of ELPA directory.
(setq package-user-dir (expand-file-name "packages" user-emacs-directory))

;; Load package management utilities.
(require 'sg/packages)
