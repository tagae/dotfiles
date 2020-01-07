(add-to-list 'load-path "/opt/local/share/emacs/site-lisp")
(add-to-list 'load-path "/opt/local/share/emacs/site-lisp/slime")

(setq trash-directory "~/.Trash/emacs")

(if (executable-find "gls") ; GNU ls, from `coreutils'
    (setq insert-directory-program "gls")
  ;; Darwin's `ls` does not support `--dired` option.
  (setq dired-use-ls-dired nil))

; Go away, ugly (and ubiquitous) .DS_Store files.
(add-to-list 'ido-ignore-files "\\.DS_Store")

(when (require 'exec-path-from-shell nil 'recommended)
  (exec-path-from-shell-initialize))

;; --- Clipboard interaction

;; Use system clipboard even when running on a terminal.
(when (not window-system)

  (defun copy-from-osx ()
    (shell-command-to-string "pbpaste"))

  (defun paste-to-osx (text &optional push)
    (let ((process-connection-type nil))
      (let ((proc (start-process "pbcopy" "*Messages*" "pbcopy")))
        (process-send-string proc text)
        (process-send-eof proc))))

  (setq interprogram-cut-function 'paste-to-osx
        interprogram-paste-function 'copy-from-osx))
