;; -*- lexical-binding: t -*-

;; Tcl-specific configuration.
;; Inherits from prog-mode-hook.

;; Tcl scripts are edited through Eglot (tcl-ls), when it is installed.
;; The server runs `tclsh' to learn about commands, so that must be on the
;; `exec-path' too.
(when (and (executable-find "tcl-ls") (executable-find "tclsh"))
  (eglot-ensure)

  ;; tcl-ls puts the signature of a command in its hover text, and answers a
  ;; signature request with the same signature, so that Eglot shows it twice
  ;; in the echo area.  Eglot reads this variable when it asks, buffer by
  ;; buffer, so the other servers keep their signature help.
  (setq-local eglot-ignored-server-capabilities
              (cons :signatureHelpProvider eglot-ignored-server-capabilities)))
