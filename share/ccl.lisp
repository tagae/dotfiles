(in-package #:cl-user)

(require 'asdf)

(defparameter *home* (truename #p"~"))

(load (truename #p"~/.common.lisp"))

;; Local Variables:
;; mode: lisp
;; End:
