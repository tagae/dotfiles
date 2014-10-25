;;; === Personal data

(setq user-full-name "Sebastián González"
      user-mail-address "tagae@ehub.io")

;;; === Emacs look & feel

;; Do not show the splash screen.
(setq inhibit-startup-message t)

;; Show line and column numbers.
(line-number-mode 1)
(column-number-mode 1)

;;; === Emacs behaviour

;; Load paths.
(add-to-list 'load-path "~/.emacs.d")
(add-to-list 'load-path "~/.emacs.d/packages")

;; Use UTF-8 by default.
(set-default-coding-systems 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-clipboard-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

;; Make all "yes or no" prompts show "y or n" instead.
(fset 'yes-or-no-p 'y-or-n-p)

;; Let autosaves and backups go into $TMPDIR/emacs-$USER/
(defconst emacs-tmp-dir
  (format "%s%s-%s/" temporary-file-directory "emacs" (user-login-name)))

(setq backup-directory-alist `((".*" . ,emacs-tmp-dir))
      auto-save-file-name-transforms `((".*" ,emacs-tmp-dir t))
      auto-save-list-file-prefix emacs-tmp-dir)

;; Reduce tab size to a minimum.
(setq-default tab-width 2)

;; Manage whitespace.
(global-whitespace-mode 1)

;; Don't let customisation code clutter this file.
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file 'noerror)

;; Make scripts executable when saved.
(add-hook 'after-save-hook
          'executable-make-buffer-file-executable-if-script-p)

;; Avoid automatic breaking of lines.
(auto-fill-mode 0)

;;; === Platform-specific configuration

(cond
 ((eq system-type 'gnu/linux)
  (load "platform/linux")
  (eq system-type 'darwin)
  (load "platform/darwin")))

(if (eq window-system 'x)
  (load "platform/x11")
  (load "platform/term"))

;;; === Mode hooks

(let ((hooks-dir "~/.emacs.d/hooks/"))
  (when (file-exists-p hooks-dir)
    (dolist (hook-file (directory-files hooks-dir nil "\\.el\\'"))
      (let ((hook-name (intern (substring hook-file 0 -3))))
        (add-hook hook-name
                  `(lambda ()
                     (load-file ,(concat hooks-dir hook-file))))))))

;;; === Package customizations

(defvar loaded-customizations '())

(let ((package-config-dir "~/.emacs.d/after-load/"))
  (when (file-exists-p package-config-dir)
    (dolist (config-file
             (directory-files package-config-dir nil "\\.el\\'"))
      (let ((package-name (intern (substring config-file 0 -3))))
        (eval-after-load package-name
          `(unless (memq ',package-name loaded-customizations)
             (load-file ,(concat package-config-dir config-file))
             (add-to-list 'loaded-customizations ',package-name)))))))

;;; === Preloading

(let ((preloads-dir "~/.emacs.d/preload/"))
  (when (file-exists-p preloads-dir)
    (dolist (preload-file (directory-files preloads-dir nil "\\.el\\'"))
      (load-file (concat preloads-dir preload-file)))))
