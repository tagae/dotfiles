(when (featurep 'package)

  (require 'sg/elisp-files)
  (require 'sg/packages)

  ;; Library-specific initialisation.
  (sg:with-elisp-files "after-init/" library-setup
                       (let ((library (file-name-base library-setup)))
                         (when (sg:recommend-package (intern library))
                           (load library-setup)))))
