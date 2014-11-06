;; Save point position between sessions
(require 'saveplace)
(setq-default save-place t)
(setq save-place-file (concat package-state-dir "saveplace"))
