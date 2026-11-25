;;; +org.el -*- lexical-binding: t; -*-

(setq system-time-locale "C")
;; Ensure snippets are prioritized in Org mode (runs BEFORE org-roam and cape)
(set-file-template! "/org/roam/.+\\.org$" 'org-mode :ignore t)
(defun my/org-capf-setup ()
  "Add a merged CAPF to the very front of the Org completion list."
  (add-hook 'completion-at-point-functions
            (cape-capf-super
             #'yasnippet-capf
             #'org-roam-complete-everywhere
             #'org-roam-complete-link-at-point
             #'cape-elisp-block
             #'pcomplete-completions-at-point)
            -10 t)) ; -10 forces this to the top of the list

(add-hook 'org-mode-hook #'my/org-capf-setup)


(use-package! org-fragtog
  :hook (org-mode . org-fragtog-mode))

(use-package! org-appear
  :hook (org-mode . org-appear-mode)
  :config
  ;; Показывать полный синтаксис ссылок [[link][desc]] при наведении курсора
  (setq org-appear-autolinks t))

(after! org

  (defface my-org-emphasis-bold
    '((default :inherit bold)
      (((class color) (min-colors 88) (background light)) :foreground "#fabd2f")
      (((class color) (min-colors 88) (background dark))  :foreground "#fabd2f"))
    "A colored bold face for org mode")

  (defface my-org-emphasis-italic
    '((default :inherit italic)
      (((class color) (min-colors 88) (background light)) :foreground "#b8bb26")
      (((class color) (min-colors 88) (background dark))  :foreground "#b8bb26"))
    "A colored italic face for org mode")

  (defface my-org-emphasis-underline
    '((default :inherit underline)
      (((class color) (min-colors 88) (background light)) :foreground "#83a598")
      (((class color) (min-colors 88) (background dark))  :foreground "#83a598"))
    "A colored underline face for org mode")

  (defface my-org-emphasis-verbatim
    '((default :inherit org-verbatim)
      (((class color) (min-colors 88) (background light)) :foreground "#d3869b")
      (((class color) (min-colors 88) (background dark))  :foreground "#d3869b"))
    "A colored verbatim face for org mode")

  (defface my-org-emphasis-code
    '((default :inherit org-code)
      (((class color) (min-colors 88) (background light)) :foreground "#8ec07c")
      (((class color) (min-colors 88) (background dark))  :foreground "#8ec07c"))
    "A colored code face for org mode")

  (setq org-emphasis-alist
        '(("*" my-org-emphasis-bold)
          ("/" my-org-emphasis-italic)
          ("_" my-org-emphasis-underline)
          ("=" my-org-emphasis-verbatim verbatim)
          ("~" my-org-emphasis-code verbatim)
          ("+" (:strike-through t))))


  (map! :map org-mode-map
        :localleader
        "u" #'org-emphasize)
  ;; Добавляем mathtools в список пакетов, подключаемых при экспорте в LaTeX
  (add-to-list 'org-latex-packages-alist '("" "mathtools" t))
  ;; Использовать dvisvgm для рендеринга (дает векторное, красивое изображение)
  (setq org-preview-latex-default-process 'dvisvgm)
  ;; (setq org-latex-create-formula-image-program 'dvisvgm)
  (setq org-startup-with-latex-preview t)
  (setq org-pretty-entities nil) ; Отключает замену \alpha -> α и т.д.
  (setq org-pretty-entities-include-sub-superscripts nil) ; Отключает замену ^2 -> ²
  )
(use-package! laas
  :hook ((org-mode   . laas-mode)
         (LaTeX-mode . laas-mode)
         (latex-mode . laas-mode)) ; Можно включить и в Org-mode!
  :config
  ;; Вы можете настроить свои собственные сниппеты, если захотите
  (aas-set-snippets 'laas-mode
    ;; Работать только в математическом режиме И только если перед триггером НЕ буква
    :cond (lambda ()
            (and (texmathp)
                 (not (and (char-before)
                           (string-match-p "[a-zA-Z\\\\]" (string (char-before)))))))
    "supp" "\\supp"
    "On" "O(n)"
    "O1" "O(1)"
    "sum" (lambda () (interactive)
            (yas-expand-snippet "\\sum\\limits_{$1}^{$2} $0"))
    "hat" (lambda () (interactive)
            (yas-expand-snippet "\\widehat\{$1\}$0"))
    "te" (lambda () (interactive)
           (yas-expand-snippet "\\text\{$1\}$0"))
    "cal" (lambda () (interactive)
            (yas-expand-snippet "\\mathcal\{$1\}$0"))
    "mbb" (lambda () (interactive)
            (yas-expand-snippet "\\mathbb\{$1\}$0"))
    "norm" (lambda () (interactive)
             (yas-expand-snippet "\\|$1\\|$0"))
    "RR" "\\mathbb{R}"
    "NN" "\\mathbb{N}"
    "ZZ" "\\mathbb{Z}"
    "QQ" "\\mathbb{Q}"
    "co"  "\\colon"
    "al"  "\\alpha"
    "Al"  "\\mathcal{A}"
    "be"  "\\beta"
    "ga"  "\\gamma"
    "Ga"  "\\Gamma"
    "de"  "\\delta"
    "De"  "\\Delta"
    "ep"  "\\varepsilon"
    "ze"  "\\zeta"
    "et"  "\\eta"
    "th"  "\\theta"
    "Th"  "\\Theta"
    "io"  "\\iota"
    "ka"  "\\varkappa"
    "la"  "\\lambda"
    "La"  "\\Lambda"
    "mu"  "\\mu"
    "nu"  "\\nu"
    "pi"  "\\pi"
    "Pi"  "\\Pi"
    "rh"  "\\rho"
    "si"  "\\sigma"
    "Si"  "\\Sigma"
    "up"  "\\upsilon"
    "Up"  "\\Upsilon"
    "ph"  "\\varphi"
    "Ph"  "\\Phi"
    "ch"  "\\chi"
    "ps"  "\\psi"
    "Ps"  "\\Psi"
    "om"  "\\omega"
    "Om"  "\\Omega"
    ))

(after! org
  (setq org-startup-with-inline-images t)
  (add-to-list 'org-emphasis-alist
               '("@" (:weight bold :slant italic) t t))
  )
;; ✅ ADD as a top-level form (after! org-roam ...)
(after! org-roam
  (setq org-roam-capture-ref-templates
        '(("r" "ref" plain
           "* Source\n${ref}\n\n#+begin_quote\n${body}\n#+end_quote\n\n%?"
           :target (file+head "web/${slug}.org"
                              "#+title: ${title}\n#+STARTUP: nolatexpreview\n:PROPERTIES:\n:ROAM_REFS: ${ref}\n:END:\n#+created: %u\n")
           :immediate-finish t
           :unnarrowed t))))
;; --- Performance settings ---
(setq process-adaptive-read-buffering nil)
(setq process-connection-type nil)
(setq read-process-output-max (* 64 1024))
;; (setq org-preview-latex-default-process 'dvipng)

;; --- Use the async engine if available (Org 9.7+) ---
(when (boundp 'org-latex-preview-use-async)
  (setq org-latex-preview-use-async t))

;; --- Disable org-roam autosync if you experience freezes ---
;; (org-roam-autosync-mode -1) ; Uncomment to disable

;; --- Consider org-fragtog for on-demand previews ---
;; (add-hook 'org-mode-hook #'org-fragtog-mode)
