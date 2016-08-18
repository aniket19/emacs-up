;;; init.el --- Make Emacs useful!
;;; Author: Vedang Manerikar
;;; Created on: 10 Jul 2016
;;; Commentary:

;; This file is a bare minimum configuration file to enable working
;; with Emacs for Helpshift newcomers.

;;; Code:

(when (version< emacs-version "24.4")
  (error "Unsupported Emacs Version! Please upgrade to a newer Emacs.  Emacs installation instructions: https://www.gnu.org/software/emacs/download.html"))

(require 'package)

(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/")
             t)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/")
             t)

(package-initialize)
;; Pin certain packages to their stable versions. This needs to
;; happen before `package-refresh-contents' to work properly.
(add-to-list 'package-pinned-packages '(cider . "melpa-stable"))
(add-to-list 'package-pinned-packages '(clj-refactor . "melpa-stable"))

(unless package-archive-contents
  (package-refresh-contents))

(defvar hs-package-list
  (append
   (when (eq system-type 'darwin)
     '(exec-path-from-shell ; Emacs plugin for dynamic PATH loading
       ))
   '(better-defaults ; Fixing weird quirks and poor defaults
     company  ; Modular in-buffer completion framework for Emacs
     helm     ; Emacs incremental completion and narrowing framework
     avy      ; Jump to things in Emacs tree-style.
     paredit  ; Minor mode for editing parentheses
     magit    ; It's Magit! An Emacs mode for Git.
     cider    ; Clojure Interactive Development Environment that Rocks
     clj-refactor ; A collection of simple clojure refactoring functions
     zenburn-theme ; A low contrast color theme for Emacs.
     ))
  "List of packages to install on top of default Emacs.")

(dolist (p hs-package-list)
  (when (not (package-installed-p p))
    (package-install p)))

;; Modify the CMD key to be my Meta key
(setq mac-command-modifier 'meta)

;; Set a directory for temporary/state related files.
(defvar dotfiles-dirname
  (file-name-directory (or load-file-name
                           (buffer-file-name)))
  "The directory where this code is running from.
Ideally, this will be ~/.emacs.d.")
(defvar tempfiles-dirname
  (concat dotfiles-dirname "temp-files/")
  "A sub-directory to hold temporary files generated by Emacs.")

;; Create the temp-files folder if necessary.
(make-directory tempfiles-dirname t)

;;; Exec PATH from Shell - Fix Emacs's understanding of the the Path
;;; var on Mac.
(when (and (eq system-type 'darwin)
           (eq window-system 'ns))
  (require 'exec-path-from-shell)
  (exec-path-from-shell-initialize))

(require 'better-defaults)

;; Move Emacs state into the temp folder we've created.
(setq ido-save-directory-list-file (concat tempfiles-dirname "ido.last")
      recentf-save-file (concat tempfiles-dirname "recentf")
      save-place-file (concat tempfiles-dirname "places")
      backup-directory-alist `(("." . ,(concat tempfiles-dirname "backups"))))

