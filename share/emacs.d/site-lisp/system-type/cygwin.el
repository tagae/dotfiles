(defun cygwin-explore (&optional path)
  "Find the current buffer in Windows explorer.exe"
  (interactive)
  (if path
      (shell-command (concat "explorer.exe /e,/select, \"$(cygpath -w \"" path "\")\""))
      (cond
        ((buffer-file-name)
         (cygwin-explore buffer-file-name))
        ((eq major-mode 'dired-mode)
         (cygwin-explore (dired-current-directory)))
        (t
         (cygwin-explore default-directory)))))

(global-set-key (kbd "C-c j D") 'cygwin-explore) ; 'jump directory'
