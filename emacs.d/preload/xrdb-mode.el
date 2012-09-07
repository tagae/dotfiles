;; See http://www.python.org/emacs/xrdb-mode.el

(autoload 'xrdb-mode "xrdb-mode" "Mode for editing X resource files." t)

(add-to-list 'auto-mode-alist '("\\.Xdefaults\\'" . xrdb-mode))
(add-to-list 'auto-mode-alist '("\\.Xenvironment\\'" . xrdb-mode))
(add-to-list 'auto-mode-alist '("\\.Xresources\\'" . xrdb-mode))
