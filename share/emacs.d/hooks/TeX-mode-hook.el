(outline-minor-mode 1)
(visual-line-mode 1)
(flyspell-mode 1)

;; Use smartparens.
(when (require 'smartparens nil 'recommended)
  (require 'smartparens-latex)
  (smartparens-mode 1))

;; For case-sensitive file systems, all AUCTeX-specific code could go in
;; TeX-mode-hook.el instead of here.
(when (load "auctex" 'noerror 'nomessage)

  (cond
      ((eq system-type 'gnu/linux)
       (add-to-list 'TeX-output-view-style '("^pdf$" "." "kpdf %o")))
      ((eq system-type 'darwin)
       (add-to-list 'TeX-view-program-list '("Preview" "open -a Preview.app %o"))
       (add-to-list 'TeX-view-program-selection '(output-pdf "Preview"))
       (add-to-list 'TeX-view-program-selection '(output-pdf "Skim"))))

  (setq TeX-parse-self t
        TeX-save-query nil ; autosave before compiling
        TeX-PDF-mode t)

  (add-to-list 'TeX-command-list
               '("Make" "make %s.pdf" TeX-run-command t t
                 :help "Run make") t)

  ;; === PDF-TeX Sync support

  (require 'server) ; no autoloads provided
  (unless (server-running-p)
    (server-start))

  (setq TeX-source-correlate-method 'synctex
        TeX-source-correlate-start-server nil)

  (TeX-source-correlate-mode 1)

  (when (eq system-type 'darwin)
    (add-to-list 'TeX-view-program-list
                 '("Skim"
                   "/Applications/Skim.app/Contents/SharedSupport/displayline %n %o %b")))

  (add-to-list 'TeX-command-list
               '("TeX" "%`tex --synctex=1%(mode)%' %t"
                 TeX-run-TeX nil (latex-mode context-mode)
                 :help "Run TeX with SyncTeX support") t)

  ;; === end of PDF-TeX Sync support

  (turn-on-reftex))
