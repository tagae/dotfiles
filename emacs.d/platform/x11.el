;;; === Behaviour

;; Delete key
(global-set-key [delete] 'delete-char)

;;; === Look & feel

;; Avoid tooltips
(tooltip-mode 0)

;; Color theme.
(when (functionp 'load-theme)
  ;(load-theme 'solarized-dark)
  (load-theme 'wombat)
  ;(load-theme 'tango)
)

(set-fringe-style 4)
