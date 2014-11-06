;; xrdb-mode can be installed through el-get.

(add-to-list 'auto-mode-alist '("Xdefaults\\'" . xrdb-mode))
(add-to-list 'auto-mode-alist '("Xenvironment\\'" . xrdb-mode))
(add-to-list 'auto-mode-alist '("Xresources\\'" . xrdb-mode))
(add-to-list 'auto-mode-alist '("Xresources.d/.+\\'" . xrdb-mode))
(add-to-list 'auto-mode-alist '("*.\\.ad$" . xrdb-mode))
