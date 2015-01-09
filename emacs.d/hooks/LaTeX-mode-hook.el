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
(when (require 'auctex nil 'recommended)

  (dolist (spec '(("Make" "make %s.pdf"
                   TeX-run-command t t
                   :help "Run make")
                  ("TeX" "%`tex --synctex=1%(mode)%' %t"
                   TeX-run-TeX nil (latex-mode context-mode)
                   :help "Run TeX with SyncTeX")
                  ("LaTeX" "%`pdflatex --synctex=1%(mode)%' %t"
                   TeX-run-TeX nil (latex-mode context-mode)
                   :help "Run LaTeX with SyncTeX")
                  ("XeLaTeX" "%`xelatex --synctex=1%(mode)%' %t"
                   TeX-run-TeX nil (latex-mode context-mode)
                   :help "Run XeLaTeX with SyncTeX")
                  ("Biber" "biber %s"
                   TeX-run-Biber nil (latex-mode context-mode)
                   :help "Run Biber"))
           (add-to-list 'TeX-command-list spec t)))

  (defun TeX-run-Biber (name command file)
    "Create a process for NAME using COMMAND to format FILE with Biber."
    (let ((process (TeX-run-command name command file)))
      (setq TeX-sentinel-function 'TeX-Biber-sentinel)
      (if TeX-process-asynchronous
          process
          (TeX-synchronous-sentinel name file process))))

  (defun TeX-Biber-sentinel (process name)
    "Cleanup TeX output buffer after running Biber."
    (goto-char (point-max))
    (cond
      ;; Check whether Biber reports any warnings or errors.
      ((re-search-backward (concat
                            "^(There \\(?:was\\|were\\) \\([0-9]+\\) "
                            "\\(warnings?\\|error messages?\\))") nil t)
       ;; Tell the user their number so that she sees whether the
       ;; situation is getting better or worse.
       (message (concat "Biber finished with %s %s. "
                        "Type `%s' to display output.")
                (match-string 1) (match-string 2)
                (substitute-command-keys
                 "\\\\[TeX-recenter-output-buffer]")))
      (t
       (message (concat "Biber finished successfully. "
                        "Run LaTeX again to get citations right."))))
    (setq TeX-command-next TeX-command-default))

  ;;(setq-default TeX-master nil) ; query for master file if not defined locally

  ;;(local-set-key '[(meta tab)] 'TeX-complete-symbol)

  (setq TeX-command-default "XeLaTeX"
        TeX-save-query nil) ; autosave before compiling

  ;; Autocompile after save, for documents that have set TeX-master.
  (add-hook 'after-save-hook
            (lambda ()
              (when TeX-master
                (TeX-command TeX-command-default 'TeX-master-file 0))))

  (turn-on-reftex))
