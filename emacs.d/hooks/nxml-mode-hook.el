(setq nxml-slash-auto-complete-flag t)

(custom-set-faces
 '(nxml-text-face ((t (:foreground "snow3"))))
 '(nxml-entity-ref-name-face ((t (:foreground "salmon1"))))
 '(nxml-entity-ref-delimiter-face ((t (:foreground "goldenrod"))))
 '(nxml-delimiter-face ((t (:foreground "ivory3"))))
 '(nxml-element-local-name-face ((t (:inherit nxml-name-face :foreground "coral3"))))
 '(nxml-name-face ((t (:foreground "coral"))))
 '(nxml-attribute-value-face ((t (:foreground "bisque2"))))
 '(nxml-prolog-literal-content-face ((t (:foreground "orange2")))))

(message "Loaded tagae's nXML config")
