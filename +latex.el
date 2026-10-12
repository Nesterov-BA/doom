;;; +latex.el -*- lexical-binding: t; -*-
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

;; Define tex-fmt as an Apheleia formatter and use it for LaTeX modes
(with-eval-after-load 'apheleia
  (when (executable-find "tex-fmt")
    ;; Register the formatter
    (setf (alist-get 'tex-fmt apheleia-formatters)
          '("tex-fmt" "--stdin"))

    ;; Point LaTeX modes at it
    (dolist (mode '(latex-mode LaTeX-mode TeX-latex-mode TeX-mode))
      (setf (alist-get mode apheleia-mode-alist) 'tex-fmt))))
