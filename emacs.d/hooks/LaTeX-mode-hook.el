;;; AUCTeX

(add-to-list
 'TeX-command-list
 '("XeLaTeX" "%`xelatex --synctex=1%(mode)%' %t"
   TeX-run-TeX nil (latex-mode context-mode)
   :help "Run XeLaTeX with SyncTeX"))

(add-to-list
 'TeX-command-list
 '("LaTeX" "%`pdflatex --synctex=1%(mode)%' %t"
   TeX-run-TeX nil (latex-mode context-mode)
   :help "Run LaTeX with SyncTeX"))

(setq TeX-command-default "XeLaTeX")

(setq-default TeX-master nil) ; query for master file if not defined locally

(local-set-key '[(meta tab)] 'TeX-complete-symbol)

;; autosave before compiling
(setq TeX-save-query nil)

;; autocompile after save, for documents that have set TeX-master
(add-hook 'after-save-hook
  (lambda ()
    (when TeX-master
      (TeX-command TeX-command-default 'TeX-master-file 0))))

;;; RefTeX

(autoload 'reftex-mode "reftex" "RefTeX Minor Mode" t)
(autoload 'turn-on-reftex "reftex" "RefTeX Minor Mode" nil)
(autoload 'reftex-citation "reftex-cite" "Make citation" nil)
(autoload 'reftex-index-phrase-mode "reftex-index" "Phrase Mode" t)

(turn-on-reftex)
(setq reftex-enable-partial-scans t)
(setq reftex-save-parse-info t)
(setq reftex-use-multiple-selection-buffers t)
(setq reftex-plug-into-AUCTeX t)

;;; Fonts

;; disable font scaling for sectioning commands
;(setq font-latex-fontify-sectioning 'color)
(let* ((yellow  "#b58900") ; from the solarized color theme
       (default yellow))
  (set-face-foreground 'font-latex-sectioning-0-face default)
  (set-face-foreground 'font-latex-sectioning-1-face default)
  (set-face-foreground 'font-latex-sectioning-2-face default)
  (set-face-foreground 'font-latex-sectioning-3-face default)
  (set-face-foreground 'font-latex-sectioning-4-face default)
  (set-face-foreground 'font-latex-sectioning-5-face default))

;; (loop
;;  for num from font-latex-sectioning-max downto 0
;;  for height-scale = 1.0 then (+ height-scale .05)
;;  for face-name = (intern (format "font-latex-sectioning-%s-face" num))
;;  unless (get face-name 'saved-face) ; Do not touch customized faces.
;;  do
;;    (message "Setting %s height scale to %s" face-name height-scale)
;;    (set-face-attribute face-name nil :height height-scale))

(message "Loaded tagae's LaTeX config")
