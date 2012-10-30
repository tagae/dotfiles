;;; === Behaviour

;; Delete key
(global-set-key [delete] 'delete-char)

;; Yank from clipboard, kill into clipboard
(setq x-select-enable-clipboard t)

;;; === Look & feel

;; Color theme.
(when (functionp 'load-theme)
  ;(load-theme 'solarized-dark)
  ;(load-theme 'wombat)
  (load-theme 'tango)
)

;; Remove visual clutter.
(dolist (mode
         '(tool-bar-mode
           scroll-bar-mode
           set-fringe-style
           tooltip-mode))
  (when (functionp mode)
    (mode 0))) ; disable

;;; === Fonts

(set-frame-font "Menlo-14")
;; (set-default-font "-*-terminus-bold-*-*-14-*-*-*-*-*-*-*")
;; (set-default-font "-*-fixed-*-*-*-14-*-*-*-*-*-*-*")
;; (set-default-font "-*-monaco-*-*-*-13-*-*-*-*-*-*-*")
