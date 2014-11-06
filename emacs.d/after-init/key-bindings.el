;; Turn on the menu bar for exploring new modes.
(global-set-key (kbd "C-<f10>") 'menu-bar-mode)

;; Transpose stuff with M-t.
(global-unset-key (kbd "M-t")) ;; which used to be transpose-words
(global-set-key (kbd "M-t l") 'transpose-lines)
(global-set-key (kbd "M-t p") 'transpose-params)
(global-set-key (kbd "M-t s") 'transpose-sexps)
(global-set-key (kbd "M-t w") 'transpose-words)

;; Handy when coding in any programming language.
(global-set-key (kbd "C-c ;") 'comment-or-uncomment-region)
(global-set-key (kbd "RET") 'newline-and-indent)
(global-set-key (kbd "C-c l") 'sort-lines)
