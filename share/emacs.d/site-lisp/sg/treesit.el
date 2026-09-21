;; -*- lexical-binding: t -*-

;; Tree-sitter grammar management.
;;
;; Grammars are compiled from source, so installing them is done once by the
;; provisioning (see `sg:treesit-install-missing-grammars'), not at startup.

(require 'treesit)

(defconst sg:treesit-language-sources
  '((go     "https://github.com/tree-sitter/tree-sitter-go" "v0.23.4")
    (gomod  "https://github.com/camdencheek/tree-sitter-go-mod" "v1.1.0"))
  "Grammars to install, in the format of `treesit-language-source-alist'.
Revisions are pinned because newer grammars are built against a tree-sitter
ABI that the tree-sitter library shipped with Emacs may not support.")

(setq treesit-language-source-alist sg:treesit-language-sources)

(defun sg:treesit-install-missing-grammars ()
  "Install the grammars in `sg:treesit-language-sources' that are missing.
Print the installed languages, if any."
  (let (installed)
    (dolist (source sg:treesit-language-sources)
      (let ((language (car source)))
        (unless (treesit-language-available-p language)
          (treesit-install-language-grammar language)
          (push language installed))))
    (when installed
      (princ (format "installed: %s\n" (nreverse installed))))))

(provide 'sg/treesit)
