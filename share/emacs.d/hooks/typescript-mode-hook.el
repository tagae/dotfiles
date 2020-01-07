(tide-setup)
(flycheck-mode +1)
(setq flycheck-check-syntax-automatically '(save mode-enabled))
(eldoc-mode +1)
;; company is an optional dependency. You have to
;; install it separately via package-install
(company-mode-on)

(setq typescript-indent-level 2)
