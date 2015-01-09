(define-key coffee-mode-map (kbd "M-r") 'coffee-compile-buffer)
(define-key coffee-mode-map (kbd "M-R") 'coffee-compile-region)

(setq coffee-tab-width 2)

;; Execute `coffee` in the directory where Emacs was started. This is
;; particularly useful if you have ./node_modules/.bin in your PATH.
(setq default-directory command-line-default-directory)
