(defun sg:read-symbols (path)
  "Return the list of symbols contained in file PATH."
  (mapcar 'intern (with-temp-buffer
                    (insert-file-contents path)
                    (split-string (buffer-string)))))

(defun sg:write-symbols (path symbols)
  "Writes one symbol name per line to the given PATH."
  (with-temp-file path
    (mapc (lambda (symbol) (insert (symbol-name symbol)) (insert "\n"))
          symbols)))

(provide 'sg/symbols)
