(setq ispell-program-name "aspell")
(setq ispell-dictionary "british")

(global-set-key [f6] 'ispell-word)
(global-set-key [(meta f6)] 'ispell-region)
(global-set-key [(control f6)] 'ispell-buffer)

(local-set-key [(meta shift tab)] 'ispell-complete-word)
