(outline-minor-mode 1)
(visual-line-mode 1)

;; Use smartparens.
(when (require 'smartparens nil 'recommended)
  (require 'smartparens-latex)
  (smartparens-mode 1))

;; Start server for PDF-TeX Sync support
;; (unless (server-running-p)
;;   (server-start))

;; For case-sensitive file systems, all AUCTeX-specific code could go in
;; TeX-mode-hook.el instead of here.
(when (require 'auctex nil 'recommended)

  (cond
    ((eq system-type 'gnu/linux)
     (add-to-list 'TeX-output-view-style '("^pdf$" "." "kpdf %o")))
    ((eq system-type 'darwin)
     (add-to-list 'TeX-view-program-list
                  '("Preview" "open -a Preview.app %o"))
     (add-to-list 'TeX-view-program-list
                  '("Skim"
                    "/Applications/Skim.app/Contents/SharedSupport/displayline %n %o %b"))
     (add-to-list 'TeX-view-program-selection '(output-pdf "Preview"))
     (add-to-list 'TeX-view-program-selection '(output-pdf "Skim"))))


  (setq TeX-source-correlate-method 'synctex
        TeX-source-correlate-start-server t
        TeX-parse-self t
        TeX-save-query nil
        TeX-PDF-mode t)

  (TeX-source-correlate-mode 1)
  (TeX-fold-mode 1))