;; `visible-bell' is broken on Emacs 24 downloaded from Mac for OSX
(when (< emacs-major-version 25)
  (setq visible-bell nil))

;;; Interactively Do Things
;; basic ido settings
(require 'ido)

(ido-mode t)
(ido-everywhere)
(setq ido-enable-flex-matching t
      ido-use-virtual-buffers t
      ido-create-new-buffer 'always
      ido-use-filename-at-point t)
(add-hook 'ido-make-buffer-list-hook 'ido-summary-buffers-to-end)

;; Ido power user settings
(defadvice completing-read
    (around ido-steroids activate)
  "IDO on steroids :D from EmacsWiki."
  (if (boundp 'ido-cur-list)
      ad-do-it
    (setq ad-return-value
          (ido-completing-read
           prompt
           (all-completions "" collection predicate)
           nil require-match initial-input hist def))))

;;; Company - complete anything
(require 'company)
;; Enable company everywhere
(add-hook 'after-init-hook 'global-company-mode)
(setq-default company-lighter " cmp")
(define-key company-active-map [tab] 'company-complete)
(define-key company-active-map (kbd "TAB") 'company-complete)

;;; Helm - Handy completion and narrowing
;; Explicitly turn off global `helm-mode'
(require 'helm-config)
(helm-mode -1)

;; Various useful key-bindings (other than Helm Defaults)
(global-set-key (kbd "C-x c r") nil) ; unset this because I plan to
                                        ; use it as a prefix key.
(global-set-key (kbd "C-x c r b") 'helm-filtered-bookmarks)
(global-set-key (kbd "C-x c r r") 'helm-regexp)
(global-set-key (kbd "C-x c C-b") 'helm-mini)
(global-set-key (kbd "M-y") 'helm-show-kill-ring)
(global-set-key (kbd "C-x c SPC") 'helm-all-mark-rings)
(global-set-key (kbd "C-h SPC") 'helm-all-mark-rings)
(global-set-key (kbd "C-x c r i") 'helm-register)
;; Useful defaults: C-x c i, C-x c I

;;; Avy
(require 'avy)
(global-set-key (kbd "M-g g") 'avy-goto-line)
(global-set-key (kbd "M-g SPC") 'avy-goto-word-1)
(avy-setup-default)

;;; Paredit
(eval-after-load 'paredit
  '(progn
     ;; `(kbd "M-s")' is a prefix key for a bunch of search related
     ;; commands by default. I want to retain this.
     (define-key paredit-mode-map (kbd "M-s") nil)))
(add-hook 'emacs-lisp-mode-hook 'enable-paredit-mode)
(eval-after-load 'clojure-mode
  '(progn (add-hook 'clojure-mode-hook 'enable-paredit-mode)))
(eval-after-load 'cider-repl
  '(progn (add-hook 'cider-repl-mode-hook 'enable-paredit-mode)
          (define-key cider-repl-mode-map (kbd "C-M-q") 'prog-indent-sexp)
          (define-key cider-repl-mode-map (kbd "C-c M-o")
            'cider-repl-clear-buffer)))

;;; Magit
;; Provide a global keybinding for Magit
(global-set-key (kbd "C-x g") 'magit-status)

;;; Cider
(eval-after-load 'cider-mode
  '(progn
     (defun cider-repl-prompt-on-newline (ns)
       "Return a prompt string with newline.
NS is the namespace information passed into the function by
cider."
       (concat ns ">\n"))

     (setq cider-repl-history-file (concat tempfiles-dirname
                                           "cider-history.txt")
           cider-repl-history-size most-positive-fixnum
           cider-repl-wrap-history t
           cider-repl-prompt-function 'cider-repl-prompt-on-newline
           nrepl-buffer-name-separator "-"
           nrepl-buffer-name-show-port t
           nrepl-log-messages t
           cider-annotate-completion-candidates t
           cider-completion-annotations-include-ns 'always
           cider-show-error-buffer 'always
           cider-prompt-for-symbol nil)

     (add-hook 'cider-mode-hook 'eldoc-mode)))

;;; Clj Refactor
(eval-after-load 'clj-refactor
  '(progn
     (defun turn-on-clj-refactor ()
       (clj-refactor-mode 1)
       (cljr-add-keybindings-with-prefix "C-c m"))

     (setq cljr-favor-prefix-notation nil
           ; stops cljr from running tests when we connect to the repl
           cljr-eagerly-build-asts-on-startup nil)

     (eval-after-load 'clojure-mode
       '(progn
          (add-hook 'clojure-mode-hook 'turn-on-clj-refactor)))))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("40f6a7af0dfad67c0d4df2a1dd86175436d79fc69ea61614d668a635c2cd94ab" default)))
 '(package-selected-packages
   (quote
    (clj-refactor cider magit paredit avy helm company better-defaults exec-path-from-shell))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;;; Theme and Look
;; This should load after `custom-safe-themes' to avoid Emacs
;; panicking about whether it is safe or not.
(load-theme 'zenburn)


(provide 'init)
;;; init.el ends here
