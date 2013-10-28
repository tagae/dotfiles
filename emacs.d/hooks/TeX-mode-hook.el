(outline-minor-mode 1)
;;(visual-line-mode t) ; this is on by default, when available

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

(setq TeX-source-correlate-method 'synctex)
(setq TeX-source-correlate-start-server nil)
(TeX-source-correlate-mode t)
(TeX-fold-mode 1)

(setq TeX-parse-self t)
(setq TeX-save-query nil)
(setq TeX-PDF-mode t)

;; Start server for PDF-TeX Sync support
(server-mode)
