(add-to-list 'TeX-command-list
             '("XeLaTeX" "%`xelatex --synctex=1 %(mode)%' %t"
               TeX-run-TeX nil (latex-mode context-mode)
               :help "Run XeLaTeX with SyncTeX")
             t)
