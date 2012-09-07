;;; === Personal data

(setq user-full-name "Sebastián González"
      user-mail-address "s.gonzalez@uclouvain.be"
      user-website "http://www.info.ucl.ac.be/~sgm/")


;;; === Emacs look & feel

;; Do not show the splash screen.
(setq inhibit-startup-message t)

;; Show line and column numbers.
(line-number-mode t)
(column-number-mode t)

;; Highlight matching parenthesis.
(show-paren-mode t)
(setq show-paren-delay 0
      show-paren-style 'parenthesis)


;;; === Emacs behaviour

;; Load paths.
(add-to-list 'load-path "~/.emacs.d")
(add-to-list 'load-path "~/.emacs.d/packages")

;; Use UTF-8 by default (be people friendly).
(set-default-coding-systems 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-clipboard-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

;; Make all "yes or no" prompts show "y or n" instead.
(fset 'yes-or-no-p 'y-or-n-p)

;; Backup (i.e. foo~) behaviour —put backup files in one place.
(defvar backup-dir "~/.emacs.d/backups/")
(setq backup-directory-alist (list (cons "." backup-dir)))

;; Autosave (i.e. #foo#) behaviour —put autosave files in one place.
(defvar auto-save-dir "~/.emacs.d/auto-saves/")
(make-directory auto-save-dir t)
(setq auto-save-file-name-transforms
      `(("\\(?:[^/]*/\\)*\\(.*\\)" ,(concat auto-save-dir "\\1") t)))

;; Always end a file with a newline.
(setq require-final-newline t)

;; Insert spaces instead of tabs
(setq-default indent-tabs-mode nil)

;; Reduce tab size to a minimum.
(setq-default tab-width 2)

(global-whitespace-mode)

;; Don't let customisation code clutter this file.
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file 'noerror)

;; Make scripts executable when saved.
(add-hook 'after-save-hook
          'executable-make-buffer-file-executable-if-script-p)


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
             (add-to-list 'loaded-customizations ',package-name)
             (message ,(format "Loaded local definitions for '%s."
                               package-name))))))))

;; --- el-get

(add-to-list 'load-path "~/.emacs.d/el-get/el-get")

(if (require 'el-get nil 'noerror)
	(el-get)
  (url-retrieve
   "https://raw.github.com/dimitri/el-get/master/el-get-install.el"
   (lambda (status)
     (goto-char (point-max))
     (eval-print-last-sexp))))

;;; === Preloading

(let ((preloads-dir "~/.emacs.d/preload/"))
  (when (file-exists-p preloads-dir)
    (dolist (preload-file (directory-files preloads-dir nil "\\.el\\'"))
      (load-file (concat preloads-dir preload-file)))))
