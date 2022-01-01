;; Remove key bindings that conflict with
;; (windmove-default-keybindings 'meta)
(define-key paredit-mode-map (kbd "M-<up>") nil)
(define-key paredit-mode-map (kbd "M-<down>") nil)

;; Replace annoying key bindings with SLIME-like ones.
;; These are more intuitive given the assignments of C-M-<up> and -<down>.
(define-key paredit-mode-map (kbd "C-M-<left>") 'paredit-backward)
(define-key paredit-mode-map (kbd "C-M-<right>") 'paredit-forward)

;; But keep the previous 2 assignments under different keys.
(define-key paredit-mode-map (kbd "C-S-<left>") 'paredit-backward-slurp-sexp)
(define-key paredit-mode-map (kbd "C-S-<right>") 'paredit-backward-barf-sexp)
