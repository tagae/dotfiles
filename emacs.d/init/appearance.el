;; Notes:
;;
;; * Some of the appearance is set by package `better-defaults`.
;;
;; * The early appearance of the tool and scroll bars can be
;;   inhibited through .Xresources:
;;       emacs*verticalScrollBars: off
;;       emacs*toolBar: off


;; Supress splash screen.
(setq inhibit-startup-message t)

;; Show line and column numbers.
(line-number-mode 1)
(column-number-mode 1)

;; Turn alarms off.
(setq ring-bell-function 'ignore)

;; Title bar format.
(setq frame-title-format "%b") ; instead of the host name

;; No blinking cursor.
(blink-cursor-mode 0)
