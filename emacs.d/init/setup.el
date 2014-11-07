;; Ensure that all wanted packages are installed.
;; Use C-h P to see the description of any given package.

(defvar tagae/packages
  '(ag
    apache-mode
    auctex
    auto-complete
    better-defaults
    browse-kill-ring
    company
    company-auctex
    company-tern
    cyberpunk-theme
    deft
    diminish
    el-get
    elisp-slime-nav
    expand-region
    flatland-theme
    flycheck
    git-gutter
    golden-ratio
    goto-last-change
    guide-key
    helm
    hl-sexp
    idle-highlight-mode
    ido-ubiquitous
    iy-go-to-char ; try package-list-packages if not working here
    js2-mode
    magit
    markdown-mode
    multiple-cursors
    paredit
    rainbow-mode
    smart-forward
    smartparens
    smex
    smooth-scrolling
    solarized-theme
    switch-window
    tagedit
    undo-tree
    volatile-highlights
    whitespace)
  "List of requested packages.")

;; Add platform-specific packages.
(when (eq system-type 'darwin)
  (setq tagae/packages
        (append tagae/packages '(exec-path-from-shell))))

;; Proceed with installation.
(package-initialize)
(dolist (package tagae/packages)
  (unless (package-installed-p package)
    (package-install package)))
