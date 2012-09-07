(require 'assoc)

(setq swank-clojure-classpath
      (cons "/Users/tagae/Applications/opt/swank-clojure/src"
            (directory-files "~/Applications/opt/clojure" t ".jar$")))

(require 'swank-clojure)

(aput 'slime-lisp-implementations 'clojure
      (list (swank-clojure-cmd) :init 'swank-clojure-init))
