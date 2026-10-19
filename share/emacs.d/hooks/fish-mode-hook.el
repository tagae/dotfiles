;; -*- lexical-binding: t -*-

;; Fish-specific configuration.
;; Inherits from prog-mode-hook.

(when (executable-find "fish-lsp")
  (eglot-ensure))
