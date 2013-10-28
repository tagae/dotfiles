(defun string-starts-with (s prefix)
  "Returns non-nil if string S starts with PREFIX."
  (let ((prelen (length prefix)))
    (or (= prelen 0)
        (and (>= (length s) prelen)
             (string-equal (substring s 0 prelen) prefix)))))

(defun string-ends-with (s suffix)
  "Return non-nil if string S ends with SUFFIX."
  (let ((sufflen (length suffix)))
    (or (= sufflen 0)
        (and (>= (length s) sufflen)
             (string-equal (substring s (- sufflen)) suffix)))))
