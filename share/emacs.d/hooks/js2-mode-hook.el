(setq js2-basic-offset 2
      js2-bounce-indent-p t)

(electric-indent-mode 1)
(electric-pair-mode 1)

;; (flycheck-select-checker 'javascript-jslint-reporter)
(when (executable-find "jshint")
  (flycheck-mode 1))

(when (executable-find "tern")
  (tern-mode t))

(when (require 'idle-highlight-mode)
  (idle-highlight-mode 1))

(when (require 'highlight-escape-sequences)
  (hes-mode 1))

;; Highlight escape sequences (hes): won't work properly unless we do this:
(put 'font-lock-regexp-grouping-backslash 'face-alias 'font-lock-builtin-face)

(when (and (featurep 'company) (require 'company-tern nil 'recommended))
  (add-to-list 'company-backends 'company-tern))

(when (require 'smart-tabs-mode nil t)
  (smart-tabs-mode-enable)
  (smart-tabs-advice js2-indent-line js2-basic-offset))
