;; Emacs Lisp-specific configuration.
;; Inherits from prog-mode-hook.

;; Instead of the default 'Emacs-Lisp'.
(setq mode-name "el")

;; Use Common Lisp indentation by default.
(set (make-local-variable 'lisp-indent-function)
     'common-lisp-indent-function)

;; Custom indentation for specific functions.
(put 'advice-add 'lisp-indent-function 'defun)

;; Display Lisp object at point in echo area.
(eldoc-mode 1)

;; Turn on docstring checking.
(checkdoc-minor-mode 1)

;; Use these visually concise symbols.
(dolist (sym '(("<=" . ?≤)
               (">=" . ?≥)
               ("/=" . ?≠)))
  (push sym prettify-symbols-alist))

;; Good old SLIME navigation.
(when (require 'elisp-slime-nav nil 'recommended)
  (elisp-slime-nav-mode 1))

;; Maniacal but lovely editing mode.
(when (require 'paredit nil 'recommended)
  (paredit-mode 1))
