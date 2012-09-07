;;; === Behaviour

;; Delete key
(global-set-key [delete] 'delete-char)

;; Yank from clipboard, kill into clipboard
(setq x-select-enable-clipboard t)

;;; === Look & feel

;; Color theme

(when (functionp 'load-theme)
  ;(load-theme 'solarized-dark)
  (load-theme 'wombat))

;; Inhibit the button toolbar
;(when (functionp 'tool-bar-mode)
;  (tool-bar-mode 0)) ; now inhibited through Xresources

;; Inhibit scroll bars
(when (functionp 'scroll-bar-mode)
  (scroll-bar-mode 0))

;;; === Fonts

;; (set-default-font "-*-terminus-bold-*-*-14-*-*-*-*-*-*-*")
;; (set-default-font "-*-fixed-*-*-*-14-*-*-*-*-*-*-*")
;; (set-default-font "-*-monaco-*-*-*-13-*-*-*-*-*-*-*")
