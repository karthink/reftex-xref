;; -*- lexical-binding: t; -*-

(TeX-add-style-hook
 "first"
 (lambda ()
   (setq TeX-command-extra-options
         "-shell-escape")
   (LaTeX-add-labels
    "sec:first"
    "eq:eqnarray"
    "sec:second"
    "eq:align"))
 :latex)

