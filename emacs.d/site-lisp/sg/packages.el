(require 'sg/symbols)

;; --- Package blacklisting

(defun sg:load-unwanted-package-list ()
  (when (file-exists-p sg:unwanted-packages-file)
    (sg:read-symbols sg:unwanted-packages-file)))

(defun sg:save-unwanted-package-list ()
  (when sg:unwanted-packages
    (sg:write-symbols sg:unwanted-packages-file sg:unwanted-packages)))

(defvar sg:unwanted-packages-file
  (expand-file-name "unwanted-packages" emacs-state-dir)
  "File in which unwanted package information is recorded.")

(defvar sg:unwanted-packages (sg:load-unwanted-package-list)
  "List of packages the user does not want to see installed.")

;; Save list of unwanted packages on exit.
(add-hook 'kill-emacs-hook #'sg:save-unwanted-package-list)

;; --- Package recommendation

(defun sg:recommend-package (package)
  "Install PACKAGE if unavailable."
  (or (package-installed-p package)
      (unless (memq package sg:unwanted-packages)
        (unless package-archive-contents
          (package-refresh-contents))
        (if (assoc package package-archive-contents)
            (if (y-or-n-p (format "Install recommended package '%s'? " package))
                (progn
                  (package-install package)
                  (delete-other-windows))
              (add-to-list 'sg:unwanted-packages package))
          (message "Cannot recommend unknown package %s." package))
        (package-installed-p package))))

(provide 'sg/packages)
