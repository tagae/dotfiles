(setq reftex-enable-partial-scans t
      reftex-save-parse-info t
      reftex-use-multiple-selection-buffers t
      reftex-plug-into-AUCTeX t
      reftex-cite-prompt-optional-args nil
      reftex-cite-cleanup-optional-args t)

;; biblatex compatibility

(add-to-list 'reftex-bibliography-commands "addbibresource")

(setq reftex-cite-format
      '((?\C-m . "\\cite[]{%l}")
        (?t . "\\textcite{%l}")
        (?a . "\\autocite[]{%l}")
        (?p . "\\parencite{%l}")
        (?f . "\\footcite[][]{%l}")
        (?F . "\\fullcite[]{%l}")
        (?x . "[]{%l}")
        (?X . "{%l}")))

(setq font-latex-match-reference-keywords
      '(("cite" "[{")
        ("cites" "[{}]")
        ("footcite" "[{")
        ("footcites" "[{")
        ("parencite" "[{")
        ("textcite" "[{")
        ("fullcite" "[{")
        ("citetitle" "[{")
        ("citetitles" "[{")
        ("headlessfullcite" "[{")))

(TeX-add-style-hook "csquotes"
  (lambda ()
    (TeX-add-symbols
     '("textcquote"
       [ "pre-note (post-note if alone)" ]
       [ "post-note" ] TeX-arg-cite  [ "Punctuation" ] t ignore ignore)
     '("blockcquote"
       [ "pre-note (post-note if alone)" ]
       [ "post-note" ] TeX-arg-cite  [ "Punctuation" ] t ignore ignore)
     '("foreigntextcquote"
       "Language"  [ "pre-note (post-note if alone)" ]
       [ "post-note" ] TeX-arg-cite  [ "Punctuation" ] t ignore ignore)
     '("foreignblockcquote"
       "Language" [ "pre-note (post-note if alone)" ]
       [ "post-note" ] TeX-arg-cite  [ "Punctuation" ] t ignore ignore))))

;; end biblatex compatibility
