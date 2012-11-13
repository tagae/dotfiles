;;; === Behaviour

;; Delete key
(global-set-key [delete] 'delete-char)

;; Yank from clipboard, kill into clipboard
(setq x-select-enable-clipboard t)

;;; === Look & feel

;; Color theme.
(when (functionp 'load-theme)
  ;(load-theme 'solarized-dark)
  (load-theme 'wombat)
  ;(load-theme 'tango)
)

(set-fringe-style 4)

;; Remove visual clutter.
(dolist (mode
         '(tool-bar-mode
           scroll-bar-mode
           tooltip-mode))
  (when (functionp mode)
    (apply mode 0 nil))) ; disable
