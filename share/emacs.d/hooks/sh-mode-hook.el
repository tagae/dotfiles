(when (string-suffix-p ".ebuild" (buffer-file-name) t)
  ;; See https://devmanual.gentoo.org//ebuild-writing/file-format/index.html
  (message "sh-mode-hook: Applying ebuild-specific settings.")
  (setq-default indent-tabs-mode t)
  (setq-default tab-width 4))
