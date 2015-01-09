(defun pinentry (desc prompt ok error)
  "Requests a passphrase from the user for use by GnuPG."
  (let* ((desc1 (replace-regexp-in-string "%0A" "\n" desc))
         (desc2 (replace-regexp-in-string "%22" "\"" desc1))
         (prompt (concat desc2 prompt ": ")))
    (read-passwd prompt)))
