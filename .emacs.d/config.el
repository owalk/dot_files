
;; Meta

;;    Let's see how long everything takes to load.

(defconst emacs-start-time (current-time))

;; Emacs starts up by loading init.el. Thanks to the wonders of =org babel=, I can keep all of my
;;    configuration in this file and load it from init.el with a single function, shown below.

;; (org-babel-load-file "~/.emacs.d/config.org")

;; I'm adding code blocks to this file all the time. Org-mode provides a few
;;    [[http://orgmode.org/manual/Easy-Templates.html][structure templates]] for quickly adding new blocks, but I can make it even
;;    better. Everything in here is Emacs lisp, so let's alter the source code
;;    template a bit when I'm in this file.

(defun ow/init-org-elisp-template ()
   (when (equal (buffer-file-name)
                "/home/.dotfiles/emacs.d/config.org")
      (setq-local org-structure-template-alist
                  '(("s" "#+BEGIN_SRC emacs-lisp\n?\n#+END_SRC" "<src lang="emacs lisp">\n?\n</src>")))))

(add-hook 'org-mode-hook 'ow/init-org-elisp-template)

;; Package Setup

;;    Managing extensions for Emacs is simplified using =package= which is
;;    built in to Emacs 24 and newer. To load downloaded packages we need to
;;    initialize =package=. =cl= is a library that contains many functions from
;;    Common Lisp, and comes in handy quite often, so we want to make sure it's
;;    loaded, along with =package=, which is obviously needed.

(require 'cl)
(require 'package)
(setq package-enable-at-startup nil)
(package-initialize)

;; Packages can be fetched from different mirrors, [[http://melpa.org][melpa]] is the largest
;;    archive and is well maintained.

(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("MELPA" . "https://melpa.org/packages/")))

;; I use the great and powerful =use-package= to keep package configuration simple.
;;     We just need to bootstrap =use-package= by ensuring it's installed first.

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package)
  (package-install 'diminish))

(eval-when-compile
  (require 'use-package))
(require 'diminish)
(require 'bind-key)

;; Package List

;;     Still need to organize these.

(use-package ac-octave :ensure t)            ; Auto-completion for octave
(use-package auto-compile :ensure t)         ; Automatically compile Emacs Lisp libraries
(use-package expand-region :ensure t)        ; Increase selected region by semantic units
(use-package idle-require :ensure t)         ; load elisp libraries while Emacs is idle
(use-package ibuffer-tramp :ensure t)        ; sort ibuffer based on tramp connection
(use-package move-text :ensure t)            ; Move current line or region with M-up or M-down
(use-package multi-term :ensure t)           ; Better terminals
(use-package skewer-mode :ensure t)          ; Use the browser as a Javascript repl
(use-package slime :ensure t)                ; Superior Lisp Interaction Mode for Emacs

;; Sane defaults

;;    These are what /I/ consider to be saner defaults.

(setq default-input-method "TeX"    ; Use TeX when toggling input method.
      doc-view-continuous t         ; At page edge goto next/previous.
      echo-keystrokes 0.1           ; Show keystrokes asap.
      inhibit-startup-message t     ; No splash screen please.
      initial-scratch-message nil   ; Clean scratch buffer.
      electric-pair-mode 1          ; Insert brackets, parentheses in pairs
      ring-bell-function 'ignore    ; Quiet.
      byte-compile-warnings nil     ; Don't show warnings when compiling elisp
      require-final-newline t       ; End files with \n
      vc-follow-symlinks t)         ; Don't ask about symlinks

;; Undo settings

(use-package undo-tree
  :ensure t
  :diminish undo-tree-mode

  :init
  ;; Save undo history between sessions, if you have an undo-dir
  (setq undo-tree-auto-save-history
        (file-exists-p
         (concat user-emacs-directory "undo"))
        undo-tree-history-directory-alist
        ;; Put undo-history files in a directory, if it exists.
        (let ((undo-dir (concat user-emacs-directory "undo")))
          (and (file-exists-p undo-dir)
               (list (cons "." undo-dir))))))

;; Some variables are buffer-local, so changing them using =setq= will only
;;    change them in a single buffer. Using =setq-default= we change the
;;    buffer-local variable's default value.

(setq-default fill-column 100                        ; Maximum line width.
              indent-tabs-mode nil                   ; Use spaces instead of tabs.
              split-width-threshold 100              ; Split verticly by default.
              auto-fill-function nil)                ; Auto fill is annoying
(diminish 'auto-fill-function)

;; Answering /yes/ and /no/ to each question from Emacs can be tedious, a
;;    single /y/ or /n/ will suffice.

(fset 'yes-or-no-p 'y-or-n-p)

;; To avoid file system clutter we put all auto saved files in a single
;;    directory.

(defvar emacs-autosave-directory
  (concat user-emacs-directory "autosaves/")
  "This variable dictates where to put auto saves. It is set to a
  directory called autosaves located wherever your .emacs.d/ is
  located.")

;; Sets all files to be backed up and auto saved in a single directory.
(setq backup-directory-alist
      `((".*" . ,emacs-autosave-directory))
      auto-save-file-name-transforms
      `((".*" ,emacs-autosave-directory t)))

;; The scratch buffer is a useful place to test out bits of elisp or store some
;;    text temporarily. It would be nice if it was persistent, though. The
;;    following code will save the buffer every 5 minutes, and reload it on
;;    startup. ([[http://dorophone.blogspot.com/2011/11/how-to-make-emacs-scratch-buffer.html][Source]])

(defun save-persistent-scratch ()
  "Save the contents of *scratch*"
       (with-current-buffer (get-buffer-create "*scratch*")
         (write-region (point-min) (point-max)
                       (concat user-emacs-directory "scratch"))))

(defun load-persistent-scratch ()
  "Reload the scratch buffer"
  (let ((scratch-file (concat user-emacs-directory "scratch")))
    (if (file-exists-p scratch-file)
        (with-current-buffer (get-buffer "*scratch*")
          (delete-region (point-min) (point-max))
          (insert-file-contents scratch-file)))))

(add-hook 'emacs-startup-hook 'load-persistent-scratch)
(add-hook 'kill-emacs-hook 'save-persistent-scratch)

(run-with-idle-timer 300 t 'save-persistent-scratch)

;; Set =utf-8= as preferred coding system.

(set-language-environment "UTF-8")

;; By default the =narrow-to-region= command is disabled and issues a
;;    warning, because it might confuse new users. I find it useful sometimes,
;;    and don't want to be warned.

(put 'narrow-to-region 'disabled nil)

;; Call =auto-complete= default configuration, which enables =auto-complete=
;;    globally.

(eval-after-load 'auto-complete-config `(ac-config-default))

;; Use Shift+arrow keys to jump around windows.

(when (fboundp 'windmove-default-keybindings)
   (windmove-default-keybindings))

;; Since I'm using a daemon, I rarely kill emacs, which means bookmarks will
;;    never get saved on quit. Just save them on every update.

(setq bookmark-save-flag 1)

;; Force =list-packages= to use the whole frame.

(use-package fullframe
             :ensure t)
(fullframe list-packages quit-window)

;; If I haven't modified a buffer and it changes on disk, revert it. Really useful for when I pull down changes to my org files.

(global-auto-revert-mode t)
(diminish 'auto-revert-mode)

;; Keybindings

;;    I keep my global key bindings in a custom keymap. By loading this map in its
;;    very own minor mode, I can make sure they ovverride any major mode
;;    bindings. I'll keep adding keys to this and then load it at the end.

(defvar custom-bindings-map (make-keymap)
  "A keymap for custom bindings.")

;; Some bindings that I haven't categorized yet:

(define-key custom-bindings-map (kbd "C-'") 'er/expand-region)
(define-key custom-bindings-map (kbd "C-;") 'er/contract-region)
(define-key custom-bindings-map (kbd "C-c h g") 'helm-google-suggest)
(define-key custom-bindings-map (kbd "C-c s") 'ispell-word)

;; Modes

;;    There are some modes that are enabled by default that I don't find
;;    particularly useful. We create a list of these modes, and disable all of
;;    these.

;;    Let's apply the same technique for enabling modes that are disabled by
;;    default.

(dolist (mode
         '(column-number-mode         ; Show column number in mode line.
           delete-selection-mode      ; Replace selected text.
           dirtrack-mode              ; directory tracking in *shell*
           recentf-mode               ; Recently opened files.
           show-paren-mode))          ; Highlight matching parentheses.
  (funcall mode 1))

(when (version< emacs-version "24.4")
  (eval-after-load 'auto-compile
    '((auto-compile-on-save-mode 1))))  ; compile .el files on save.

;; We want to have autocompletion by default. Load company mode everywhere.

(use-package company
  :ensure t
  :diminish company-mode
  :init
  (setq company-idle-delay 0)

  :config
  (add-hook 'after-init-hook 'global-company-mode))

;; Visual

;;    First, get rid of a few things.

(dolist (mode
         '(tool-bar-mode                ; No toolbars, more room for text.
           menu-bar-mode                ; No menu bar
           scroll-bar-mode              ; No scroll bars either.
           blink-cursor-mode))          ; The blinking cursor gets old.
  (funcall mode 0))

;; Change the color-theme to =zenburn= and use the [[http://www.levien.com/type/myfonts/inconsolata.html][Inconsolata]] font if it's
;;    installed. This is wrapped in a function that will make sure we only load
;;    after a frame has been created. Otherwise, starting from a daemon won't load
;;    the font correctly. ([[https://www.reddit.com/r/emacs/comments/3a5kim/emacsclient_does_not_respect_themefont_setting/][Source]])

(use-package solarized-theme)
(use-package zenburn-theme
  :ensure t)

(defun ow/load-theme ()
  (load-theme 'zenburn t)
  (when (member "Inconsolata" (font-family-list))
    (set-face-attribute 'default nil :font "Inconsolata-13")
    (add-to-list 'default-frame-alist
                 '(font . "Inconsolata-13"))))

(defun ow/load-theme-in-frame (frame)
  (select-frame frame)
  (ow/load-theme))

(if (daemonp)
    (add-hook 'after-make-frame-functions #'ow/load-theme-in-frame)
  (ow/load-theme))

;; When interactively changing the theme (using =M-x load-theme=), the
;;    current custom theme is not disabled. This often gives weird-looking
;;    results; we can advice =load-theme= to always disable themes currently
;;    enabled themes.

(defadvice load-theme
  (before disable-before-load (theme &optional no-confirm no-enable) activate)
  (mapc 'disable-theme custom-enabled-themes))

;; I like how Vim shows you empty lines using tildes. Emacs can do something
;;    similar with the variable =indicate-empty-lines=, but I'll make it look a bit
;;    more familiar. ([[http://www.reddit.com/r/emacs/comments/2kdztw/emacs_in_evil_mode_show_tildes_for_blank_lines/][Source]])

(setq-default indicate-empty-lines t)
(define-fringe-bitmap 'tilde [0 0 0 113 219 142 0 0] nil nil 'center)
(setcdr (assq 'empty-line fringe-indicator-alist) 'tilde)
(set-fringe-bitmap-face 'tilde 'font-lock-function-name-face)

;; Windows

;;    =Winner-mode= allows you to jump back to previously used window
;;    configurations. The following massive function will ignore unwanted buffers
;;    when returning to a particular layout. ([[https://github.com/thierryvolpiatto/emacs-tv-config/blob/master/.emacs.el#L1706][Source]])

(setq winner-boring-buffers '("*Completions*"
                              "*Compile-Log*"
                              "*inferior-lisp*"
                              "*Fuzzy Completions*"
                              "*Apropos*"
                              "*Help*"
                              "*cvs*"
                              "*Buffer List*"
                              "*Ibuffer*"
                              ))
(defvar winner-boring-buffers-regexp "\\*[hH]elm.*")
(defun winner-set1 (conf)
  (let* ((buffers nil)
         (alive
          ;; Possibly update `winner-point-alist'
          (cl-loop for buf in (mapcar 'cdr (cdr conf))
                   for pos = (winner-get-point buf nil)
                   if (and pos (not (memq buf buffers)))
                   do (push buf buffers)
                   collect pos)))
    (winner-set-conf (car conf))
    (let (xwins) ; to be deleted
      ;; Restore points
      (dolist (win (winner-sorted-window-list))
        (unless (and (pop alive)
                     (setf (window-point win)
                           (winner-get-point (window-buffer win) win))
                     (not (or (member (buffer-name (window-buffer win))
                                      winner-boring-buffers)
                              (string-match winner-boring-buffers-regexp
                                            (buffer-name (window-buffer win))))))
          (push win xwins))) ; delete this window
      ;; Restore marks
      (letf (((current-buffer)))
        (cl-loop for buf in buffers
                 for entry = (cadr (assq buf winner-point-alist))
                 for win-ac-reg = (winner-active-region)
                 do (progn (set-buffer buf)
                           (set-mark (car entry))
                           (setf win-ac-reg (cdr entry)))))
      ;; Delete windows, whose buffers are dead or boring.
      ;; Return t if this is still a possible configuration.
      (or (null xwins)
          (progn
            (mapc 'delete-window (cdr xwins)) ; delete all but one
            (unless (one-window-p t)
              (delete-window (car xwins))
              t))))))
(defalias 'winner-set 'winner-set1)
(winner-mode 1)

;; The following function will toggle horizontal/vertical window splits. ([[http://www.emacswiki.org/emacs/ToggleWindowSplit][Source]])

(defun ow/toggle-window-split ()
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
             (next-win-buffer (window-buffer (next-window)))
             (this-win-edges (window-edges (selected-window)))
             (next-win-edges (window-edges (next-window)))
             (this-win-2nd (not (and (<= (car this-win-edges)
                                         (car next-win-edges))
                                     (<= (cadr this-win-edges)
                                         (cadr next-win-edges)))))
             (splitter
              (if (= (car this-win-edges)
                     (car (window-edges (next-window))))
                  'split-window-horizontally
                'split-window-vertically)))
        (delete-other-windows)
        (let ((first-win (selected-window)))
          (funcall splitter)
          (if this-win-2nd (other-window 1))
          (set-window-buffer (selected-window) this-win-buffer)
          (set-window-buffer (next-window) next-win-buffer)
          (select-window first-win)
          (if this-win-2nd (other-window 1))))))

;; Refile
;;   Stuff that I'm still playing around with.

(add-hook 'text-mode-hook #'bug-reference-mode)
(add-hook 'prog-mode-hook #'bug-reference-prog-mode)

(use-package helm-org-rifle
  :ensure t)

(use-package abbrev
  :diminish abbrev-mode
  :config
  (if (file-exists-p abbrev-file-name)
      (quietly-read-abbrev-file)))

;; Helm

;;   Helm is an amazing completion tool for finding almost anything. We can
;;   replace many default functions with the helm equivalent.

(use-package helm
  :ensure t
  :diminish helm-mode
  :bind (("C-x b" . helm-mini)
         ("C-x C-f" . helm-find-files)
         ("C-c h" . helm-command-prefix)
         ("M-x" . helm-M-x)
         ("M-y" . helm-show-kill-ring))

  :init
  (setq helm-quick-update                     t ; do not display invisible candidates
        helm-split-window-in-side-p           t ; open helm buffer inside current window, not occupy whole other window
        helm-M-x-fuzzy-match                  t ; fuzzy matching M-x
        helm-buffers-fuzzy-matching           t ; fuzzy matching buffer names when non--nil
        helm-recentf-fuzzy-match              t ; fuzzy matching recent files
        helm-move-to-line-cycle-in-source     t ; move to end or beginning of source when reaching top or bottom of source.
        helm-ff-search-library-in-sexp        t ; search for library in `require' and `declare-function' sexp.
        helm-scroll-amount                    8 ; scroll 8 lines other window using M-<next>/M-<prior>
        helm-ff-file-name-history-use-recentf t)
  (when (executable-find "curl")
    (setq helm-google-suggest-use-curl-p t))

  :config
  ; When I haven't entered anything, backspace should get me out of helm
  (defun helm-backspace ()
    (interactive)
    (condition-case nil
        (backward-delete-char 1)
      (error
       (helm-keyboard-quit))))

  (define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action)
  (define-key helm-map (kbd "C-z")  'helm-select-action) ; list actions using C-z
  (define-key helm-map (kbd "DEL") 'helm-backspace)

  (helm-mode 1))

(use-package helm-ag
  :ensure t)

(use-package helm-projectile
  :ensure t
  :config
  (helm-projectile-on))

;; I'd like to easily run helm-occur on all buffers that are backed by files. ([[http://stackoverflow.com/questions/14726601/sublime-text-2s-goto-anything-or-instant-search-for-emacs][Source]])

(defun ow/helm-do-grep-all-buffers ()
  "multi-occur in all buffers backed by files."
  (interactive)
  (helm-multi-occur-1
   (delq nil
         (mapcar (lambda (b)
                   (when (buffer-file-name b) (buffer-name b)))
                 (buffer-list)))))

;; When you press backspace in a helm buffer and there's nothing left to delete,
;;   helm will complain by saying ~Text is read only~. A much better default is to just
;;   close the buffer. ([[http://oremacs.com/2014/12/21/helm-backspace/][Source]])



;; helm-gtags

(use-package helm-gtags
  :ensure t
  :diminish helm-gtags-mode
  :bind (("M-." . helm-gtags-dwim)
         ("M-," . helm-gtags-pop-stack))
  :init
  (setq helm-gtags-ignore-case t
        helm-gtags-auto-update t
        helm-gtags-use-input-at-cursor t
        helm-gtags-pulse-at-cursor t
        helm-gtags-prefix-key "\C-cg"
        helm-gtags-suggested-key-mapping t)

  :config
  (add-hook 'dired-mode-hook 'helm-gtags-mode)
  (add-hook 'eshell-mode-hook 'helm-gtags-mode)
  (add-hook 'c-mode-hook 'helm-gtags-mode)
  (add-hook 'c++-mode-hook 'helm-gtags-mode)
  (add-hook 'asm-mode-hook 'helm-gtags-mode)

  (define-key helm-gtags-mode-map (kbd "C-c g a") 'helm-gtags-tags-in-this-function)
  (define-key helm-gtags-mode-map (kbd "C-j") 'helm-gtags-select)
  (define-key helm-gtags-mode-map (kbd "C-c <") 'helm-gtags-previous-history)
  (define-key helm-gtags-mode-map (kbd "C-c >") 'helm-gtags-next-history))

;; Ivy

;; I'm just starting to play around with Ivy, and it may end up replacing a lot of Helm functionality for me.

(use-package ivy
  :ensure t
  :diminish ivy-mode

  :config
  (ivy-mode 1)
  ;; add ‘recentf-mode’ and bookmarks to ‘ivy-switch-buffer’.
  (setq ivy-use-virtual-buffers t)
  ;; number of result lines to display
  (setq ivy-height 10)
  ;; does not count candidates
  (setq ivy-count-format "")
  ;; no regexp by default
  (setq ivy-initial-inputs-alist nil)
  ;; configure regexp engine.
  (setq ivy-re-builders-alist
        ;; fuzzy matching
        '((t . ivy--regex-fuzzy))))

(use-package flx
  :ensure t)

(use-package counsel
  :ensure t)

(use-package counsel-projectile
  :ensure t)

;; Buffer Management

;;    =Ibuffer= mode is a built-in replacement for the stock =BufferMenu=. It offers
;;    fancy things like filtering buffers by major mode or sorting by size. The
;;    [[http://www.emacswiki.org/emacs/IbufferMode][wiki]] offers a number of improvements.

;;    The size column is always listed in bytes. We can make it a bit more human
;;    readable by creating a custom column.

;; (eval-after-load 'ibuffer
;;   (define-ibuffer-column size-h
;;     (:name "Size" :inline t)
;;     (cond
;;      ((> (buffer-size) 1000000) (format "%7.1fM" (/ (buffer-size) 1000000.0)))
;;      ((> (buffer-size) 1000) (format "%7.1fk" (/ (buffer-size) 1000.0)))
;;      (t (format "%8d" (buffer-size)))))

;;   ;; Modify the default ibuffer-formats
;;   (setq ibuffer-formats
;;         '((mark modified read-only " "
;;                 (name 18 18 :left :elide) " "
;;                 (size-h 9 -1 :right) " "
;;                 (mode 16 16 :left :elide) " "
;;                 filename-and-process))))

(add-hook 'ibuffer-hook 'ibuffer-tramp-set-filter-groups-by-tramp-connection)

;; (fullframe ibuffer ibuffer-quit)
(define-key custom-bindings-map (kbd "C-x C-b")  'ibuffer)
(define-key custom-bindings-map (kbd "C-c r") 'rename-buffer)

;; Snippets

;;    Start yasnippet

(use-package yasnippet
  :ensure t
  :diminish yas-minor-mode
  :config
  (yas-global-mode 1))

;; Editing Large Files

;;    =VLF-mode= allows me to open up huge files in batches, which is really useful when going through
;;    massive log files. Here I just require it so I have the option of using it. More configuration to follow.

(use-package vlf
  :ensure t
  :config
  (require 'vlf-setup))

;; Base Environment

;;    Use line numbering for programming and text editing. For opening large files, this may add some
;;    overhead, so we can delay rendering a bit.

(setq linum-delay t linum-eager nil)
(add-hook 'prog-mode-hook 'linum-mode)
(add-hook 'text-mode-hook 'linum-mode)

(use-package flycheck
  :ensure t
  :init
  ;; Flycheck gets to be a bit much when warning about checkdoc issues.
  (setq-default flycheck-disabled-checkers '(emacs-lisp-checkdoc))

  :config
  (add-hook 'prog-mode-hook 'flycheck-mode))

;; I want to be able to easily pick out TOODs and FIXMEs in code. Let's do some font locking. ([[http://writequit.org/org/][Source]])

(defun ow/highlight-todos ()
  "Highlight FIXME and TODO"
  (font-lock-add-keywords
   nil '(("\\<\\(FIXME:?\\|TODO:?\\)\\>"
          1 '((:foreground "#d7a3ad") (:weight bold)) t))))

(add-hook 'prog-mode-hook #'ow/highlight-todos)

;; Show me what line I'm on.

(add-hook 'prog-mode-hook #'hl-line-mode)

;; TODO - bug-reference-mode

;;     White space stuff ([[http://www.reddit.com/r/emacs/comments/2keh6u/show_tabs_and_trailing_whitespaces_only/][Source]])

(use-package whitespace
  :diminish whitespace-mode
  :init
  (setq whitespace-display-mappings
        ;; all numbers are Unicode codepoint in decimal. try (insert-char 182 ) to see it
        '((space-mark 32 [183] [46])              ; 32 SPACE, 183 MIDDLE DOT 「·」, 46 FULL STOP 「.」
          (newline-mark 10 [182 10])              ; 10 LINE FEED
          (tab-mark 9 [187 9] [9655 9] [92 9])))  ; 9 TAB, 9655 WHITE RIGHT-POINTING TRIANGLE 「▷」

  (setq whitespace-style '(face tabs trailing tab-mark))

  :config
  (set-face-attribute 'whitespace-tab nil
                      :background "#f0f0f0"
                      :foreground "#00a8a8"
                      :weight 'bold)
  (set-face-attribute 'whitespace-trailing nil
                      :background "#e4eeff"
                      :foreground "#183bc8"
                          :weight 'normal))
  (add-hook 'prog-mode-hook 'whitespace-mode)

;; =which-function= is a minor mode that will show use the mode line to me what function I'm
;;     in. This is really helpful for super long functions.

(use-package which-func
  :config
  (which-function-mode 1))

;; Paredit

(use-package paredit
  :ensure t
  :diminish paredit-mode
  :config
  (add-hook 'emacs-lisp-mode-hook 'paredit-mode)
  (add-hook 'racket-mode-hook 'paredit-mode)
  (add-hook 'clojure-mode-hook 'paredit-mode))

;; sr-speedbar

;;     When I'm exploring a new code base, it's really nice to be able to see what else is in the
;;     current directory. =sr-speedbar= will follow my current buffer to show me a list of other
;;     files. You can even expand a file and get a tree of all the tags inside. This feature is super
;;     useful for C++ files.

;;     TODO: integrate speedbar with evil

(use-package sr-speedbar
  :ensure t
  :init
  (setq sr-speedbar-right-side nil)
  (setq sr-speedbar-skip-other-window-p t)
  (setq speedbar-use-images nil)
  (setq sr-speedbar-width 25))

;; Compilation

(setq-default
 compilation-auto-jump-to-first-error t    ; Take me to the first error
 compilation-always-kill t                 ; Restart compilation without prompt
 compilation-ask-about-save nil            ; Don't worry about saving buffers
 compilation-scroll-output 'first-error)   ; Follow compilation buffer until we hit an error

;; I only need the output of the compilation buffer if there are any errors. Otherwise, we can close
;;    it when it finishes. ([[http://emacs.stackexchange.com/questions/62/hide-compilation-window][Source]])

(setq compilation-finish-function
      (lambda (buf str)
        (if (and (null (string-match ".*exited abnormally.*" str))
                 (null (string-match ".*interrupt.*" str)))
            ;;no errors, make the compilation window go away in a few seconds
            (progn
              (run-at-time
               "1 sec" nil 'delete-windows-on
               (get-buffer-create "*compilation*"))
              (message "No Compilation Errors!")))))

;; When gcc hits an error, it spits out a number of lines that say something like =In file included
;;    from /path/to/file.h:22=. For whatever reason, =next-error= immediately jumps to the first of the
;;    files when I really want to jump straight to the error. This cryptic line will fix the regex
;;    that's causing this. ([[http://stackoverflow.com/questions/15489319/how-can-i-skip-in-file-included-from-in-emacs-c-compilation-mode][Source]])

(setcar (nthcdr 5 (assoc 'gcc-include compilation-error-regexp-alist-alist)) 0)

;; C++

;;     By default, .h files are opened in C mode. I'll mostly be using them for C++
;;     projects, though.

(use-package c++-mode
  :mode "\\.h\\'")

;; FSP

;;     FSP (Finite state processes) is a notation that formally describes concurrent
;;     systems as described in the book Concurrency by Magee and Kramer. Someday
;;     I want to make a fully featured mode for FSP. Someone by the name of
;;     Esben Andreasen made a mode with basic syntax highlighting, so that will
;;     have to do for now.

;;     We'll add it manually until I have time to play around with it.

;; Load fsp-mode.el from its own directory
;; (add-to-list 'load-path "~/Dropbox/fsp-mode/")
;; (require 'fsp-mode)

;; Java and C

;;     The =c-mode-common-hook= is a general hook that work on all C-like
;;     languages (C, C++, Java, etc...). I like being able to quickly compile
;;     using =C-c C-c= (instead of =M-x compile=), a habit from =latex-mode=.

(defun c-setup ()
  (local-set-key (kbd "C-c C-c") 'compile)
  (setq c-default-style "linux"
        c-basic-offset 4))

(add-hook 'c-mode-common-hook 'c-setup)

(defun java-setup ()
  (setq-local compile-command (concat "javac " (buffer-name))))

(add-hook 'java-mode-hook 'java-setup)

;; LaTeX

;;     =.tex=-files should be associated with =latex-mode= instead of
;;     =tex-mode=.

(use-package latex-mode
 :mode "\\.tex\\'" )

(evil-leader/set-key-for-mode 'latex-mode
  "at" 'tex-compile)

;; Lisps

;;     This advice makes =eval-last-sexp= (bound to =C-x C-e=) replace the sexp with
;;     the value.

(defadvice eval-last-sexp (around replace-sexp (arg) activate)
  "Replace sexp when called with a prefix argument."
  (if arg
      (let ((pos (point)))
        ad-do-it
        (goto-char pos)
        (backward-kill-sexp)
        (forward-sexp))
    ad-do-it))

;; Clojure

(use-package clojure-mode
  :ensure t)

(use-package cider
  :ensure t)

(evil-leader/set-key-for-mode 'clojure-mode
  "vv" 'cider-eval-last-sexp
  "vV" 'cider-eval-last-sexp-to-repl)

;; Emacs Lisp

(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            ;; Use spaces, not tabs.
            (setq indent-tabs-mode nil)
            (define-key emacs-lisp-mode-map
              "\r" 'reindent-then-newline-and-indent)))
(add-hook 'emacs-lisp-mode-hook 'eldoc-mode)
(add-hook 'emacs-lisp-mode-hook 'flyspell-prog-mode) ;; Requires Ispell

;; Racket

;; Use racket in geiser-mode.

(use-package racket-mode
  :mode "\\.rkt")

;; Markdown

(use-package markdown-mode
  :mode "\\.md\\'")

;; Octave

;;     Make it so =.m= files are loaded in =octave-mode=.

(use-package octave-mode
  :mode "\\.m$")

;; Python

;;      [[http://tkf.github.io/emacs-jedi/released/][Jedi]] offers very nice auto completion for =python-mode=. Mind that it is
;;      dependent on some python programs as well, so make sure you follow the
;;      instructions from the site.

(use-package jedi
  :init
  (setq jedi:complete-on-dot t))
;; (add-hook 'python-mode-hook 'jedi:setup)
;; (setq jedi:server-command
;;      (cons "python3" (cdr jedi:server-command))
;;      python-shell-interpreter "python3")

;;(add-hook 'python-mode-hook 'jedi:ac-setup)

;; impatient mode
;;      TODO: start httpd in correct directory

;;     =impatient-mode= is an amazing tool for live-editing web pages. When paired with
;;     =simple-httdp=, you can point your browser to =http://localhost:8080/imp= to
;;     see a live copy of any buffer that has impatient-mode enabled. If that buffer happens to contain HTML, CSS, or Javascript, it will be evaluated on the fly. No need to save or refresh
;;     anything. It's almost like they knew that I'm very... impatient.

;;     Let's start impatient mode for all HTML, CSS, and Javascript buffers, and
;;     run =httpd-start= when needed.

;; TODO: set up impatient mode
;(use-package impatient-mode)

;(defun ow/imp-setup ()
;  (setq httpd-root "/home/oliver/") ;; I'd like to set this based on the current buffer's working directory
;  (httpd-start)
;  (impatient-mode))

;; (add-hook 'html-mode-hook 'ow/imp-setup)
;; (add-hook 'css-mode-hook 'ow/imp-setup)
;; (add-hook 'js-mode-hook 'ow/imp-setup)

;; RUBY ON RAILS
;; Add Rinari for easy navigation

;; Interactively Do Things (highly recommended, but not strictly required)
  (require 'ido)
  (ido-mode t)

  ;; Rinari
  (add-to-list 'load-path "~/.emacs.d/rinari")
  (require 'rinari)
  (add-hook 'ruby-mode-hook 'rinari-minor-mode t)

;;; nxml (HTML ERB template support)
(load "~/.emacs.d/nxhtml/autostart.el")
 (setq
         nxhtml-global-minor-mode t
         mumamo-chunk-coloring 'submode-colored
         nxhtml-skip-welcome t
         indent-region-mode t
         rng-nxml-auto-validate-flag nil
         nxml-degraded t)

(add-to-list 'auto-mode-alist '("\\.html\\.erb$" . eruby-nxhtml-mumamo-mode))

;; JavaScript

(use-package js2-mode
  :ensure t
  ;; :mode "\\.js\\"

  :init
  (setq js2-highlight-level 1)

  :config
  (add-hook 'js2-mode-hook 'ac-js2-mode))

;; Semantic

(require 'cc-mode)
(require 'semantic)

(global-semanticdb-minor-mode 1)
(global-semantic-idle-scheduler-mode 1)

(semantic-mode 1)

;; function-args

(use-package function-args
  :ensure t
  :diminish FA
  :config
  (fa-config-default)
  (define-key c-mode-map  [(control tab)] 'moo-complete)
  (define-key c++-mode-map  [(control tab)] 'moo-complete)
  (define-key c-mode-map (kbd "M-o")  'fa-show)
  (define-key c++-mode-map (kbd "M-o")  'fa-show))

;; Source Control

;;    Magit is awesome!

(use-package magit
  :ensure t
  :bind ("C-c m" . magit-status)
  :init
  (setq magit-push-always-verify nil)

  :config
  (fullframe magit-status magit-mode-quit-window))

; Play nicely with evil
(use-package evil-magit
  :ensure t
  :init
  (setq evil-magit-state 'motion))
(use-package magit-svn)
(use-package gist)

;; Diffs

;;     =ediff= is a powerful tool for dealing with changes to a file. You can diff
;;     two files or diff the current buffer against the version that's on disk. I
;;     haven't had to use it too much yet, but here are some tweaks that I've
;;     picked up.

;;     By default, ediff compares two buffers in a vertical split. Horizontal would
;;     make it a lot easier to compare things.

(custom-set-variables
 '(ediff-window-setup-function 'ediff-setup-windows-plain)
 '(ediff-diff-options "-w")
 '(ediff-split-window-function 'split-window-horizontally))

;; Don't screw up my window configuration after I leave ediff.

(add-hook 'ediff-after-quit-hook-internal 'winner-undo)

;; It's hard to diff org files when everything is collapsed. These functions
;;     will expand each hunk as I jump to it, and collapse the rest. ([[http://permalink.gmane.org/gmane.emacs.orgmode/75211][Source]])

;; Check for org mode and existence of buffer
(defun ow/ediff-org-showhide(buf command &rest cmdargs)
  "If buffer exists and is orgmode then execute command"
  (if buf
      (if (eq (buffer-local-value 'major-mode (get-buffer buf)) 'org-mode)
          (save-excursion (set-buffer buf) (apply command cmdargs)))))

(defun ow/ediff-org-unfold-tree-element ()
  "Unfold tree at diff location"
  (ow/ediff-org-showhide ediff-buffer-A 'org-reveal)
  (ow/ediff-org-showhide ediff-buffer-B 'org-reveal)
  (ow/ediff-org-showhide ediff-buffer-C 'org-reveal))
;;
(defun ow/ediff-org-fold-tree ()
  "Fold tree back to top level"
  (ow/ediff-org-showhide ediff-buffer-A 'hide-sublevels 1)
  (ow/ediff-org-showhide ediff-buffer-B 'hide-sublevels 1)
  (ow/ediff-org-showhide ediff-buffer-C 'hide-sublevels 1))

(add-hook 'ediff-select-hook 'ow/ediff-org-unfold-tree-element)
(add-hook 'ediff-unselect-hook 'ow/ediff-org-fold-tree)

;; We can use a function to toggle how whitespace is treated in the
;;     diff. ([[http://www.reddit.com/r/emacs/comments/2513zo/ediff_tip_make_vertical_split_the_default/][Source]])

(defun ediff-toggle-whitespace-sensitivity ()
  "Toggle whitespace sensitivity for the current EDiff run.

This does not affect the global EDiff settings.  The function
automatically updates the diff to reflect the change."
  (interactive)
  (let ((post-update-message
         (if (string-match " ?-w$" ediff-actual-diff-options)
             (progn
               (setq ediff-actual-diff-options
                     (concat ediff-diff-options " " ediff-ignore-case-option)
                     ediff-actual-diff3-options
                     (concat ediff-diff3-options " " ediff-ignore-case-option3))
               "Whitespace sensitivity on")
           (setq ediff-actual-diff-options
                 (concat ediff-diff-options " " ediff-ignore-case-option " -w")
                 ediff-actual-diff3-options
                 (concat ediff-diff3-options " " ediff-ignore-case-option3 " -w"))
           "Whitespace sensitivity off")))
    (ediff-update-diffs)
    (message post-update-message)))

(add-hook 'ediff-keymap-setup-hook
          #'(lambda () (define-key ediff-mode-map [?W] 'ediff-toggle-whitespace-sensitivity)))

;; Projectile

;;    Projectile makes it easy to navigate files in a single project. A project
;;    is defined as any directory containing a .git/ or other VCS
;;    repository. We can manually define a project by adding an empty
;;    =.projectile= file to our directory.

(use-package projectile
  :ensure t
  :init
  (setq projectile-completion-system 'helm)
  (setq projectile-enable-caching t)

  ; Used for helm-projectile-grep
  (setq grep-find-ignored-directories nil)
  (setq grep-find-ignored-files nil)

  ; Save all project buffers whenever I compile
  (defun ow/projectile-setup ()
    (setq compilation-save-buffers-predicate 'projectile-project-buffer-p))

  :config
  (add-hook 'projectile-mode-hook 'ow/projectile-setup)
  (projectile-global-mode))

;; =projectile-find-file-dwim= is a handy way to immediately jump around a project if there's a
;;    filename under the point. One thing it can't do is line numbers, such as =hello.cpp:42=. This
;;    function will jump to a line number if it's there, otherwise just call the regular function.
;;    (Adapted from the advice found [[http://stackoverflow.com/questions/3139970/open-a-file-at-line-with-filenameline-syntax][here]])

;;    When I have time I'd like to add this capability right into Projectile, since I'm duplicating
;;    quite a bit of code here.
   
;;    TODO - gf or <SPC>pf should
;;    - Check if in project
;;      - If yes, jump to project file
;;      - If no, check list of all project files
;;      - Otherwise, find-file

(defun ow/projectile-find-file-with-line-number-maybe ()
  (interactive)
  (let* ((projectile-require-project-root nil)
         (file (if (region-active-p)
                   (buffer-substring (region-beginning) (region-end))
                 (or (thing-at-point 'filename) "")))
         (project-files (projectile-all-project-files)))
    (if (string-match "\\(.*?\\):\\([0-9]+\\)$" file)
        (let* ((file-name (match-string 1 file))
               (line-num (string-to-number (match-string 2 file)))
               (file-match (car (-filter (lambda (project-file)
                                           (string-match file-name project-file))
                                         project-files))))
          (when file-match
            (find-file (expand-file-name file-match (projectile-project-root)))
            (goto-line line-num))))))

(advice-add 'helm-projectile-find-file-dwim :before-until #'ow/projectile-find-file-with-line-number-maybe)

;; neotree

;; I like to see the full tree structure of my projects. NeoTree provides that.

(add-to-list 'load-path "~/.emacs.d/neotree/")
  (require 'neotree)
  (global-set-key [f8] 'neotree-toggle)

;; Dired

;;    By default, dired shows file sizes in bytes. We can change the switches used by ls to make things human readable.

(setq dired-listing-switches "-alh")

;; Terminals

;;    Multi-term makes working with many terminals a bit nicer. I can easily create
;;    and cycle through any number of terminals. There's also a "dedicated terminal"
;;    that I can pop up when needed.

;;    From the emacs wiki:

(defun last-term-buffer (l)
  "Return most recently used term buffer."
  (when l
    (if (eq 'term-mode (with-current-buffer (car l) major-mode))
        (car l) (last-term-buffer (cdr l)))))

(defun get-term ()
  "Switch to the term buffer last used, or create a new one if
    none exists, or if the current buffer is already a term."
  (interactive)
  (let ((b (last-term-buffer (buffer-list))))
    (if (or (not b) (eq 'term-mode major-mode))
        (multi-term)
      (switch-to-buffer b))))

(setq multi-term-dedicated-select-after-open-p t)

;; Some modes don't need to be in the terminal.

;; (add-hook 'term-mode-hook (lambda()
;;                             (yas-minor-mode -1)))

(define-key custom-bindings-map (kbd "C-c t") 'multi-term-dedicated-toggle)
(define-key custom-bindings-map (kbd "C-c T") 'get-term)

;; I'd like the =C-l= to work more like the standard terminal (which works
;;    like running =clear=), and resolve this by simply removing the
;;    buffer-content. Mind that this is not how =clear= works, it simply adds a
;;    bunch of newlines, and puts the prompt at the top of the window, so it
;;    does not remove anything. In Emacs removing stuff is less of a worry,
;;    since we can always undo!

(defun clear-shell ()
  "Runs `comint-truncate-buffer' with the
`comint-buffer-maximum-size' set to zero."
  (interactive)
  (let ((comint-buffer-maximum-size 0))
   (comint-truncate-buffer)))

(add-hook 'shell-mode-hook (lambda () (local-set-key (kbd "C-l") 'clear-shell)))

;; Config files

;;    Let's add some color to these files.

(add-to-list 'auto-mode-alist '("\\.service\\'" . conf-unix-mode))
(add-to-list 'auto-mode-alist '("\\.timer\\'" . conf-unix-mode))
(add-to-list 'auto-mode-alist '("\\.target\\'" . conf-unix-mode))
(add-to-list 'auto-mode-alist '("\\.mount\\'" . conf-unix-mode))
(add-to-list 'auto-mode-alist '("\\.automount\\'" . conf-unix-mode))
(add-to-list 'auto-mode-alist '("\\.slice\\'" . conf-unix-mode))
(add-to-list 'auto-mode-alist '("\\.socket\\'" . conf-unix-mode))
(add-to-list 'auto-mode-alist '("\\.path\\'" . conf-unix-mode))

;; Proced

(defun proced-settings ()
  (proced-toggle-auto-update t))

(add-hook 'proced-mode-hook 'proced-settings)
(define-key custom-bindings-map (kbd "C-x p") 'proced)

;; Org-mode

;;   =Org-mode= makes up a massive part of my emacs usage.

(defun ow/org-setup ()
  (interactive)
  (turn-on-auto-fill)
  (turn-on-flyspell))

(use-package org-mode
  :pin manual
  :mode "\\.txt\\'"

  :init
  (setq org-agenda-files '("~/org/")
        org-agenda-default-appointment-duration 60     ; 1 hour appointments
        org-agenda-span 1                              ; Show only today by default
        org-agenda-start-on-weekday 0                  ; Show agenda from Sunday.
        org-catch-invisible-edits 'show                ; Expand a fold when trying to edit it
        org-confirm-babel-evaluate nil                 ; Don't ask to evaluate src blocks
        org-directory "~/org/"
        org-hide-emphasis-markers t                    ; Don't show markup characters
        org-link-search-must-match-exact-headline nil  ; Create internal links with only a partial match
        org-outline-path-complete-in-steps nil         ; Refile in a single go
        org-refile-use-outline-path t                  ; Show full paths for refiling
        org-return-follows-link t                      ; Hit return to open links
        org-src-fontify-natively t                     ; Highlight src blocks natively
        org-startup-folded t                           ; Start buffer folded
        org-startup-indented t)                        ; Indent sections based on their header level

                                        ; Show dots instead of dashes
  (font-lock-add-keywords 'org-mode
                          '(("^ +\\([-*]\\) "
                             (0 (prog1 ()
                                  (compose-region (match-beginning 1) (match-end 1) "•"))))))

  :config
  (add-hook 'org-mode-hook #'ow/org-setup)
  (fullframe org-agenda org-agenda-Quit))

(use-package org-bullets
  :ensure t
  :config
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))

;; Of course, I use git to keep my org files under control. We should periodically make sure everything is in sync.

(defun ow/sync-org-directory ()
  "Save all org buffers and then run my script to sync everything with my git remote.
If there are new changes, my org buffers should auto revert"
  (interactive)
  (let ((default-directory org-directory))
    (org-save-all-org-buffers)
    (save-window-excursion
      (shell-command "./maintainOrgFiles" "*maintainOrgFiles"))))

(run-with-idle-timer 300 t 'ow/sync-org-directory)

;; Agenda

;;    I'm just starting to play around with custom agenda commands.

(setq org-agenda-custom-commands
      '(("w" "Work"
         ((tags-todo "+WORK-backlog"
                     ((org-agenda-overriding-header "Tasks")
                      (org-agenda-remove-tags t)
                      (org-agenda-sorting-strategy
                       '(todo-state-down priority-down))
                      (org-agenda-skip-function
                       '(org-agenda-skip-entry-if 'todo '("IDEA" "STALLED" "STARTED" "BLOCKED")))))
          (todo "BLOCKED"
                ((org-agenda-overriding-header "Blocked")))
          (todo "FIXED"
                ((org-agenda-overriding-header "Awaiting verification")))
          (todo "STALLED|STARTED|QA"
                ((org-agenda-overriding-header "Stories")))))))

;; Mark tasks as complete when all subtasks are done.

(defun org-summary-todo (n-done n-not-done)
  "Switch entry to DONE when all subentries are done, to TODO otherwise."
  (let (org-log-done org-log-states)   ; turn off logging
    (org-todo (if (= n-not-done 0) "DONE" "TODO"))))

(add-hook 'org-after-todo-statistics-hook 'org-summary-todo)

(setq org-hierarchical-todo-statistics 'nil)

;; Babel

;;    Org-babel is awesome for literate programming, and it even works with
;;    compiled languages. To create C source blocks we just need to enable

(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (C . t)
     (dot . t)
     (gnuplot . t)
     (sh . t)
     (python . t)
     (octave . t))))

(advice-add 'org-babel-C-ensure-main-wrap :override #'ow/org-c-src-main)

(defun ow/org-c-src-main (body)
  "Wrap BODY in a \"main\" function call if none exists."
  (if (string-match "^[ \t]*[intvod]+[ \t\n\r]*main[ \t]*(.*)" body)
      body
    (format "int main(int argc, char* argv[]) {\n%s\nreturn 0;\n}\n" body)))

;; We can ensure that src blocks in certain languages receive some default headers.

(setq org-babel-default-header-args:sh
      '((:shebang . "#!/bin/bash")))

(setq org-babel-default-header-args:python
      '((:shebang . "#!/bin/python")))

;; Capturing

;;    Notes that I capture are generally sent to =refile.org= for further review. We can use Helm to
;;    quickly refile them to any headline within my =org-agenda-files=.

(setq org-refile-targets '((nil :maxlevel . 9)
                           (org-agenda-files :maxlevel . 9)))

(defun ow/verify-refile-target ()
  "Exclude todo keywords with a done state from refile targets"
  (not (member (nth 2 (org-heading-components)) org-done-keywords)))

(setq org-refile-target-verify-function 'ow/verify-refile-target)

;; The capture buffer should start in insert state. Note that the usual function
;;    =evil-set-initial-state= doesn't work for this case. I'm pretty sure it's
;;    because =org-capture-mode= is only a minor mode, but I could be wrong.

(add-hook 'org-capture-mode-hook 'evil-insert-state)

;; Capture templates

(setq org-capture-templates
      '(("a" "Teamforge Artifact" entry (file+headline (concat org-directory "work.org") "Refile")
         "* OPEN artf%^{artifact} - %^{description}\n [[teamforge:%\\1][Teamforge Link]]" :immediate-finish 1)
        ("j" "Journal Entry" plain (file+datetree (concat org-directory "journal.org"))
         "    %?    %u" :empty-lines 1)
        ("s" "Scheduled Action" entry (file+datetree+prompt (concat org-directory "calendar.org"))
            "* %?\n%t\n")
        ("t" "Todo" entry (file+datetree+prompt (concat org-directory "calendar.org"))
          "* TODO %?\n  SCHEDULED: %t\n")))

;; Habits

;;    Org-mode has a nice feature called org-habit that I can use to track day to
;;    day things. Let's load the module first.

;; (add-to-list 'org-modules
;;              'org-habit)

;; MobileOrg
;;    MobileOrg will let me sync my agenda to my phone, which will then sync
;;    with my calendar.

;; Set to the name of the file where new notes will be stored
(setq org-mobile-inbox-for-pull "~/Dropbox/org/flagged.org")
;; Set to <your Dropbox root directory>/MobileOrg.
(setq org-mobile-directory "~/Dropbox/Apps/MobileOrg")

;; We can use =idle-timer= to push and pull to MobileOrg when there's no
;;    other activity.

(defvar my-org-mobile-sync-timer nil)

(defun my-org-mobile-sync-pull-and-push ()
  (org-mobile-pull)
  (org-mobile-push)
  (when (fboundp 'sauron-add-event)
    (sauron-add-event 'my 3 "Called org-mobile-pull and org-mobile-push")))

(defun my-org-mobile-sync-start ()
  "Start automated `org-mobile-push'"
  (interactive)
  (setq my-org-mobile-sync-timer
        (run-with-idle-timer 300 t
                             'my-org-mobile-sync-pull-and-push)))

(defun my-org-mobile-sync-stop ()
  "Stop automated `org-mobile-push'"
  (interactive)
  (cancel-timer my-org-mobile-sync-timer))

(my-org-mobile-sync-start)

;; Keybindings

;;    Org-mode uses Shift + arrow keys to change things like timestamps, TODO
;;    keywords, priorities, and so on. This is nice, but it gets in the way of
;;    windmove. The following hooks will allow shift+<arrow> to use windmove if
;;    there are no special org-mode contexts under the point.

(add-hook 'org-shiftup-final-hook 'windmove-up)
(add-hook 'org-shiftleft-final-hook 'windmove-left)
(add-hook 'org-shiftdown-final-hook 'windmove-down)
(add-hook 'org-shiftright-final-hook 'windmove-right)

;; Some default org keybindings could be a bit more evil.

(evil-define-key 'normal org-mode-map
  (kbd "M-h") 'org-metaleft
  (kbd "M-j") 'org-metadown
  (kbd "M-k") 'org-metaup
  (kbd "M-l") 'org-metaright)

;; Ledger

;;   I use John Wiegley's amazing [[http://ledger-cli.org][ledger-cli]] to keep track of my finances. Ledger reads from a simple
;;   plaintext file to generate any financial report you could ever want.

(setq ow/ledger-dir "~/Dropbox/ledger")

(use-package ledger-mode
  :mode "\\.dat\\'"
  :init
  (setq ledger-clear-whole-transactions 1)

  :config
  (defun ow/clean-ledger-on-save ()
    (interactive)
    (if (eq major-mode 'ledger-mode)
        (let ((curr-line (line-number-at-pos)))
          (ledger-mode-clean-buffer)
          (line-move (- curr-line 1)))))

  (defun ledger-increment-date ()
    (interactive)
    (ow/ledger-change-date 1))

  (defun ledger-decrement-date ()
    (interactive)
    (ow/ledger-change-date -1))

  (defun ow/ledger-change-date (num)
    "Replace date of current transaction with date + num days.
   Currently only works with the format %Y/%m/%d"
    (save-excursion
      (ledger-navigate-beginning-of-xact)
      (let* ((beg (point))
             (end (re-search-forward ledger-iso-date-regexp))
             (xact-date (filter-buffer-substring beg end)))
        (delete-region beg end)
        (insert
         (format-time-string
          "%Y/%m/%d"
          (time-add (ow/encoded-date xact-date)
                    (days-to-time num)))))))

  (defun ow/encoded-date (date)
    "Given a date in the form %Y/%m/%d, return encoded time string"
    (string-match "\\([0-9][0-9][0-9][0-9]\\)/\\([0-9][0-9]\\)/\\([0-9][0-9]\\)" date)
    (let* ((fixed-date
            (concat (match-string 1 date) "-" (match-string 2 date) "-" (match-string 3 date)))
           (d (parse-time-string fixed-date)))
      (encode-time 0 0 0 (nth 3 d) (nth 4 d) (nth 5 d))))

  (add-to-list 'evil-emacs-state-modes 'ledger-report-mode)
  (add-hook 'before-save-hook 'ow/clean-ledger-on-save)
  (define-key ledger-mode-map (kbd "C-M-.") 'ledger-increment-date)
  (define-key ledger-mode-map (kbd "C-M-,") 'ledger-decrement-date))

;; Refile

(use-package ox-reveal
  :ensure t
  :init
  (setq org-reveal-root "http://cdn.jsdelivr.net/reveal.js/3.0.0/"))


(use-package htmlize
  :ensure t)

;; Wrap-up

;;   We're ready to load the minor mode containing my global keybindings.

(define-minor-mode custom-bindings-mode
  "A mode that activates custom-bindings."
  t nil custom-bindings-map)

;; The moment of truth. How did we do on load time?

(defun ow/get-init-time ()
    (when window-system
      (let ((elapsed
             (float-time (time-subtract (current-time) emacs-start-time))))
        (message "Loading init.el...done (%.3fs)" elapsed))))

(add-hook 'after-init-hook 'ow/get-init-time)
