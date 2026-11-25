;;; +mediadb.el -*- lexical-binding: t; -*-
(require 'cl-lib)
(require 'seq)
(require 'subr-x)

(after! org
  (defvar my/media-db-directory (expand-file-name "MediaDB/" org-directory))
  (defvar my/media-card-width 220)
  (defvar my/media-poster-width 160)
  (defvar my/media-poster-height 240)
  (defvar my/media-card-gap 20)
  (defvar-local my/media--cache nil)
  (defvar-local my/media--overlays nil)
  (defvar-local my/media--width nil)
  (defvar-local my/media--timer nil)
  (defvar-local my/media--active nil)
  (defvar-local my/media--rendering nil)

  (defun my/media--backlog-p ()
    (and buffer-file-name
         (file-equal-p buffer-file-name
                       (expand-file-name "backlog.org" org-directory))))

  (defun my/media-read-file (file)
    (with-temp-buffer
      (insert-file-contents file)
      (let ((case-fold-search t))
        (cl-labels ((field (name prefix)
                      (goto-char (point-min))
                      (when (re-search-forward
                             (concat "^" (regexp-quote prefix)
                                     (regexp-quote name) ":[ \t]*\\(.*\\)$") nil t)
                        (string-trim (match-string-no-properties 1)))))
          (let ((image (field "IMAGE" ":")))
            (list :file file
                  :title (or (field "TITLE" "#+") (file-name-base file))
                  :director (field "DIRECTOR" ":")
                  :developer (field "DEVELOPER" ":")
                  :watched (field "WATCHED" ":")
                  :played (field "PLAYED" ":")
                  :image (and image (not (string-empty-p image))
                              (expand-file-name image (file-name-directory file)))))))))

  (defun my/media-backlog-items (type)
    (let ((dir (expand-file-name type my/media-db-directory))
          (status (if (equal type "games") :played :watched)))
      (when (file-directory-p dir)
        (sort (seq-filter
               (lambda (item) (equal (plist-get item status) "false"))
               (mapcar #'my/media-read-file
                       (directory-files-recursively dir "\\.org\\'")))
              (lambda (a b)
                (string-lessp (downcase (plist-get a :title))
                              (downcase (plist-get b :title))))))))

  (defun my/media--items (type)
    (unless (hash-table-p my/media--cache)
      (setq my/media--cache (make-hash-table :test #'equal)))
    (let ((cached (gethash type my/media--cache 'missing)))
      (if (eq cached 'missing)
          (puthash type (my/media-backlog-items type) my/media--cache)
        cached)))

  (defun my/media--overlay (beg end &rest props)
    (let ((ov (make-overlay beg end nil t nil)))
      (while props (overlay-put ov (pop props) (pop props)))
      (overlay-put ov 'evaporate t)
      (push ov my/media--overlays)
      ov))

  (defun my/media--clear ()
    (mapc #'delete-overlay my/media--overlays)
    (setq my/media--overlays nil))

  (defun my/media--window-width ()
    (max 1 (window-body-width (or (get-buffer-window (current-buffer) t)
                                  (selected-window)) t)))

  (defun my/media--columns (requested)
    (max 1 (min requested
                (floor (+ (my/media--window-width) my/media-card-gap)
                       (+ my/media-card-width my/media-card-gap)))))

  (defun my/media--wrap (text)
    ;; Fixed-pitch face; leave one character of safety for font rounding.
    (let* ((limit (max 1 (1- (floor my/media-card-width
                                    (max 1 (frame-char-width))))))
           (words (split-string (or text "") "[ \t\n\r]+" t))
           (line "") result)
      (dolist (word words)
        (when (and (not (string-empty-p line))
                   (> (+ (string-width line) 1 (string-width word)) limit))
          (push line result) (setq line ""))
        (while (> (string-width word) limit)
          (let ((part (truncate-string-to-width word limit)))
            (when (string-empty-p part) (setq part (substring word 0 1)))
            (push part result)
            (setq word (substring word (length part)))))
        (unless (string-empty-p word)
          (setq line (if (string-empty-p line) word (concat line " " word)))))
      (unless (string-empty-p line) (push line result))
      (nreverse result)))

  (defun my/media--align (index)
    (let ((beg (point)))
      (insert " ")
      (my/media--overlay beg (point) 'display
                         `(space :align-to (,(* index (+ my/media-card-width my/media-card-gap)))))))

  (defun my/media--poster (item)
    (let* ((path (plist-get item :image))
           (image (and (display-graphic-p) path (file-readable-p path)
                       (condition-case nil
                           (create-image path nil nil :max-width my/media-poster-width
                                         :max-height my/media-poster-height :ascent 100)
                         (error nil))))
           (beg (point)))
      (insert (if path "[Poster]" "[No poster]"))
      (when image
        (my/media--overlay beg (point) 'display image 'priority 100))))

  (defun my/media--poster-row (items)
    (let ((beg (point)))
      (insert " ")
      ;; Reserve a constant row height, without distorting landscape covers.
      (when (display-graphic-p)
        (my/media--overlay beg (point) 'display
                           `(space :width (1) :height (,my/media-poster-height) :ascent 100))))
    (cl-loop for item in items for index from 0 do
             (when (> index 0) (my/media--align index))
             (my/media--poster item))
    (insert "\n"))

  (defun my/media--text-row (items lines row linkp)
    (cl-loop for item in items for parts in lines for index from 0 do
             (when (> index 0) (my/media--align index))
             (let ((text (nth row parts)) (beg (point)))
               (if (not text) (insert " ")
                 (if linkp
                     (insert (org-link-make-string
                              (concat "file:" (file-relative-name (plist-get item :file)
                                                                   (file-name-directory buffer-file-name)))
                              (replace-regexp-in-string "[][\n\r]" " " text)))
                   (insert text)))
               (my/media--overlay beg (point) 'face 'fixed-pitch)))
    (insert "\n"))

  (defun org-dblock-write:media-backlog (params)
    (let* ((type (or (plist-get params :type) "movies"))
           (columns (my/media--columns (max 1 (or (plist-get params :columns) 4))))
           (items (my/media--items type)))
      (if (null items) (insert "Бэклог пуст.\n")
        (while items
          (let (group)
            (dotimes (_ columns)
              (when items (push (pop items) group)))
            (setq group (nreverse group))
            (let ((titles (mapcar (lambda (i) (my/media--wrap (plist-get i :title))) group))
                  (authors (mapcar (lambda (i)
                                     (my/media--wrap (or (plist-get i :director)
                                                         (plist-get i :developer)))) group)))
              (my/media--poster-row group)
              (dotimes (row (apply #'max 0 (mapcar #'length titles)))
                (my/media--text-row group titles row t))
              (dotimes (row (apply #'max 0 (mapcar #'length authors)))
                (my/media--text-row group authors row nil))
              (insert "\n")))))))

  (defun my/media--render ()
    (let ((my/media--rendering t)
          (inhibit-read-only t)
          (was-modified (buffer-modified-p)))
      (my/media--clear)
      (org-remove-inline-images)
      (save-excursion
        (save-restriction
          (widen)
          (goto-char (point-min))
          (let ((case-fold-search t))
            (while (re-search-forward "^[ \t]*#\\+BEGIN:[ \t]+media-backlog\\(?:[ \t]\\|$\\)" nil t)
              (beginning-of-line)
              (save-excursion (org-update-dblock))
              (forward-line 1)))))
      (setq my/media--width (my/media--window-width))
      (font-lock-flush)
      (unless was-modified (set-buffer-modified-p nil))))

  (defun my/media-refresh-backlog ()
    (interactive)
    (unless (my/media--backlog-p) (user-error "Not the media backlog file"))
    (setq my/media--cache nil)
    (my/media--render))

  (defun my/media--resize-now (buffer)
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (setq my/media--timer nil)
        (let ((win (get-buffer-window buffer t)))
          (when (and win my/media--active (not my/media--rendering))
            (with-selected-window win
              (unless (equal my/media--width (my/media--window-width))
                (my/media--render))))))))

  (defun my/media--resize (&rest _)
    (when (and my/media--active (not my/media--rendering)
               (get-buffer-window (current-buffer) t)
               (not (equal my/media--width (my/media--window-width))))
      (when (timerp my/media--timer) (cancel-timer my/media--timer))
      (setq my/media--timer
            (run-with-idle-timer 0.2 nil #'my/media--resize-now (current-buffer)))))

  (defun my/media--cleanup ()
    (when (timerp my/media--timer) (cancel-timer my/media--timer))
    (setq my/media--timer nil))

  (defun my/media-backlog-auto-refresh ()
    (when (and (derived-mode-p 'org-mode) (my/media--backlog-p))
      (setq-local my/media--active t)
      (setq-local truncate-lines t)
      (when (bound-and-true-p org-indent-mode) (org-indent-mode -1))
      (when (bound-and-true-p display-line-numbers-mode) (display-line-numbers-mode -1))
      (add-hook 'window-size-change-functions #'my/media--resize nil t)
      (add-hook 'window-configuration-change-hook #'my/media--resize nil t)
      (add-hook 'kill-buffer-hook #'my/media--cleanup nil t)
      (my/media-refresh-backlog)))

  ;; Run after local file variables have been applied, not in org-mode-hook.
  (remove-hook 'org-mode-hook #'my/media-backlog-auto-refresh)
  (add-hook 'find-file-hook #'my/media-backlog-auto-refresh)
  (map! :map org-mode-map :localleader
        :desc "Refresh media backlog" "B" #'my/media-refresh-backlog))
