(whitespace-mode t)

(define-key coffee-mode-map [(meta r)] 'coffee-compile-buffer)
(define-key coffee-mode-map [(meta R)] 'coffee-compile-region)

;; Execute `coffee` in the directory where Emacs was started. This is
;; particularly useful if you have ./node_modules/.bin in your PATH.
(setq default-directory command-line-default-directory)

;(add-hook 'find-file-hook
;  (lambda ()
;    (setq default-directory command-line-default-directory)))
