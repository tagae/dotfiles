;; mode line utilities.

(defun sg:flash-mode-line ()
  "Quiclky flash the mode line."
  (invert-face 'mode-line)
  (run-with-timer 0.1 nil 'invert-face 'mode-line))

(provide 'sg/mode-line)
