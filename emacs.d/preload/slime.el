;(require 'slime-autoloads nil 'noerror)
(when (load "slime-autoloads" t)
  (setq slime-auto-connect 'always)
  (slime-setup '(slime-fancy slime-asdf inferior-slime)))
