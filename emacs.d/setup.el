(package-initialize)
(dolist (feature '(
                   ag
                   apache-mode
                   auctex
                   auto-complete
                   better-defaults
                   browse-kill-ring
                   company
                   company-auctex
                   company-tern
                   cyberpunk-theme
                   diminish
                   el-get
                   expand-region
                   flatland-theme
                   git-gutter
                   golden-ratio
                   goto-last-change
                   guide-key
                   hl-sexp
                   idle-highlight-mode
                   ido-ubiquitous
                   iy-go-to-char ; try package-list-packages if not working here
                   js3-mode
                   magit
                   markdown-mode
                   multiple-cursors
                   paredit
                   smart-forward
                   smex
                   smooth-scrolling
                   solarized-theme
                   switch-window
                   undo-tree
                   whitespace
                   ))
  (unless (package-installed-p feature)
    (package-install feature)))

(when (eq 'darwin system-type)
  (dolist (feature '(
                     exec-path-from-shell
                     ))
    (unless (package-installed-p feature)
    (package-install feature))))
