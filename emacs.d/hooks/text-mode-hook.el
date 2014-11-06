(flyspell-mode)

;; Pairwise insertion
(setq skeleton-pair t)
(local-set-key (kbd "[") 'skeleton-pair-insert-maybe)
(local-set-key (kbd "(") 'skeleton-pair-insert-maybe)
(local-set-key (kbd "{") 'skeleton-pair-insert-maybe)
(local-set-key (kbd "<") 'skeleton-pair-insert-maybe)

;;; Editing aids

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

(defun move-line (&optional n)
	"Move current line N (1) lines up/down leaving point in place."
	(interactive "p")
	(when (null n)
		(setq n 1))
	(let ((col (current-column)))
		(beginning-of-line)
		(next-line 1)
		(transpose-lines n)
		(previous-line 1)
		(forward-char col)))

(defun move-line-up (n)
	"Moves current line N (1) lines up leaving point in place."
	(interactive "p")
	(move-line (if (null n) -1 (- n))))

(defun move-line-down (n)
	"Moves current line N (1) lines down leaving point in place."
	(interactive "p")
	(move-line (if (null n) 1 n)))

(local-set-key [(meta \,)] 'shift-left)
(local-set-key [(meta .)] 'shift-right)
(local-set-key [(meta up)] 'move-line-up)
(local-set-key [(meta down)] 'move-line-down)
