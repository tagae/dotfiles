(setq inferior-lisp-program "lein repl")

;; clj-refactor
(require 'clj-refactor)
(clj-refactor-mode 1)
(cljr-add-keybindings-with-prefix "C-c C-o")

;; align-cljlet
(require 'align-cljlet)
(global-set-key (kbd "C-c C-a") 'align-cljlet)

;; paredit
(require 'paredit)
(paredit-mode)

;; projectile
(require 'projectile)
(projectile-mode)

;; company-mode
(require 'company)
(company-mode)

(require 'company-etags)
(add-to-list 'company-etags-modes 'clojure-mode)

;; yasnippet
(require 'yasnippet)
(require 'clojure-snippets)
(yas-global-mode 1)
(add-to-list 'yas-snippet-dirs "~/.emacs.d/snippets")
(yas-load-directory "~/.emacs.d/snippets")
