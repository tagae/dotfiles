;; Have the delete key behave as expected.
(global-set-key [delete] 'delete-char)

;; Higher frames by default.
(setq default-frame-alist '((height . 70)))

;; Avoid tooltips.
(tooltip-mode 0)

;; Color theme.
(load-theme 'wombat)

;; Yank at point instead of at click.
(setq mouse-yank-at-point t)

;; Use primary selection for cutting and pasting.
(setq x-select-enable-primary t)
