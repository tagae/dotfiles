;;; See http://www.masteringemacs.org/article/mastering-key-bindings-emacs


;;; ---[ Default configuration ]---

;;; Getting help.

;; C-h C-h : help on the C-h prefix
;; C-h m : describe mode
;; C-h b : describe all keybindings
;; C-h c : briefly describe command run by given key sequence
;; C-h k : fully describe command run by given key sequence
;; <prefix> C-h : get a list of all keys that belong to that prefix
;; C-h n : Emacs news -summary of user-visible changes

;; Advanced.

;; C-u M-x apropos-variable RET -mode-hook$ RET : show known mode hooks

;;; Executing commands.

;; M-x : run command
;; M-: : eval expression


;;; ---[ Overriding of default bindings ]---

(global-unset-key (kbd "C-x C-z")) ; useless duplicate of C-z

(global-set-key (kbd "M-/") 'hippie-expand)
(global-set-key (kbd "C-x C-b") 'ibuffer)

;(global-set-key (kbd "C-s") 'isearch-forward-regexp)
;(global-set-key (kbd "C-r") 'isearch-backward-regexp)
;(global-set-key (kbd "C-M-s") 'isearch-forward)
;(global-set-key (kbd "C-M-r") 'isearch-backward)

;; Transpose stuff with M-t.
(global-unset-key (kbd "M-t")) ; which used to be transpose-words
(global-set-key (kbd "M-t l") 'transpose-lines)
(global-set-key (kbd "M-t p") 'transpose-params)
(global-set-key (kbd "M-t s") 'transpose-sexps)
(global-set-key (kbd "M-t w") 'transpose-words)

;; Instead of set-fill-column.
(global-set-key (kbd "C-x f") 'recentf-open-files)


;;; ---[ Extension of existing command prefixes ]---

(define-key 'help-command (kbd "C-i") 'info-display-manual) ;; C-h C-i

;; Complement to zap-to-char that leaves the target character untouched.
(global-set-key (kbd "M-Z") 'zap-up-to-char)

(autoload 'zap-up-to-char "misc" ; not provided by default
  "Kill up to, but not including ARGth occurrence of CHAR." t)

;; Move through buffers with arrow keys.
;(global-set-key (kbd "S-M-<left>") '(lambda () (interactive) (other-window -1)))
;(global-set-key (kbd "S-M-<right>") '(lambda () (interactive) (other-window 1)))


;;; ---[ Personal customisations ]---

;; Reserved for personal use
;; (though many packages won't respect these conventions):
;;
;; C-c ? : where ? is a single character
;; <Fx> : function keys for x >= 5

;; Handy when coding in any programming language.
;;(global-set-key (kbd "C-c ;") 'comment-dwim) ; already in M-;
;;(global-set-key (kbd "RET") 'newline-and-indent)

;; Line editing (C-c l).
(global-set-key (kbd "C-c l s") 'sort-lines) ; 'sort'
(global-set-key (kbd "C-c l u") 'delete-duplicate-lines) ; 'uniq'

;; Turn on the menu bar for exploring new modes.
(global-set-key (kbd "C-<f10>") 'menu-bar-mode)


;;; ---[ Package-specific customisations ]---

(global-set-key [f6] 'ispell-word)
(global-set-key [(meta f6)] 'ispell-region)
(global-set-key [(control f6)] 'ispell-buffer)

(global-set-key (kbd "C-c j d") 'dired-jump) ; 'jump directory'
(global-set-key (kbd "C-c j 4 d") 'dired-jump-other-window) ; 4 is convention for 'other window'

;; Autoloads not provided before dired-x package is loaded.

(autoload 'dired-jump "dired-x"
  "Jump to Dired buffer corresponding to current buffer." t)

(autoload 'dired-jump-other-window "dired-x"
  "Like dired-jump but in other window." t)

(global-set-key (kbd "C-c j b") 'ace-jump-buffer) ; 'buffer'
(global-set-key (kbd "C-c j W") 'ace-window) ; 'window'
