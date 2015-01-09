(defun sg:archive-decompile-class-hook ()
  "Automatically decompile classfiles found in archive (jar) files."
  (when (string-match "\.class$" buffer-file-name)
    (jdc-buffer)))

;;(add-hook 'archive-extract-hook 'sg:archive-decompile-class-hook)
