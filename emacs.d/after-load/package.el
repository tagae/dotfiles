(when (boundp 'package-archives)
  (add-to-list 'package-archives
    '("ELPA" . "http://tromey.com/elpa/"))
  (add-to-list 'package-archives
    '("marmalade" . "http://marmalade-repo.org/packages/"))
  (add-to-list 'package-archives
    '("melpa" . "http://melpa.milkbox.net/packages/")))
