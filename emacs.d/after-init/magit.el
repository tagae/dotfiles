(global-set-key (kbd "C-c C-g") 'magit-status)
(global-set-key (kbd "C-c C-b") 'magit-blame-mode)

(setq
 ;; List of autocompletions if nothing in sight.
 magit-repo-dirs '("~/.dotfiles" "~/Projects")
 ;; Use ido to select options.
 magit-completing-read-function 'magit-ido-completing-read
 ;; Don't put "origin-" in front of new branch names by default.
 magit-default-tracking-name-function 'magit-default-tracking-name-branch-only
 ;; Open magit status in same window as current buffer.
 magit-status-buffer-switch-function 'switch-to-buffer
 ;; Highlight word/letter changes in hunk diffs.
 magit-diff-refine-hunk t
 ;; Ask me if I want to include a revision when rewriting.
 magit-rewrite-inclusive 'ask
 ;; Ask me to save buffers.
 magit-save-some-buffers t
 ;; Pop the process buffer if we're taking a while to complete.
 magit-process-popup-time 10
 ;; Ask me if I want a tracking upstream.
 magit-set-upstream-on-push t
 ;; Don't show " MRev" in modeline.
 magit-auto-revert-mode-lighter "")
