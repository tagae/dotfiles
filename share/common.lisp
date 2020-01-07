(in-package #:cl-user)

#+disable
(let ((mudballs-path
       (merge-pathnames #p"Applications/opt/mudballs/boot.lisp" *home*)))
  (when (probe-file mudballs-path)
    (load mudballs-path)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (pushnew (merge-pathnames #p"Applications/opt/slime/" *home*)
           asdf:*central-registry* :test #'equal)

  (pushnew (merge-pathnames #p"Applications/lib/common-lisp/" *home*)
           asdf:*central-registry* :test #'equal)

  (pushnew
   (merge-pathnames #p".asdf-install-dir/systems/" *home*)
   asdf:*central-registry* :test #'equal)

  (pushnew
   (merge-pathnames #p"Applications/opt/clbuild/systems/" *home*)
   asdf:*central-registry* :test #'equal))

;; Stop the pretty printer from going bananas when displaying cyclic
;; data structures

(setq *print-pretty* t
      *print-circle* t
      *print-length* 20
      *print-level* 5)

(cond
  ((probe-file #p"/etc/gentoo-init.lisp")
   #+nil (load #p"/etc/gentoo-init.lisp"))
  (t
   ;; configure asdf-binary-locations
   ;; (when (find-symbol '*centralize-lisp-binaries* (find-package 'asdf))
   ;;   (setq asdf:*centralize-lisp-binaries* t))
   ;; (setq asdf:*default-toplevel-directory*
   ;;       (merge-pathnames #p"Applications/var/common-lisp/" *home*))
))

;; Local Variables:
;; mode: lisp
;; End:

#+setup
(

 (pushnew #p"/Users/tagae/Applications/opt/ccl-svn/tools/asdf-install/"
  asdf:*central-registry* :test #'equal)
 (asdf:oos 'asdf:load-op 'asdf-install)
 (asdf-install:install 'asdf-binary-locations)
 (asdf:oos 'asdf:load-op 'asdf-binary-locations)
)
