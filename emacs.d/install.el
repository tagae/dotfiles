;; el-get
(url-retrieve
   "https://raw.github.com/dimitri/el-get/master/el-get-install.el"
   (lambda (status)
     (goto-char (point-max))
     (eval-print-last-sexp)))

;; el-get packages
(defvar world
  '(auctex
    markdown-mode
    clojure-mode
    nrepl))

(dolist (package world)
  (el-get-install package))
