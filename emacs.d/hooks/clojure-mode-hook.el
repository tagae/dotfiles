;; (setq inferior-lisp-program "lein repl")

;; ;; clj-refactor
;; (require 'clj-refactor)
;; (clj-refactor-mode 1)
;; (cljr-add-keybindings-with-prefix "C-c C-o")

;; ;; align-cljlet
;; (require 'align-cljlet)
;; (global-set-key (kbd "C-c C-a") 'align-cljlet)

;; ;; paredit
;; (require 'paredit)
;; (paredit-mode)

;; ;; projectile
;; (require 'projectile)
;; (projectile-mode 1)

;; ;; company-mode
;; (require 'company)
;; (company-mode)

;; (require 'company-etags)
;; (add-to-list 'company-etags-modes 'clojure-mode)

;; ;; yasnippet
;; ;; (require 'yasnippet)
;; ;; (require 'clojure-snippets)
;; ;; (yas-global-mode 1)
;; ;; (add-to-list 'yas-snippet-dirs "~/.emacs.d/snippets")
;; ;; (yas-load-directory "~/.emacs.d/snippets")

;; (global-set-key (kbd "C-c C-s") 'clojure-toggle-keyword-string)

;; (define-key clojure-mode-map
;;   "\C-c\C-k"
;;   '(lambda ()
;;      (interactive)
;;      (let ((current-point (point)))
;;        (goto-char (point-min))
;;        (let ((ns-idx (re-search-forward clojure-namespace-name-regex nil t)))
;;          (when ns-idx
;;            (goto-char ns-idx)
;;            (let ((sym (symbol-at-point)))
;;              (message (format "Loading %s ..." sym))
;;              (lisp-eval-string (format "(require '%s :reload)" sym))
;;              (lisp-eval-string (format "(in-ns '%s)" sym)))))
;;        (goto-char current-point))))
