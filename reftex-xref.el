;;; reftex-xref.el --- xref and eldoc support for reftex  -*- lexical-binding: t; -*-

;; Copyright (C) 2024  Karthik Chikmagalur

;; Author: Karthik Chikmagalur <karthikchikmagalur@gmail.com>
;; Maintainer: Karthik Chikmagalur <karthikchikmagalur@gmail.com>
;; Version: 0.1.0
;; Keywords: tex, convenience
;; Homepage: https://github.com/karthink/reftex-xref

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; xref and eldoc support for RefTeX.  Use `reftex-eldoc-activate'and
;; `reftex-xref-activate' in a major-mode hook to enable them.

;;; Code:
(require 'xref)
(require 'reftex-ref)
; to use these function safely
(require 'auctex)
(declare-function LaTeX-outline-regexp "latex")
(declare-function LaTeX-find-matching-end "latex")
(declare-function LaTeX-find-matching-begin "latex")

(cl-defmethod xref-backend-identifier-at-point ((_backend (eql reftex)))
  (when (looking-back "\\\\\\(?:page\\|eq\\|auto\\|c\\)?ref{[-a-zA-Z0-9_*.:]*"
                                      (line-beginning-position))
		    (reftex-this-word "-a-zA-Z0-9_*.:")))

(cl-defmethod xref-backend-definitions ((_backend (eql reftex)) prompt)
  (unless (symbol-value reftex-docstruct-symbol) (reftex-parse-one))
  (when-let* ((docstruct (symbol-value reftex-docstruct-symbol))
              (data (assoc prompt docstruct))
              (label (nth 0 data))
              (file  (nth 3 data))
              (buffer (or (find-buffer-visiting file)
                          (reftex-get-file-buffer-force
                           file (not reftex-keep-temporary-buffers))))
              (re (format reftex-find-label-regexp-format (regexp-quote label)))
              (found (with-current-buffer buffer
                       (or (re-search-backward re nil t)
                           (re-search-forward re nil t)
                           (save-excursion
                             (goto-char (point-min))
                             (re-search-forward
                              (format reftex-find-label-regexp-format2
                                      (regexp-quote label))
                                   nil t))))))
    (list (xref-make prompt (xref-make-buffer-location
                             buffer found)))))

(cl-defmethod xref-backend-apropos ((_backend (eql reftex)) pattern)
  (xref-backend-definitions 'reftex pattern))

(defun reftex-xref ()
  "Function to activate buffer-local backend.
Add this function to `xref-backend-functions' to use xref to find
function and variable definitions in the same buffer.
This should have a low priority among xref backends."
  'reftex)

;; Eldoc support via xref, because why not
(defun reftex-xref--display-in-eldoc (callback)
  "Display reference label location in Eldoc.
Call CALLBACK if possible."
  (when (cl-intersection
         (ensure-list (get-text-property (point) 'face))
         '(font-lock-keyword-face font-lock-constant-face
           TeX-fold-unfolded-face))
    (save-excursion
      (when-let*
          ((inhibit-redisplay t)
           ((car (reftex-what-macro-safe 1)))
           (key (reftex-this-word "^{}%\n\r, \t"))
           (item (car (xref-backend-definitions 'reftex key)))
           (location (xref-item-location item))
           (pos (xref-buffer-location-position location))
           (docstring
            (with-current-buffer (xref-buffer-location-buffer location)
              (goto-char pos)
              (pcase-let
                  ((`(,start . ,end)
                    (condition-case nil
                        (LaTeX-find-matching-begin)
                      (:success
                       ;; Found \begin{}...\end{}
                       (cons (point)
                             (progn (forward-char 1)
                                    (LaTeX-find-matching-end)
                                    (point))))
                      (error
                       ;; No \begin, find \section{} or Org heading instead
                       (goto-char pos)
                       (re-search-backward
                        (pcase major-mode
                          ('org-mode "^*")
                          (_ (concat "\\(" (LaTeX-outline-regexp)
                                     "\\|\\`\\)")))
                        (line-beginning-position -2)
                        t)
                       (cons (line-beginning-position)
                             (line-end-position))))))
                (buffer-substring-no-properties start end)))))
        (if-let* ((prop-and-ov
                   (get-char-property-and-overlay
                    (xref-buffer-location-position location)
                    (pcase major-mode
                      ('org-mode 'org-overlay-type)
                      ('latex-mode 'category))))
                  ((memq (car prop-and-ov)
                           '(org-latex-overlay preview-overlay)))
                  (ov (cdr prop-and-ov)))
            (funcall callback (propertize docstring 'display
                                          (overlay-get ov 'preview-image)))
          (funcall callback docstring))))))

(defun reftex-eldoc-activate ()
  (add-hook 'eldoc-documentation-functions
            'reftex-xref--display-in-eldoc
            nil :local))

(defun reftex-xref-activate ()
  "Activate reftex support using xref."
  (add-hook 'xref-backend-functions
            'reftex-xref nil :local))

(provide 'reftex-xref)
;;; reftex-xref.el ends here
