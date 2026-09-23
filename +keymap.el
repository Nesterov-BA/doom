;;; +keymap.el -*- lexical-binding: t; -*-

(map! :n "gj" #'evil-next-line
      :n "j"  #'evil-next-visual-line
      :n "gk" #'evil-previous-line
      :n "k"  #'evil-previous-visual-line
      :v "gj" #'evil-next-line
      :v "j"  #'evil-next-visual-line
      :v "gk" #'evil-previous-line
      :v "k"  #'evil-previous-visual-line)

(map! :n "g$" #'evil-end-of-line
      :n "$"  #'evil-end-of-visual-line
      :n "g0" #'evil-beginning-of-line
      :n "0"  #'evil-beginning-of-visual-line
      :v "g$" #'evil-end-of-line
      :v "$"  #'evil-end-of-visual-line
      :v "g0" #'evil-beginning-of-line
      :v "0"  #'evil-beginning-of-visual-line)
