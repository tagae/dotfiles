;; elisp file manipulation utilities.

(defvar sg:elisp-file-pattern "^[^.].+\\.el$"
  "Regexp matching Emacs Lisp filenames. Ignores dotfiles.")

(defun sg:mapc-elisp-files (function path)
  "Applies FUNCTION to every filename in PATH matching
`sg:elisp-file-pattern'."
  (let ((dir (expand-file-name path user-emacs-directory)))
    (when (file-exists-p dir)
      (mapc function (directory-files dir t sg:elisp-file-pattern t)))))

(defun sg:load-elisp-files (path)
  "Load all elisp files in the given PATH. If PATH is relative,
`user-emacs-directory' is used as a base."
  (sg:mapc-elisp-files 'load path))

(defmacro sg:with-elisp-files (path var &rest body)
  "Do BODY with variable VAR bound to each filename in PATH that
matches `sg:elisp-file-pattern'. If PATH is relative,
`user-emacs-directory' is used as a base."
  (declare (indent 2))
  (let ((dir (make-symbol "dir")))
    `(let ((,dir (expand-file-name ,path user-emacs-directory)))
       (when (file-exists-p ,dir)
         (dolist (,var (directory-files ,dir t sg:elisp-file-pattern t))
           ,@body)))))

(provide 'sg/elisp-files)
