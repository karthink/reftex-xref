;; -*- lexical-binding: t; -*-

(TeX-add-style-hook
 "second"
 (lambda ()
   (setq TeX-command-extra-options
         "-shell-escape")
   (LaTeX-add-labels
    "sec:third"
    "eq:equation"
    "sec:fourth"
    "fig:figure1"))
 :latex)

