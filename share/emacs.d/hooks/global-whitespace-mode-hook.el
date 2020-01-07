;; Automatically clean up bad whitespace.
(setq whitespace-action '(auto-cleanup))

;; Only show bad whitespace.
(setq whitespace-style
      '(face
        indentation
        empty
        lines
        space-before-tab
        space-after-tab
        tabs ; tab-mark
        trailing)
      whitespace-line-column 100)

;; Set calmer faces for common kinds of whitespace.

(set-face-attribute 'whitespace-indentation nil
                    :foreground nil
                    :background "#353"
                    :weight 'bold)

; Empty lines at end of file.
(set-face-attribute 'whitespace-empty nil
                    :foreground nil
                    :background "#533"
                    :weight 'bold)

(set-face-attribute 'whitespace-space-after-tab nil
                    :foreground nil
                    :background "#335"
                    :weight 'bold)
