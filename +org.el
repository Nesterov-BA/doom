;;; +org.el -*- lexical-binding: t; -*-

;; Ensure snippets are prioritized in Org mode (runs BEFORE org-roam and cape)
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
  ;; Использовать dvisvgm для рендеринга (дает векторное, красивое изображение)
  (setq org-latex-create-formula-image-program 'dvisvgm)
  (setq org-pretty-entities nil) ; Отключает замену \alpha -> α и т.д.
  (setq org-pretty-entities-include-sub-superscripts nil) ; Отключает замену ^2 -> ²
  ;; Настроить размер формул
  (setq org-format-latex-optiohs
        (plist-put org-format-latex-options :scale 1)))
(use-package! laas
  :hook (org-mode . laas-mode) ; Можно включить и в Org-mode!
  :config
  ;; Вы можете настроить свои собственные сниппеты, если захотите
  (aas-set-snippets 'laas-mode
                    :cond #'texmathp ; Работать только в математическом режиме
                    "supp" "\\supp"
                    "On" "O(n)"
                    "O1" "O(1)"
                    "sum" (lambda () (interactive)
                            (yas-expand-snippet "\\sum\\limits_{$1}^{$2} $0"))
                    "hat" (lambda () (interactive)
                            (yas-expand-snippet "\\widehat\{$1\}$0"))
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
                    "ta"  "\\tau"
                    "up"  "\\upsilon"
                    "Up"  "\\Upsilon"
                    "ph"  "\\varphi"
                    "Ph"  "\\Phi"
                    "ch"  "\\chi"
                    "ps"  "\\psi"
                    "Ps"  "\\Psi"
                    "om"  "\\omega"
                    "Om"  "\\Omega"
                    ;; ... и так далее
                    ))
