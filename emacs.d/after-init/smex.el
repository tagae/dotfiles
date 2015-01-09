(setq smex-save-file (expand-file-name "smex" emacs-state-dir))
(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "M-X") 'smex-major-mode-commands)
