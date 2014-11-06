(setq smex-save-file (concat package-state-dir "smex"))
(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "M-X") 'smex-major-moode-commands)
