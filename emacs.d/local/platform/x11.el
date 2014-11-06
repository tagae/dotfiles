;;; === Behaviour

;; Delete key
(global-set-key [delete] 'delete-char)

;;; === Look & feel

;; Avoid tooltips
(tooltip-mode 0)

;; Color theme.
(load-theme 'wombat)

(when nil
  (require 'solarized)
  (deftheme solarized-dark "The dark variant of the Solarized colour theme")
  (create-solarized-theme 'dark 'solarized-dark)
  (provide-theme 'solarized-dark)
  (load-theme 'solarized-dark))

;(load-theme 'flatland t)
