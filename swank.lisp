(require :asdf)

#+asdf
(pushnew "/Users/tagae/.asdf-install-dir/systems/"
         asdf:*central-registry*
         :test #'equalp)
