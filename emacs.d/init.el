;; Load paths.
(add-to-list 'load-path (expand-file-name "lib" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "packages" user-emacs-directory))

;; Use UTF-8 by default.
(setq locale-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-clipboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

;; Make all "yes or no" prompts show "y or n" instead.
(defalias 'yes-or-no-p 'y-or-n-p)

;; Make backups of files, even when they're in version control.
(setq vc-make-backup-files t)

;; No limit for matching parenthesis.
(setq blink-matching-paren-distance nil)

;; Reduce tab size to a minimum.
(setq default-tab-width 2)
(setq-default tab-width 2)

;; Lines should be 80 characters wide, not 70
(setq fill-column 80)
(set-default 'fill-column 80)

;; Show empty lines after buffer end.
(set-default 'indicate-empty-lines t)

;; Move files to trash when deleting.
(setq delete-by-moving-to-trash t)

;; See deeper into eval-expression.
(setq eval-expression-print-level 10)

;; Make scripts executable when saved.
(add-hook 'after-save-hook
          'executable-make-buffer-file-executable-if-script-p)

;; Avoid automatic breaking of lines.
(auto-fill-mode 0)

;; Replace selection with typed text.
(delete-selection-mode 1)

;; No need to mark things using shift.
(setq shift-select-mode nil)

;; Don't be so stingy on the memory, there's plenty.
(setq gc-cons-threshold 20000000)

;; Navigate windows with M-<arrows>.
;(windmove-default-keybindings 'meta)
;(setq windmove-wrap-around t)

;; Sentences do not need double spaces to end. Period.
(set-default 'sentence-end-double-space nil)

;; Revert unmodified buffer when file changes.
(global-auto-revert-mode 1)

;; Auto refresh dired.
(setq global-auto-revert-non-file-buffers t)
;(setq auto-revert-verbose nil) ; but be quiet about it

;; Show keystrokes in progress.
(setq echo-keystrokes 0.1)

;; Easily navigate sillycased words.
(global-subword-mode 1)

;; Recent files.
(recentf-mode 1)
(setq recentf-max-menu-items 100)
(global-set-key (kbd "C-x C-r") 'recentf-open-files)

;; Save minibuffer history.
(setq savehist-file (concat user-emacs-directory "state/savehist") )
(savehist-mode 1)
(setq history-length 1000)

;; Undo/redo window configuration with C-c <left>/<right>.
(winner-mode 1)

;; Avoid truncating lines.
(set-default 'truncate-lines t)

;; Used in other files.
(defvar package-state-dir (concat user-emacs-directory "state/")
  "Directory to save package state information.")

(make-directory package-state-dir t)

;; Let autosaves go into $TMPDIR/emacs-$USER/
(let ((auto-save-dir (concat user-emacs-directory "auto-save/")))
  (setq auto-save-file-name-transforms `((".*" ,auto-save-dir t))
        auto-save-list-file-prefix auto-save-dir))

;; Don't let customisation code clutter this file.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file 'noerror)

;; Enable commands disabled by default for the sake of new users.
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)

;;; === Platform-specific configuration
(cond
 ((eq system-type 'gnu/linux)
  (load "platform/linux")
  (eq system-type 'darwin)
  (load "platform/darwin")))

(if window-system
  (load "platform/x11")
  (load "platform/term"))

;;; === Hooks

(let ((hooks-dir (concat user-emacs-directory "hooks/")))
  (when (file-exists-p hooks-dir)
    (dolist (hook-file (directory-files hooks-dir nil "\\.el\\'"))
      (let ((hook-name (intern (substring hook-file 0 -3))))
        (add-hook hook-name
                  `(lambda ()
                     (load-file ,(concat hooks-dir hook-file))))))))

;; after-init hooks
(let ((after-init-dir (concat user-emacs-directory "after-init/")))
  (when (file-exists-p after-init-dir)
    (dolist (hook-file (directory-files after-init-dir nil "\\.el\\'"))
      (add-hook 'after-init-hook
                `(lambda ()
                   (load-file ,(concat after-init-dir hook-file)))))))

;;; === Package customizations

(defvar loaded-customizations '())

(let ((package-config-dir (concat user-emacs-directory "after-load/")))
  (when (file-exists-p package-config-dir)
    (dolist (config-file
             (directory-files package-config-dir nil "\\.el\\'"))
      (let ((package-name (intern (substring config-file 0 -3))))
        (eval-after-load package-name
          `(unless (memq ',package-name loaded-customizations)
             (load-file ,(concat package-config-dir config-file))
             (add-to-list 'loaded-customizations ',package-name)))))))

;;; === Preloads

(let ((init-dir (expand-file-name "init/"  user-emacs-directory)))
  (when (file-exists-p init-dir)
    (dolist (path (directory-files init-dir 'full "\\.el\\'"))
      (load-file path))))
