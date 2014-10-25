(define-key inferior-lisp-mode-map
  "\C-cl"
  '(lambda ()
     (interactive)
     (erase-buffer)
     (lisp-eval-string "")))
