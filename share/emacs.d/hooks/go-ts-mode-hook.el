;; -*- lexical-binding: t -*-

;; Go-specific configuration.
;; Inherits from prog-mode-hook.

;; Go code is formatted by gofmt, which indents with tabs.
(setq-local indent-tabs-mode t
            tab-width 4
            go-ts-mode-indent-offset 4)

;; Organize imports and format through gopls on save.
(add-hook 'before-save-hook
          (lambda ()
            (when (eglot-managed-p)
              ;; Signals an error when there are no imports to organize.
              (ignore-errors
                (eglot-code-action-organize-imports (point-min) (point-max)))
              (eglot-format-buffer)))
          nil t)
