(diminish 'paredit-mode "PE")

;; Remove annoying key bindings set by paredit.
(define-key paredit-mode-map (kbd "M-<up>") nil)
(define-key paredit-mode-map (kbd "M-<down>") nil)
