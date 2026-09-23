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
  )
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


(defun my-org-media-capture ()
  "Prompt for a title/year and return an Org capture string."
  (let* ((title (read-string "Title: "))
         (year  (read-string "Year (optional): "))
         (args  (append (list :title title)
                        (when (and year (not (string-empty-p year)))
                          (list :year (string-to-number year)))))
         (movie (condition-case err
                    (apply #'orgmdb args)
                  (error (user-error "OMDb lookup failed: %s"
                                     (error-message-string err))))))
    (unless movie
      (user-error "No results found for %S" title))
    (with-temp-buffer
      (insert (format "* TODO %s (%s) :%s:\n"
                      (alist-get 'Title movie)
                      (alist-get 'Year movie)
                      (if (string= (alist-get 'Type movie) "series")
                          "series" "movie")))
      (insert ":PROPERTIES:\n")
      (insert (format ":IMDB_ID: %s\n" (alist-get 'imdbID movie)))
      (insert (format ":RATING:  %s\n" (alist-get 'imdbRating movie)))
      (insert (format ":METASCORE:  %s\n" (alist-get 'Metascore movie)))
      (insert ":END:\n\n")
      (insert (or (alist-get 'Plot movie) "") "\n")
      (buffer-string))))

(defun my-rawg-search (query)
  "Search RAWG for QUERY and return the first result's alist."
  (let* ((api-key "4e394795884c4968bb06288ad423a2fd")
         (url (format "https://api.rawg.io/api/games?key=%s&search=%s&page_size=1"
                      api-key (url-hexify-string query)))
         (response-buffer (url-retrieve-synchronously url)))
    (with-current-buffer response-buffer
      (goto-char url-http-end-of-headers)
      (let ((json-object-type 'alist)
            (json-key-type 'symbol)
            (json-array-type 'list))
        (let* ((data (json-read))
               (results (alist-get 'results data)))
          (when results
            (let ((game (car results)))
              (list :title (alist-get 'name game)
                    :year (alist-get 'released game)
                    :rating (alist-get 'rating game)
                    :background (alist-get 'background_image game)))))))))

(defun my-org-insert-game (query)
  "Search RAWG for QUERY and insert a game subtree at point."
  (interactive "sGame title: ")
  (let ((game (my-rawg-search query)))
    (unless game (user-error "No RAWG results for %S" query))
    (let* ((title  (plist-get game :title))
           (year   (plist-get game :year))
           (y      (if (and year (>= (length year) 4))
                       (substring year 0 4)
                     "n/a"))
           (rating (plist-get game :rating))
           (bg     (plist-get game :background)))
      (insert (format "* %s (%s) :game:\n" title y))
      (insert ":PROPERTIES:\n")
      (insert ":SOURCE: RAWG\n")
      (insert (format ":RATING: %s\n" (or rating "n/a")))
      (insert (format ":COVER:  %s\n" (or bg "n/a")))
      (insert ":END:\n\n")
      (message "Inserted %s" title))))

(after! org
  (setq org-startup-with-inline-images t)
  (setq org-image-actual-width '(600))
  (defun my-org-rawg-capture ()
    "Capture template: prompt for a game and return Org text."
    (let* ((query (read-string "Game title: "))
           (game  (my-rawg-search query)))
      (unless game (user-error "No RAWG results for %S" query))
      (let* ((title  (plist-get game :title))
             (year   (plist-get game :year))
             (y      (if (and year (>= (length year) 4))
                         (substring year 0 4)
                       "n/a"))
             (rating (plist-get game :rating))
             (bg     (plist-get game :background)))
        (format "* %s (%s) :game:\n:PROPERTIES:\n:SOURCE: RAWG\n:RATING: %s\n:COVER:  %s\n:END:\n"
                title y (or rating "n/a") (or bg "n/a")))))

  (add-to-list 'org-capture-templates
               '("g" "Game" entry
                 (file+headline "~/hdd/org/roam/mediadb/games.org" "backlog")
                 (function my-org-rawg-capture)
                 :empty-lines 1))
  (add-to-list 'org-capture-templates
               '("m" "Media" entry
                 (file+headline "~/HDD/org/roam/MediaDB/movies.org" "Watchlist")
                 (function my-org-media-capture)
                 :empty-lines 1)))
