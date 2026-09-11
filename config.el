;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-login-name "AlexxSap"
      user-mail-address "alexxandrsap@mail.ru")

(setq doom-font (font-spec :family "FiraCode Nerd Font" :size 16))

;; disable exit confirmation
(setq confirm-kill-emacs nil)

;; `load-theme' function. This is the default:
(setq doom-theme 'doom-gruvbox)

;; show relative row numbers
(setq display-line-numbers-type 'relative)

;; hide hidden files in tree
(setq treemacs-show-hidden-files nil)

;;instal lsp package
(require 'lsp-mode)

;; hooks for golang - format and add imports on save
(add-hook 'go-mode-hook #'lsp-deferred)
(defun lsp-go-install-save-hooks ()
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t))
(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)

;; keys for dired navigation
(evil-define-key 'normal dired-mode-map
  (kbd "l") 'dired-find-file
  (kbd "h") 'dired-up-directory)

;; comments
(map! "C-/" #'comment-line)

;; org settings
;; source code pretty
(setq org-src-fontify-natively t)

;; begin and end block smaller
;; (custom-set-faces
;; '(org-block-begin-line
;; ((t (:height 0.8 :extend t :weight bold))))
;; '(org-block-end-line
;; ((t (:height 0.8 :extend t :weight bold)))))

;; set headers size
(defun my-org-faces ()
  (set-face-attribute 'org-level-1 nil :height 1.2)
  (set-face-attribute 'org-level-2 nil :height 1.2)
  (set-face-attribute 'org-level-3 nil :height 1.2)
  (set-face-attribute 'org-level-4 nil :height 1.2))
(add-hook 'org-mode-hook #'my-org-faces)

;; hide Org markup indicators.
(after! org (setq org-hide-emphasis-markers t))

(map! :leader
      (:prefix ("t")
       :desc "pretty org mode" "o" #'+org-pretty-mode
       :desc "pretty marknown mode" "m" #'nb/markdown-unhighlight))
;; add create file key for dired
(map! :leader
      (:prefix ("f")
       :desc "create empty file" "t" #'dired-create-empty-file))

;; eshell toggle keys
(map! :leader
      :desc "Eshell"                 "e s" #'eshell
      :desc "Eshell popup toggle"    "e t" #'+eshell/toggle)

;; disable flymake - not support c++20 and 23
(setq flymake-start-on-flymake-mode nil)
(setq flymake-start-on-save-buffer nil)

(setq org-export-babel-evaluate nil)

;;this block replace standart #+begin_ and #+end_ blocks with some icons
(with-eval-after-load 'org
  (defvar-local rc/org-at-src-begin -1
    "Variable that holds whether last position was a ")

  (defvar rc/ob-header-symbol ?☰
    "Symbol used for babel headers")

  (defun rc/org-prettify-src--update ()
    (let ((case-fold-search t)
          (re "^[ \t]*#\\+begin_src[ \t]+[^ \f\t\n\r\v]+[ \t]*")
          found)
      (save-excursion
        (goto-char (point-min))
        (while (re-search-forward re nil t)
          (goto-char (match-end 0))
          (let ((args (org-trim
                       (buffer-substring-no-properties (point)
                                                       (line-end-position)))))
            (when (org-string-nw-p args)
              (let ((new-cell (cons args rc/ob-header-symbol)))
                (cl-pushnew new-cell prettify-symbols-alist :test #'equal)
                (cl-pushnew new-cell found :test #'equal)))))
        (setq prettify-symbols-alist
              (cl-set-difference prettify-symbols-alist
                                 (cl-set-difference
                                  (cl-remove-if-not
                                   (lambda (elm)
                                     (eq (cdr elm) rc/ob-header-symbol))
                                   prettify-symbols-alist)
                                  found :test #'equal)))
        ;; Clean up old font-lock-keywords.
        (font-lock-remove-keywords nil prettify-symbols--keywords)
        (setq prettify-symbols--keywords (prettify-symbols--make-keywords))
        (font-lock-add-keywords nil prettify-symbols--keywords)
        (while (re-search-forward re nil t)
          (font-lock-flush (line-beginning-position) (line-end-position))))))

  (defun rc/org-prettify-src ()
    "Hide src options via `prettify-symbols-mode'.

  `prettify-symbols-mode' is used because it has uncollpasing. It's
  may not be efficient."
    (let* ((case-fold-search t)
           (at-src-block (save-excursion
                           (beginning-of-line)
                           (looking-at "^[ \t]*#\\+begin_src[ \t]+[^ \f\t\n\r\v]+[ \t]*"))))
      ;; Test if we moved out of a block.
      (when (or (and rc/org-at-src-begin
                     (not at-src-block))
                ;; File was just opened.
                (eq rc/org-at-src-begin -1))
        (rc/org-prettify-src--update))
      (setq rc/org-at-src-begin at-src-block)))

  (defun rc/org-prettify-symbols ()
    (mapc (apply-partially 'add-to-list 'prettify-symbols-alist)
          (cl-reduce 'append
                     (mapcar (lambda (x) (list x (cons (upcase (car x)) (cdr x))))
                             `(("#+begin_src" . ?✎) ;;
                               ("#+end_src"   .?✎) ;;
                               ("#+header:" . ,rc/ob-header-symbol)
                               ("#+begin_quote" . ?»)
                               ("#+end_quote" . ?«)))))
    (turn-on-prettify-symbols-mode)
    (add-hook 'post-command-hook 'rc/org-prettify-src t t))
  (add-hook 'org-mode-hook #'rc/org-prettify-symbols))

