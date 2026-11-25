;;; +addmedia.el -*- lexical-binding: t; -*-
(require 'cl-lib)
(require 'subr-x)
(require 'url)
(require 'json)

(defun my/media-root ()
  (expand-file-name "MediaDB/" org-directory))

(defun my/media-value (value)
  (if (or (null value) (eq value :null) (equal value "N/A"))
      "" (replace-regexp-in-string "[\n\r]+" " " (format "%s" value))))

(defun my/media-download-poster (url id)
  (when (and (stringp url) (string-match-p "\\`https?://" url))
    (let* ((dir (expand-file-name "posters/" (my/media-root)))
           (ext (downcase (or (file-name-extension
                              (car (split-string url "[?#]"))) "jpg")))
           (file (expand-file-name
                  (concat id "." (if (member ext '("jpg" "jpeg" "png" "webp")) ext "jpg")) dir)))
      (make-directory dir t)
      (condition-case err
          (progn
            (unless (file-exists-p file)
              (url-copy-file url file nil))
            file)
        (error (message "Poster download failed: %s" (error-message-string err)) nil)))))

(defun my/media-save-entry (type id title properties poster &optional plot)
  (let* ((dir (expand-file-name (concat type "/") (my/media-root)))
         (file (expand-file-name (concat id ".org") dir)))
    (make-directory dir t)
    (unless (file-exists-p file)
      (let ((image (my/media-download-poster poster id)))
        (with-temp-buffer
          (insert "#+title: " (my/media-value title) "\n\n:PROPERTIES:\n")
          (dolist (prop properties)
            (insert (format ":%s: %s\n" (car prop) (my/media-value (cdr prop)))))
          (when image
            (insert ":IMAGE: " (file-relative-name image dir) "\n"))
          (insert ":END:\n\n" (if (stringp plot) plot "") "\n")
          (let ((coding-system-for-write 'utf-8-unix))
            (write-region (point-min) (point-max) file nil 'silent nil 'excl)))))
    (find-file file)))

(defun my/omdb-request (parameter value)
  (require 'orgmdb)
  (let* ((key orgmdb-omdb-apikey)
         (url (concat "https://www.omdbapi.com/?apikey="
                      (url-hexify-string (or key ""))
                      "&" parameter "=" (url-hexify-string value)))
         (buf nil))
    (unless (and (stringp key) (not (string-empty-p key)))
      (user-error "Set orgmdb-omdb-apikey"))
    (setq buf (url-retrieve-synchronously url t t 20))
    (unless buf (user-error "OMDb request failed"))
    (unwind-protect
        (with-current-buffer buf
          (unless (eq url-http-response-status 200)
            (user-error "OMDb HTTP error: %s" url-http-response-status))
          (goto-char url-http-end-of-headers)
          (let* ((json-object-type 'alist)
                 (json-key-type 'symbol)
                 (json-array-type 'list)
                 (json-null nil)
                 (data (json-read)))
            (unless (equal (alist-get 'Response data) "True")
              (user-error "OMDb: %s" (alist-get 'Error data)))
            data))
      (kill-buffer buf))))

(defun my/media-add-movie ()
  (interactive)
  (let* ((query (read-string "Movie or series title: "))
         (results (alist-get 'Search (my/omdb-request "s" query)))
         (choices
          (mapcar (lambda (item)
                    (cons (format "%s (%s) [%s] [%s]"
                                  (alist-get 'Title item)
                                  (alist-get 'Year item)
                                  (alist-get 'Type item)
                                  (alist-get 'imdbID item))
                          (alist-get 'imdbID item)))
                  (cl-remove-if-not
                   (lambda (item)
                     (member (alist-get 'Type item) '("movie" "series")))
                   results)))
         (selected (if choices
                       (cdr (assoc (completing-read "Movie or series: " choices nil t)
                                   choices))
                     (user-error "No movie or series results")))
         (movie (my/omdb-request "i" selected))
         (id (alist-get 'imdbID movie))
         (type (alist-get 'Type movie)))
    (unless (and (stringp id) (string-match-p "\\`tt[0-9]+\\'" id))
      (user-error "No OMDb result for %s" query))
    (unless (member type '("movie" "series"))
      (user-error "Unsupported OMDb type: %s" type))
    (my/media-save-entry
     (if (equal type "series") "series" "movies") id
     (format "%s (%s)" (alist-get 'Title movie) (alist-get 'Year movie))
     `(("SOURCE" . "OMDb") ("IMDB_ID" . ,id)
       ("YEAR" . ,(alist-get 'Year movie))
       ("DIRECTOR" . ,(alist-get 'Director movie))
       ("RATING" . ,(alist-get 'imdbRating movie))
       ("METASCORE" . ,(alist-get 'Metascore movie))
       ("WATCHED" . "false"))
     (alist-get 'Poster movie) (alist-get 'Plot movie))))

(defvar my/rawg-api-key nil "RAWG API key; falls back to RAWG_API_KEY environment variable.")

(defun my/rawg-request (path &optional query)
  (let* ((key (or my/rawg-api-key (getenv "RAWG_API_KEY")))
         (url (and key (concat "https://api.rawg.io/api/" path
                               "?key=" (url-hexify-string key) (or query "")))))
    (unless (and key (not (string-empty-p key))) (user-error "Set my/rawg-api-key"))
    (let ((buf (url-retrieve-synchronously url t t 20)))
      (unless buf (user-error "RAWG request failed"))
      (unwind-protect
          (with-current-buffer buf
            (unless (and (boundp 'url-http-response-status)
                         (= url-http-response-status 200))
              (user-error "RAWG HTTP error: %s" url-http-response-status))
            (goto-char url-http-end-of-headers)
            (let ((json-object-type 'alist) (json-key-type 'symbol)
                  (json-array-type 'list) (json-null nil))
              (json-read)))
        (kill-buffer buf)))))

(defun my/media-add-game (query)
  (interactive "sGame title: ")
  (let* ((results (alist-get 'results
                            (my/rawg-request "games" (concat "&page_size=10&search=" (url-hexify-string query)))))
         (choices (mapcar (lambda (g) (cons (format "%s (%s) [%s]" (alist-get 'name g) (alist-get 'released g) (alist-get 'id g)) g)) results)))
    (unless choices (user-error "No RAWG results"))
    (let* ((game (cdr (assoc (completing-read "Game: " choices nil t) choices)))
           (id (alist-get 'id game))
           (details (my/rawg-request (format "games/%s" id)))
           (date (alist-get 'released details))
           (year (if (and (stringp date) (>= (length date) 4)) (substring date 0 4) "n/a")))
      (my/media-save-entry
       "games" (format "rawg-%s" id)
       (format "%s (%s)" (alist-get 'name details) year)
       `(("SOURCE" . "RAWG") ("RAWG_ID" . ,id) ("YEAR" . ,year)
         ("DEVELOPER" . ,(mapconcat (lambda (d) (or (alist-get 'name d) "")) (alist-get 'developers details) ", "))
         ("RATING" . ,(alist-get 'rating details)) ("PLAYED" . "false"))
       (alist-get 'background_image details) (alist-get 'description_raw details)))))

(after! org
  (require 'org-capture)
  (setq org-capture-templates
        (cl-remove-if (lambda (entry) (member (car entry) '("m" "g"))) org-capture-templates)))

(map! :leader
      :prefix ("n M" . "media")
      :desc "Add movie or series" "m" #'my/media-add-movie
      :desc "Add game" "g" #'my/media-add-game)
