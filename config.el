(add-to-list 'exec-path (expand-file-name "~/.cargo/bin"))
(add-to-list 'exec-path (expand-file-name "~/.local/bin"))
(add-to-list 'exec-path (expand-file-name "~/.local/share/cargo/bin"))
(add-to-list 'exec-path (expand-file-name "/home/boris/.config/doom/helpers/.venv/bin"))
(add-to-list 'exec-path "/usr/local/bin")

(setq doom-font (font-spec :family "JetBrainsMono Nerd Font Mono" :size 20)
      doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font" :size 20)
      doom-big-font (font-spec :family "JetBrainsMono Nerd Font Mono" :size 24)
      doom-symbol-font (font-spec :family "JetBrainsMono Nerd Font Mono"))
(setq doom-theme 'doom-gruvbox)
(setq display-line-numbers-type 'relative)


;; Make _ and - word constituents in every buffer.
(defun my/set-word-chars ()
  "Make _ and - word constituents in the current buffer."
  (modify-syntax-entry ?_ "w")
  (modify-syntax-entry ?- "w"))

(add-hook 'after-change-major-mode-hook #'my/set-word-chars)

(setq ispell-alternate-dictionary "~/.local/share/dict/all.words")

(setq apheleia-log-debug-info t)

(load! "local/+orgdir")
(load! "+keymap")
(load! "+latex")

(after! ispell
  (setq ispell-program-name "hunspell")
  ;; Configure your dictionaries (e.g., US English and French)
  (setq ispell-dictionary "en_US,ru_RU")

  ;; Advise ispell-hunspell-add-multi-dice to correctly parse the comma-separated list
  (ispell-set-spellchecker-params)
  (ispell-hunspell-add-multi-dic "en_US,ru_RU"))


(set-file-template! "/Makefile$"
  :trigger "__makefile-cpp"
  :mode 'makefile-gmake-mode)

(after! apheleia
  (set-formatter! 'mbake
    '("bash" "-c" "mbake format \"$0\" && cat \"$0\"" input)
    :modes '(makefile-gmake-mode makefile-bsdmake-mode makefile-mode)))

(defun my/cpp-compile-and-run ()
  "Compile the current C++ file with g++ and run it in a comint buffer."
  (interactive)
  (let* ((src (buffer-file-name))
         (exe (file-name-sans-extension src))
         (default-directory (file-name-directory src)))
    (unless (string-match-p "\\.\\(cpp\\|cc\\|cxx\\|C\\)\\'" src)
      (user-error "Not a C++ file"))
    (compile (format "g++ -std=c++17 -Wall -Wextra -O2 -o %s %s && echo \"-------------------------- OUTPUT --------------------------\" && %s"
                     (shell-quote-argument exe)
                     (shell-quote-argument src)
                     (shell-quote-argument exe)))))

(map! :map (c++-mode-map c-mode-map)
      :localleader
      :desc "Compile & run C++" "r" #'my/cpp-compile-and-run)

(defun my/eglot-capf ()
  (setq-local completion-at-point-functions
              (list (cape-capf-super
                     #'eglot-completion-at-point
                     #'yasnippet-capf
                     #'cape-file))))

(add-hook 'eglot-managed-mode-hook #'my/eglot-capf)

(load! "+org")
(load! "+markdown")

(setq orgmdb-omdb-apikey "cf06fc05")
(setq orgmdb-poster-folder nil)
