;; Automatically clean up bad whitespace.
(setq whitespace-action '(auto-cleanup))

;; Only show bad whitespace.
(setq whitespace-style
      '(face
        indentation
        lines
        space-after-tab
        space-before-tab
        tabs
        trailing)
      whitespace-line-column 100)
