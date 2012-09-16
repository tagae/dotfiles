;;(add-to-list 'load-path (file-name-directory load-file-name))

(defun dotfiles-message (type msg &rest objects)
  (message
   (car
    (split-string
     (shell-command-to-string
      (format "source ~/.dotfiles/bin/lib/interaction.sh; %s %s"
              type (shell-quote-argument (apply 'format msg objects))))
     "[\n\r]"))))
