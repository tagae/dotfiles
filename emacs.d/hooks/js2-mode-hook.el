(when nil ;; disabled code
  (when (require 'smart-tabs-mode nil t)
    (smart-tabs-mode-enable)
    (smart-tabs-advice js2-indent-line js2-basic-offset)))
