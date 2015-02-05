(setq ido-save-directory-list-file (expand-file-name "ido" emacs-state-dir)
      ido-enable-flex-matching t
      ;ido-use-filename-at-point 'guess
      ido-use-url-at-point t
      ido-show-dot-for-dired t
      ido-use-virtual-buffers 'auto
      ido-default-buffer-method 'selected-window)

(ido-everywhere 1) ; superseded by ido-ubiquitous if available

(when (require 'ido-at-point nil 'recommended)
  (ido-at-point-mode 1))

(when (require 'ido-ubiquitous nil 'recommended)
  (ido-ubiquitous-mode 1))

(when (require 'flx-ido nil 'recommended)
  (flx-ido-mode 1)
  (setq ido-use-faces nil)) ; see flx highlights
