;; Load paths

(add-to-list 'load-path "~/Applications/opt/slime")
(add-to-list 'load-path "~/Applications/opt/slime/contrib")

;;; Common Lisp implementations

;; by registering your implementations, you can choose one by
;; its "short name" when doing M-- M-x slime
(setq slime-lisp-implementations
  `((sbcl ("sbcl"))
    (ccl ("ccl"))
    (clisp ("clisp"))
    ,@slime-lisp-implementations))

;;; SLIME prefs

(setq slime-auto-connect 'always)

(slime-setup '(slime-repl
               slime-asdf
               slime-fancy
               slime-banner
               inferior-slime))

;;; Hyperspec

;(eval-after-load "hyperspec"
;  '(load "hyperspec-addon"))

;; hyperspec path
(some (lambda (path)
        (let ((path (expand-file-name path)))
          (when (file-accessible-directory-p path)
            (setq common-lisp-hyperspec-root path))))
      '("/usr/share/doc/hyperspec-7.0/HyperSpec/"
        "/sw/share/doc/hyperspec/"
        "/opt/local/share/doc/lisp/HyperSpec-7-0/HyperSpec/"))

;;; Info

;; register info help (dpans2texi)
(info-lookup-add-help
 :mode 'lisp-mode
 :regexp "[^][()'\" \t\n]+"
 :ignore-case t
 :doc-spec '(("(ansicl)Symbol Index" nil nil nil)))

;; register hooks
(add-hook 'slime-connected-hook
  (lambda ()
    (cond
     ((member ':ccl (slime-lisp-features))
      (slime-load-file "~/.ccl.lisp"))
     ((member ':clisp (slime-lisp-features))
      (slime-load-file "~/.clisp.lisp")))))

;;; Editor

;;(setq slime-complete-symbol*-fancy t)
;;(setq slime-complete-symbol-function 'slime-fuzzy-complete-symbol)
(local-set-key [tab] 'slime-indent-and-complete-symbol)
(set-variable lisp-indent-function 'common-lisp-indent-function)

(message "Loaded tagae's Slime config")
