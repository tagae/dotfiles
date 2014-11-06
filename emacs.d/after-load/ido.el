(setq
 ido-save-directory-list-file (concat package-state-dir "ido")
 ido-use-filename-at-point 'guess
 ido-use-url-at-point t
 ido-show-dot-for-dired t
 ido-use-virtual-buffers 'auto
 ido-default-buffer-method 'selected-window)

; superseded by ido-ubiquitous
;(ido-everywhere 1)


