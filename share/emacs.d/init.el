;; ===[ S Y S T E M ]===

;; == elisp

(setq gc-cons-threshold (* 50 1024 1024))
(setq load-prefer-newer t)

;; == state

(defconst emacs-state-dir (expand-file-name "state/" user-emacs-directory)
  "Stores state information generated by Emacs operation.")

(make-directory emacs-state-dir t)

;; == tmp files

(defconst emacs-tmp-dir
  (format "%s%s/%s/" temporary-file-directory "emacs" (user-login-name))
  "Stores temporary files.")

(make-directory emacs-tmp-dir t)

;; == site lisp

(add-to-list 'load-path (expand-file-name "site-lisp" user-emacs-directory))

;; ===[ H O O K S ]===

(require 'sg/elisp-files)

;; Install hooks found in the `hooks' directory.
;; Each filename in `hooks' is used as hook name.

(sg:with-elisp-files "hooks/" hook-filename
  (let ((hook-name (intern (file-name-base hook-filename))))
    (add-hook hook-name `(lambda () (load ,hook-filename)))))


;; ===[ P A C K A G E S ]===

(require 'package)

(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/"))

(unless (package-installed-p 'use-package)
  (unless package-archive-contents
    (package-refresh-contents))
  (package-install 'use-package))

(require 'use-package)


;; ===[ A P P E A R A N C E ]===

;; Supress known information.
(setq inhibit-startup-screen t)

;; No visual distractions.
(blink-cursor-mode 0)

;; --- User interface

(load-theme 'wombat)

;; Remove useless elements.
(menu-bar-mode 0)
(tooltip-mode 0)
(tool-bar-mode 0)
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode 0))

;; --- Mode line

;; Show cursor coordinates.
(line-number-mode 1)
(column-number-mode 1)

;; Show buffer size.
(size-indication-mode 1)

;; --- Buffer content

;; Avoid visually truncating lines.
(set-default 'truncate-lines t)

;; Use visually concise symbols (for modes that support it).
(global-prettify-symbols-mode 1)

;; Show empty lines after buffer end.
(set-default 'indicate-empty-lines t)

;; --- Bell behaviour

;; Alternatives:
;;(setq visible-bell t)
;;(setq ring-bell-function 'sg:flash-mode-line)
(setq ring-bell-function 'ignore)

;; --- Visual aids

;; Show matching parentheses.
(show-paren-mode 1)

;; No limit for matching parenthesis.
(setq blink-matching-paren-distance nil)


;; ===[ I 1 8 N ]===

(setq locale-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-clipboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)


;; ===[ N A V I G A T I O N ]===

;; --- Scrolling

(put 'scroll-left 'disabled nil)

;; Avoid scroll “jumps” (scroll one line at a time).
(setq scroll-conservatively 1)

;; Number of lines before scroll begins.
(setq scroll-margin 10)

;; Keep cursor fixed when paging up or down.
(setq scroll-preserve-screen-position 1)

;; --- Windows

;; Navigate windows with M-<arrows>.
(windmove-default-keybindings 'meta)
(setq windmove-wrap-around t)


;; ===[ E D I T I N G ]===

;; Lines should be 80 characters wide, not 70.
(set-default 'fill-column 79) ; columns are 0-based

;; Save other program's selection before killing text.
(setq save-interprogram-paste-before-kill t)

;; Enable change region case commands.
;; (off by default for the sake of novices)
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

;; Enable narrowing commands.
;; (off by default for the sake of novices)
(put 'narrow-to-region 'disabled nil)
(put 'narrow-to-page 'disabled nil)
(put 'narrow-to-defun 'disabled nil)

;; Enable erase-buffer command.
;; (off by default for the sake of novices)
;; See http://emacsredux.com/blog/2013/05/04/erase-buffer/
(put 'erase-buffer 'disabled nil)

;; Have TAB work as autocomplete if line already indented.
(setq tab-always-indent 'complete)
(add-to-list 'completion-styles 'initials t)

;; Easily navigate sillyCasedWords.
(global-subword-mode 1)


;; ===[ W H I T E S P A C E ]===

;; Use spaces for indentation.
(setq-default indent-tabs-mode nil)

;; Shorten rendering of tab characters
(setq-default tab-width 4)

;; Ensure that files end with a newline.
(setq require-final-newline t)

;; Manage whitespace everywhere.
(global-whitespace-mode 1)


;; ===[ B U F F E R S ]===

;; Suppress default (help) message from *scratch*.
(setq initial-scratch-message nil)

;; Revert unmodified buffer when file changes.
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t ; works in particular for dired
      auto-revert-verbose nil) ; be quiet about auto reverting

;; Seems the most intuitive to me.
(setq uniquify-buffer-name-style 'forward)

;; --- Minibuffer

(setq savehist-file (expand-file-name "savehist" emacs-state-dir))
(savehist-mode 1)


;; ===[ F I L E S ]===

(defconst emacs-backup-dir
  (expand-file-name "backups" emacs-tmp-dir)
  "Directory to store backup files.")

(make-directory emacs-backup-dir t)

;; Make backups files.
;; (http://www.emacswiki.org/emacs/ForceBackups)
(setq backup-directory-alist `((".*" . ,emacs-backup-dir))
      vc-make-backup-files t ; even when file is under version control
      vc-follow-symlinks t ; mention that a symlink is under version control
      version-control t ; use version numbers for backups
      kept-new-versions 10 ; number of newest versions to keep
      kept-old-versions 0 ; number of oldest versions to keep
      delete-old-versions t ; be silent about deleting excess backup versions
      backup-by-copying t) ; don't clobber symlinks

;; Store autosave files in tmp dir.
(setq auto-save-file-name-transforms `((".*" ,emacs-tmp-dir t))
      auto-save-list-file-prefix emacs-tmp-dir)

;; Move files to trash when deleting.
(setq delete-by-moving-to-trash t)

;; Warn when opening files bigger than 100MB.
(setq large-file-warning-threshold (* 100 1024 1024))

;; Keep a list of recently opened files.
(recentf-mode 1)

;; File-local variables that can be trusted.
(setq safe-local-variable-values
      '((epa-armor . t)
        (ispell-dictionary . "french")))

;; Missing default auto-modes
(add-to-list 'auto-mode-alist '("AUTHORS\\'" . text-mode))


;; ===[ S E S S I O N S ]===

;; Save point position between sessions.
(require 'saveplace)
(setq-default save-place t)
(setq save-place-file (expand-file-name "saveplace" emacs-state-dir))


;; ===[ A C C E L E R A T O R S ]===

;; Make all "yes or no" prompts show "y or n" instead.
(defalias 'yes-or-no-p 'y-or-n-p)

;; Interactive do
(ido-mode 1)
(ido-everywhere 1)
(setq ido-save-directory-list-file (expand-file-name "ido" emacs-state-dir)
      ido-enable-flex-matching t
      ido-use-url-at-point t
      ido-show-dot-for-dired t
      ido-use-virtual-buffers 'auto
      ido-default-buffer-method 'selected-window)


;; ===[ T O O L S ]===

;; --- ispell

(setq ispell-program-name "aspell"
      ispell-dictionary "british"
      ispell-extra-args '("--sug-mode=ultra" "--keyboard=dvorak"))

;; --- eshell

(setq eshell-history-file-name
      (expand-file-name "eshell-history" emacs-state-dir))

;; --- tramp

(setq tramp-persistency-file-name
      (expand-file-name "tramp" emacs-state-dir))


;; ===[ P L A T F O R M ]===

;; Load configuration based on current system type.
(let* ((base-name (symbol-name system-type))
       (system-type-config (concat "system-type/" base-name)))
  (load system-type-config 'optional))

;; Load configuration based on current window system.
(let* ((base-name (symbol-name window-system))
       (window-system-config (concat "window-system/" base-name)))
  (load window-system-config 'optional))


;; ===[ C U S T O M I Z A T I O N ]===

;; Load custom key assignments.
(load (expand-file-name "keys" user-emacs-directory) 'optional)

;; Don't let customisation code clutter this file.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

;; Load user preferences if available.
(load custom-file 'optional)


;; ===[ U S E D   P A C K A G E S ]===

(use-package diminish
    :ensure t)

(use-package ace-jump-mode
    :ensure t
    :bind ("§" . ace-jump-char-mode)
    :config (ace-jump-mode-enable-mark-sync))

(use-package smex
    :ensure t
    :bind
    (("M-x" . smex)
     ("M-X" . smex-major-mode-commands))
    :config
    (setq smex-save-file (expand-file-name "smex" emacs-state-dir)))

(use-package undo-tree
    :ensure t
    :config
    (global-undo-tree-mode 1)
    (setq undo-tree-mode-lighter "")
    (setq undo-tree-history-directory-alist
          (list (cons "" (expand-file-name "undo-tree" emacs-state-dir)))))

(use-package company
    :ensure t
    :defer t
    :diminish
    :config (global-company-mode 1))

(use-package expand-region
    :ensure t
    :bind ("C-\\" . 'er/expand-region))

(use-package golden-ratio
    :ensure t
    :diminish
    :init (golden-ratio-mode 1))

(use-package ido-completing-read+
    :ensure t
    :defer t
    :config (ido-ubiquitous-mode 1))


(use-package ido-at-point
    :ensure t
    :defer t
    :config (ido-at-point-mode 1))

(use-package flx-ido
    :ensure t
    :defer t
    :config
    (flx-ido-mode 1)
    (setq ido-use-faces nil))

(use-package elisp-slime-nav
    :ensure t
    :defer t
    :diminish)

(use-package fish-mode
    :ensure t
    :defer t)

(use-package company-elisp
    :after (company elisp-mode)
    :config
    (push 'company-elisp company-backends))

(use-package tex
    :ensure auctex
    :defer t)

(use-package company-auctex
    :after (company latex))

(use-package deft
    :ensure t
    :bind ([f8] . deft)
    :config
    (setq deft-extension "text")
    (setq deft-directory "~/Projects/notes")
    (when (locate-library "markdown-mode")
      (setq deft-text-mode 'markdown-mode)))

(use-package dockerfile-mode
    :ensure t
    :defer t)

(use-package docker-compose-mode
    :ensure t
    :defer t)

(use-package magit
    :ensure t
    :bind (("C-x g" . magit-status)
           ("C-x G" . magit-status-with-prefix))
    :config
    (setq magit-completing-read-function 'magit-ido-completing-read))

(use-package markdown-mode
    :ensure t
    :defer t)

(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1)
  :diminish ec)

(use-package paredit
    :ensure t
    :defer t
    :diminish "ped")

(use-package rg
    :ensure t
    :defer t)

(use-package slime
    :if (executable-find "sbcl")
    :ensure t
    :defer t
    :config
    (setq inferior-lisp-program "sbcl")
    (setq slime-contribs '(slime-fancy)))

(use-package slime-company
    :after slime)

(when (executable-find "clojure")
  (use-package clojure-mode
      :ensure t
      :defer t
      :diminish "clj")
  (use-package clojure-mode-extra-font-locking
      :ensure t
      :after clojure-mode)
  (use-package projectile
      :ensure t
      :defer t
      :diminish "prj"
      :bind-keymap
      ("C-c p" . projectile-command-map)
      :init
      (setq projectile-known-projects-file
            (expand-file-name "projectile-bookmarks.eld" emacs-state-dir)))
  (use-package cider
      :ensure t
      :defer t
      :diminish "clj"
      :config
      (projectile-mode 1))
  (add-hook 'clojure-mode-hook #'paredit-mode))

(use-package password-store
    :if (executable-find "pass")
    :ensure t
    :load-path "/usr/local/share/emacs/site-lisp/pass")

(use-package auto-package-update
    :ensure t
    :config
    (setq auto-package-update-delete-old-versions t
          auto-package-update-interval 15)
    (auto-package-update-maybe))
