#!/bin/bash
pacman -Qqen > "$HOME/pkglist-official.txt"
pacman -Qqem > "$HOME/pkglist-aur.txt"
