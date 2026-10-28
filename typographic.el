;;; typographic.el --- Buffer-local serif/sans prose typography -*- lexical-binding: t; -*-

;; Author: Akane
;; Keywords: faces, fonts

;;; Commentary:
;; Serif/sans prose modes (body → variable-pitch, code → fixed-pitch).
;; Global mono/CJK: set with Emacs built-ins.
;; Optional no-italic / no-bold: call `typographic-setup-mono-faces'
;; after theme load when needed (not automatic).
;; See README.org.

;;; Code:

(require 'face-remap)

(defgroup typographic nil
  "Buffer-local serif/sans prose typography."
  :group 'faces
  :prefix "typographic-")

(defcustom typographic-serif-latin nil
  "Serif Latin family for `typographic-serif-mode'."
  :type '(choice (const nil) string)
  :group 'typographic)

(defcustom typographic-serif-cjk nil
  "Serif CJK family for `typographic-serif-mode'."
  :type '(choice (const nil) string)
  :group 'typographic)

(defcustom typographic-sans-latin nil
  "Sans Latin family for `typographic-sans-mode'."
  :type '(choice (const nil) string)
  :group 'typographic)

(defcustom typographic-sans-cjk nil
  "Sans CJK family for `typographic-sans-mode'."
  :type '(choice (const nil) string)
  :group 'typographic)

(defcustom typographic-no-italic-font nil
  "Family string matching `default': force normal slant on mono faces."
  :type '(choice (const nil) string)
  :group 'typographic)

(defcustom typographic-no-bold-font nil
  "Family string matching `default': force normal weight on mono faces."
  :type '(choice (const nil) string)
  :group 'typographic)

(defcustom typographic-fixed-faces
  '(org-block org-code org-verbatim org-table org-table-row org-formula
    org-link org-special-keyword org-meta-line org-checkbox org-priority
    org-todo org-done org-ellipsis org-tag org-date org-document-info-keyword
    org-hide org-property-value org-drawer
    markdown-ts-latex markdown-ts-code-block markdown-ts-code-span
    markdown-ts-code-block-markup-hidden
    markdown-ts-indented-code-block markdown-ts-in-code-block
    markdown-ts-table markdown-ts-in-table
    markdown-ts-delimiter markdown-ts-link markdown-ts-link-destination
    markdown-ts-appear-table markdown-ts-appear-table-header
    markdown-ts-appear-table-cell markdown-ts-appear-table-border
    markdown-ts-appear-mathjax-source
    line-number)
  "Faces remapped to `fixed-pitch' in prose modes."
  :type '(repeat face)
  :group 'typographic)

(defvar-local typographic--cookies nil)
(defconst typographic--leading-ws '("^[[:space:]]+" 0 'fixed-pitch))

(defconst typographic--italic-faces
  '(font-lock-preprocessor-face font-lock-type-face font-lock-comment-face
    font-lock-keyword-face font-lock-builtin-face))

(defconst typographic--bold-faces
  '(font-lock-keyword-face font-lock-function-name-face font-lock-type-face
    font-lock-constant-face font-lock-builtin-face font-lock-warning-face))

;;;###autoload
(defun typographic-available-p (family)
  "Return non-nil if font FAMILY is installed."
  (and (stringp family) (find-font (font-spec :family family))))

(defun typographic--fontset (tag)
  "Return fontset for TAG (TAG must not contain hyphens)."
  (let ((name (concat "fontset-typographic" tag)))
    (unless (member name (fontset-list))
      (create-fontset-from-fontset-spec
       (format "-*-*-*-*-*-*-*-*-*-*-*-*-fontset-typographic%s" tag)))
    name))

;;;###autoload
(defun typographic-setup-mono-faces ()
  "Strip synthetic italic/bold from mono faces when `default' matches.
Call after theme load if `typographic-no-italic-font' or
`typographic-no-bold-font' is set.  Not run automatically."
  (when (display-graphic-p)
    (let ((family (face-attribute 'default :family nil 'default)))
      (when (and (stringp typographic-no-italic-font)
                 (equal family typographic-no-italic-font))
        (dolist (face typographic--italic-faces)
          (set-face-attribute face nil :slant 'normal)))
      (when (and (stringp typographic-no-bold-font)
                 (equal family typographic-no-bold-font))
        (dolist (face typographic--bold-faces)
          (set-face-attribute face nil :weight 'normal))))))

;;; Prose modes

(defvar typographic-serif-mode)
(defvar typographic-sans-mode)

(defun typographic--teardown-prose ()
  "Remove prose remaps from the current buffer."
  (when typographic--cookies
    (mapc #'face-remap-remove-relative typographic--cookies)
    (setq typographic--cookies nil)
    (font-lock-remove-keywords nil (list typographic--leading-ws))
    (variable-pitch-mode -1)
    (font-lock-flush)))

(defun typographic--activate-prose (latin cjk tag)
  "Enable prose with LATIN/CJK under fontset TAG."
  (typographic--teardown-prose)
  (let ((fontset (typographic--fontset tag)))
    (when (typographic-available-p cjk)
      (set-fontset-font fontset 'han cjk)
      (set-fontset-font fontset 'kana cjk))
    (when (typographic-available-p latin)
      (set-face-attribute 'variable-pitch nil
                          :family latin
                          :fontset fontset)))
  (variable-pitch-mode 1)
  (setq typographic--cookies
        (mapcar (lambda (face)
                  (face-remap-add-relative face 'fixed-pitch))
                typographic-fixed-faces))
  (font-lock-add-keywords nil (list typographic--leading-ws) 'append)
  (font-lock-flush))

;;;###autoload
(define-minor-mode typographic-serif-mode
  "Prose mode (serif): body in variable pitch, code in fixed pitch."
  :lighter " Serif"
  :group 'typographic
  (if typographic-serif-mode
      (progn
        (setq typographic-sans-mode nil)
        (typographic--activate-prose
         typographic-serif-latin typographic-serif-cjk "serif"))
    (typographic--teardown-prose)))

;;;###autoload
(define-minor-mode typographic-sans-mode
  "Prose mode (sans): body in variable pitch, code in fixed pitch."
  :lighter " Sans"
  :group 'typographic
  (if typographic-sans-mode
      (progn
        (setq typographic-serif-mode nil)
        (typographic--activate-prose
         typographic-sans-latin typographic-sans-cjk "sans"))
    (typographic--teardown-prose)))

(provide 'typographic)
;;; typographic.el ends here
