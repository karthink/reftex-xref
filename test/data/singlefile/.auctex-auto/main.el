;; -*- lexical-binding: t; -*-

(TeX-add-style-hook
 "main"
 (lambda ()
   (setq TeX-command-extra-options
         "-shell-escape")
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("article" "")))
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("amsmath" "")))
   (TeX-run-style-hooks
    "latex2e"
    "article"
    "art10"
    "amsmath")
   (LaTeX-add-labels
    "sec:first"
    "eq:eqnarray"
    "sec:second"
    "eq:align"
    "eq:equation"))
 :latex)

