(require 'epg)

(defcustom epg-gpg-program-prefix
  (file-name-directory
     (directory-file-name
        (file-name-directory
           (file-truename epg-gpg-program))))
  "Directory prefix used for installation of `epg-gpg-program'.")

(defcustom epg-gpg-preset-passphrase-program
  (concat epg-gpg-program-prefix "libexec/gpg-preset-passphrase")
  "Name of GnuPG 2's `gpg-preset-passphrase'.")

(defun epg-passphrase-start-process (action sub-key)
  (let ((process (start-process
                    "GnuPG 2 passphrase" "*epg passphrase*"
                    epg-gpg-preset-passphrase-program
                    (concat "--" (symbol-name action))
                    (epg-sub-key-fingerprint sub-key))))
    ;(set-process-filter process #'epg--passphrase-process-filter)
    process))

(defun epg--passphrase-process-filter (process input)
  (if (buffer-live-p (process-buffer process))
      (with-current-buffer (process-buffer process)
        (goto-char (point-max))
        (insert input))))

(defun epg-sub-key-preset-passphrase (context sub-key)
  (let ((process (epg-passphrase-start-process 'preset sub-key))
        (prompt (format "Passphrase for key %s: " (epg-sub-key-id sub-key))))
    (process-send-string process (read-passwd prompt))
    (process-send-eof process)))

(defun epg-sub-key-forget-passphrase (context sub-key)
  (epg-passphrase-start-process 'forget sub-key))

(defun epg-key-cache-sub-key-passphrases (context key-id)
  (loop
     for key in (epg-list-keys context key-id 'secret)
     do (loop
           for sub-key in (epg-key-sub-key-list key)
           when (member 'encrypt (epg-sub-key-capability sub-key))
           do
             (epg-sub-key-preset-passphrase context sub-key))))

;;(epg-key-cache-sub-key-passphrases (epg-make-context) "sgm")
