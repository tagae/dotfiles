(flyspell-mode 1)

;; --- Editing aids

(when (require 'move-text nil 'recommended)
  (move-text-default-bindings))

(defun shift-region (distance)
  "Shift the selected region right if DISTANCE is postive, left if negative"
  (let ((mark (mark)))
    (save-excursion
      (indent-rigidly (region-beginning) (region-end) distance)
      (push-mark mark t t)
      (setq deactivate-mark nil))))

(defun shift-right ()
  (interactive)
  (shift-region 1))

(defun shift-left ()
  (interactive)
  (shift-region -1))

;; --- Key bindings

(local-set-key (kbd "M-,") 'shift-left)
(local-set-key (kbd "M-.") 'shift-right)
