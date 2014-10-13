;; el-get

(add-to-list 'load-path "~/.emacs.d/el-get/el-get")
(unless (require 'el-get nil 'noerror)
  (url-retrieve
   "https://raw.github.com/dimitri/el-get/master/el-get-install.el"
   (lambda (status)
     (goto-char (point-max))
     (eval-print-last-sexp))))

(defvar goodies '(smex better-defaults))

(dolist (p goodies)
  (unless (package-installed-p p)
    (package-install p)))
