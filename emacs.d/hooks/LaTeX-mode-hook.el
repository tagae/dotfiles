;;; Fonts

;; Disable font scaling for sectioning commands.
;(setq font-latex-fontify-sectioning 'color)

;; (let* ((yellow  "#b58900") ; from the solarized color theme
;;        (default yellow))
;;   (set-face-foreground 'font-latex-sectioning-0-face default)
;;   (set-face-foreground 'font-latex-sectioning-1-face default)
;;   (set-face-foreground 'font-latex-sectioning-2-face default)
;;   (set-face-foreground 'font-latex-sectioning-3-face default)
;;   (set-face-foreground 'font-latex-sectioning-4-face default)
;;   (set-face-foreground 'font-latex-sectioning-5-face default))

;; (loop
;;  for num from font-latex-sectioning-max downto 0
;;  for height-scale = 1.0 then (+ height-scale .05)
;;  for face-name = (intern (format "font-latex-sectioning-%s-face" num))
;;  unless (get face-name 'saved-face) ; Do not touch customized faces.
;;  do
;;    (message "Setting %s height scale to %s" face-name height-scale)
;;    (set-face-attribute face-name nil :height height-scale))


;; For case-sensitive file systems, all AUCTeX-specific code could go in
;; LaTeX-mode-hook.el instead of here.
(when (load "auctex" 'noerror 'nomessage)

  (dolist (spec '(("LaTeX" "%`pdflatex --synctex=1%(mode)%' %t"
                   TeX-run-TeX nil (latex-mode context-mode)
                   :help "Run LaTeX with SyncTeX")
                  ("XeLaTeX" "%`xelatex --synctex=1%(mode)%' %t"
                   TeX-run-TeX nil (latex-mode context-mode)
                   :help "Run XeLaTeX with SyncTeX"))
           (add-to-list 'TeX-command-list spec t)))

  (setq TeX-command-default "XeLaTeX"))
