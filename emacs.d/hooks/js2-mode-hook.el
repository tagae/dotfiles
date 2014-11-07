(when (require 'smart-tabs-mode nil t)
  (smart-tabs-mode-enable)
  (smart-tabs-advice js2-indent-line js2-basic-offset))

(setq js2-basic-offset 4
      js2-bounce-indent-p t)

(flycheck-mode 1) ; needs `jshint` in PATH
