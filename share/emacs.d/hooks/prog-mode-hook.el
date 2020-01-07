;; Generic config for programming language text.

;; Spell check my comments pleaze.
(flyspell-prog-mode)

;; Follow tail of *compilation* buffer.
(setq compilation-scroll-output t
      compilation-auto-jump-to-first-error t)

;; Highlight all occurrences of word under cursor.
(when (require 'idle-highlight-mode nil 'recommended)
  (idle-highlight-mode 1))

;; --- Key bindings

(global-set-key (kbd "M-RET") 'indent-new-comment-line)

(local-set-key (kbd "M-C") 'compile)
