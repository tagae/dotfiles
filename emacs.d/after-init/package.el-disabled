(when nil
	(defun ensure-installed (feature)
		(require 'package)
		(package-initialize)
		(unless package-archive-contents
			(package-refresh-contents))
		(unless (package-installed-p feature)
			(when (y-or-n-p (format "Install required package %s? " feature))
				(package-install feature)))))

(when nil
(advice-add 'require :around
	    (lambda (orig-require feature &optional filename noerror)
	      (or (apply orig-require feature filename 'noerror '())
		  noerror
		  (progn
		    (ensure-installed feature)
		    (apply orig-require feature filename noerror '())))))
)

(defun ensure-installed (feature)
	(unless (el-get-package-installed-p feature)
		(when (y-or-n-p (format "Install required package %s? " feature))
			(el-get-do-install feature))))

(advice-add 'require :around
						(lambda (orig-require feature &optional filename noerror)
							(or (apply orig-require feature filename 'noerror '())
									noerror
									(progn
										(ensure-installed feature)
										(apply orig-require feature filename noerror '())))))
