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

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; Make _ and - word constituents in every buffer.
(defun my/set-word-chars ()
  "Make _ and - word constituents in the current buffer."
  (modify-syntax-entry ?_ "w")
  (modify-syntax-entry ?- "w"))

(add-hook 'after-change-major-mode-hook #'my/set-word-chars)

(setq apheleia-log-debug-info t)

;; LaTeX / AucTeX configuration (VimTeX equivalent)
;; ---------------------------------------------------------------------------
(after! latex
  ;; --- viewer: Zathura ------------------------------------------------
  (setq TeX-view-program-selection '((output-pdf "Zathura"))
        TeX-view-program-list
        '(("Zathura" "zathura --synctex-forward %n:0:%b %o")))

  ;; --- SyncTeX --------------------------------------------------------
  (setq TeX-source-correlate-mode t
        TeX-source-correlate-method 'synctex
        TeX-source-correlate-start-server t)

  ;; --- don't auto-jump to viewer after compile ------------------------
  (setq TeX-show-compilation nil
        TeX-after-compilation-finished-functions
        (remove 'TeX-revert-document-buffer
                TeX-after-compilation-finished-functions))
  (add-hook 'LaTeX-mode-hook #'prettify-symbols-mode)

  ;; Optional: Improve the editing experience
  (setq prettify-symbols-unprettify-at-point 'right-edge)
  (with-eval-after-load 'tex-mode
    (dolist (pair '(("\\varnothing" . ?∅)
                    ("\\Rightarrow" . ?⇒)
                    ("\\rightarrow" . ?→)
                    ("\\mapsto" . ?↦)
                    ("\\leq" . ?≤)
                    ("\\geq" . ?≥)
                    ("\\neq" . ?≠)
                    ("\\approx" . ?≈)
                    ("\\cdot" . ?·)
                    ("\\times" . ?×)
                    ("\\ldots" . ?…)))
      (add-to-list 'tex--prettify-symbols-alist pair))))

(after! ispell
  (setq ispell-program-name "hunspell")
  ;; Configure your dictionaries (e.g., US English and French)
  (setq ispell-dictionary "en_US,ru_RU")

  ;; Advise ispell-hunspell-add-multi-dice to correctly parse the comma-separated list
  (ispell-set-spellchecker-params)
  (ispell-hunspell-add-multi-dic "en_US,ru_RU"))

;; Define tex-fmt as an Apheleia formatter and use it for LaTeX modes
(with-eval-after-load 'apheleia
  (when (executable-find "tex-fmt")
    ;; Register the formatter
    (setf (alist-get 'tex-fmt apheleia-formatters)
          '("tex-fmt" "--stdin"))

    ;; Point LaTeX modes at it
    (dolist (mode '(latex-mode LaTeX-mode TeX-latex-mode TeX-mode))
      (setf (alist-get mode apheleia-mode-alist) 'tex-fmt))))

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
