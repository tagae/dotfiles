;; Reuse current buffer by pressing 'a'.
;; (off by default for the sake of novices)
; (put 'dired-find-alternate-file 'disabled nil)

;; Always delete and copy recursively.
(setq dired-recursive-deletes 'always
      dired-recursive-copies 'always)

;; Show human-readable file sizes.
(setq dired-listing-switches "-alh")

;; Use other dired's subdir, instead of current subdir.
; (setq dired-dwim-target t)

;; --- dired-x

;(require 'dired-x)

;; Prevent dired-x from binding C-x C-j.
;; (alternative defined in `keys.el')
;(setq dired-bind-jump nil)

;; Omit uninteresting files by default.
;(dired-omit-mode 1)

;; Ignore Java class files.
;; (add-to-list 'dired-omit-extensions ".class")
