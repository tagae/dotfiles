(erc-spelling-mode 1)

(erc-completion-mode 1)

(setq
 erc-prompt-for-password t
 erc-spelling-dictionaries
 '(("irc.eu.freenode.net" "british")
   ("#fu" "spanish"))
 erc-autojoin-channels-alist
 '(("freenode.net" "#emacs" "#slate" "#lisp" "#gentoo"))
 erc-pals
 '("azul" "novo" "galactus" "arhuaco")
 erc-keywords
 '("amos" "\\bseba[-a-z]*\\b")
 erc-track-exclude-types
 '("JOIN" "PART" "QUIT" "MODE" "NICK")
 erc-hide-list
 '("JOIN" "PART" "QUIT" "NICK"))

(defun irc ()
  "Connect to IRC."
  (interactive)
  (when (y-or-n-p "IRC? ")
    ;(load "erc-auth-tagae")
    (erc :server "irc.eu.freenode.net"
	 :port 6667
	 :nick "tagae"
	 :full-name user-full-name)))