;; Org-mode spec
(add-hook 'org-mode-hook (lambda ()
                           (rc/org-prettify-symbols)))
(defun surround-word-with-quotes ()
  "Surround the word at point with double quotes."
  (interactive)
  (let ((bounds (bounds-of-thing-at-point 'symbol)))
    (when bounds
      (goto-char (car bounds))
      (insert "\"")
      (goto-char (+ 1 (cdr bounds)))
      (insert "\""))))
(global-set-key (kbd "C-c q") 'surround-word-with-quotes)

(defun surround-word-with-asterisk ()
  "Surround the word at point with asterisk."
  (interactive)
  (let ((bounds (bounds-of-thing-at-point 'symbol)))
    (when bounds
      (goto-char (car bounds))
      (insert "*")
      (goto-char (+ 1 (cdr bounds)))
      (insert "*"))))
(global-set-key (kbd "C-c a") 'surround-word-with-asterisk)

(defun surround-word-with-eq ()
  "Surround the word at point with =."
  (interactive)
  (let ((bounds (bounds-of-thing-at-point 'symbol)))
    (when bounds
      (goto-char (car bounds))
      (insert "=")
      (goto-char (+ 1 (cdr bounds)))
      (insert "="))))
(global-set-key (kbd "C-c e") 'surround-word-with-eq)

;; add image support. Press C-c C-c on line or M-x org-redisplay-inline-images
;; example
;; #+ATTR_ORG: :width 800 :height 400 :align center
;; [[file:/home/user/images/example.png]]
(setq org-startup-with-inline-images t)

;; hide/show code blocks
(global-set-key (kbd "C-c h") 'hs-hide-block)
(global-set-key (kbd "C-c s") 'hs-show-block)
(global-set-key (kbd "C-c H") 'hs-hide-all)
(global-set-key (kbd "C-c S") 'hs-show-all)

;; Install visual-fill-column
(unless (package-installed-p 'visual-fill-column)
  (package-install 'visual-fill-column))

;; Configure fill width
(setq visual-fill-column-width 110
      visual-fill-column-center-text t)

(defun my/org-present-start ()
  ;; Center the presentation and wrap lines
  (visual-fill-column-mode 1)
  (visual-line-mode 1))

(defun my/org-present-end ()
  ;; Stop centering the document
  (visual-fill-column-mode 0)
  (visual-line-mode 0))

;; maximize on startup
(add-hook 'window-setup-hook #'toggle-frame-maximized)

;; Register hooks with org-present
(add-hook 'org-present-mode-hook 'my/org-present-start)
(add-hook 'org-present-mode-quit-hook 'my/org-present-end)

;; haskell settings
;; lsp for haskell
(require 'lsp-haskell)
;; hooks for doc and indentation
(add-hook 'haskell-mode-hook 'turn-on-haskell-doc-mode)
(add-hook 'haskell-mode-hook 'turn-on-haskell-indentation)
(add-hook 'haskell-mode-hook #'lsp)
(add-hook 'haskell-literate-mode-hook #'lsp)
;; format on save
(setq haskell-stylish-on-save t)

;; Для Haskell включите проверку hlint
(add-hook 'haskell-mode-hook #'flycheck-mode)

