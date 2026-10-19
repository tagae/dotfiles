;; -*- lexical-binding: t -*-

;; Shell-specific configuration, for both `sh-mode' and `bash-ts-mode'.
;; Inherits from prog-mode-hook.

(when (string-suffix-p ".ebuild" (buffer-file-name) t)
  ;; See https://devmanual.gentoo.org//ebuild-writing/file-format/index.html
  (message "sh-base-mode-hook: Applying ebuild-specific settings.")
  (setq-default indent-tabs-mode t)
  (setq-default tab-width 4))

;; Shell scripts are edited through Eglot (bash-language-server), for the
;; dialects that ShellCheck understands.
(when (memq sh-shell '(sh bash dash ksh))
  (eglot-ensure))
