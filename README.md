# Hyprland-Arch Linux Rice

## My personal Hyprland config

___

> ### *-- Disclaimer --*
>
> *I am not a developer/programmer, just a Linux enthusiast. All this
configurations are just what I learned along the way by myself. You may
encounter some redundant lines of code.*
___
![Screenshot](https://i.imgur.com/nGGcmZY.png)

* **Distro** • [Arch Linux](https://archlinux.org/) 🐧
* **Window Manager** • [Hyprland](https://hyprland.org/) 💧
* **Colorscheme** • [Oxocarbon](https://github.com/nyoom-engineering/oxocarbon)
💻
  * **Backup Colorscheme** •  [Catppuccin](https://github.com/catppuccin) 🐈
  * **Backup Colorscheme** •  [Rose Pine](https://rosepinetheme.com) 🌹
* **Shell** • [Zsh](https://www.zsh.org) 🐚 with
  * [zinit](https://github.com/zdharma-continuum/zinit) 💤
  * [Starship](https://github.com/starship/starship) 🚀
* **Terminal** • [Kitty](https://sw.kovidgoyal.net/kitty/) 🐈
* **Panel** • [Waybar](https://github.com/Alexays/Waybar) 🍫
* **Notication Daemon** •
[Swaync](https://github.com/ErikReider/SwayNotificationCenter) 🔔
* **Launcher** • [Rofi](https://github.com/davatorium/rofi) ⚓ with
[rofimoji](https://github.com/fdw/rofimoji) 😐
* **File Manager** • [Nautilus](https://apps.gnome.org/Nautilus/) 🗄️
* **Editor** • [Neovim](https://neovim.io/) 📝
* **Backup Editor** • [Zed](https://zed.dev/) 📝
  
## Before installation note

*You can review the `pkglist.txt` file to remove the packages you don't want
and replace the ones you like, but I cannot guarantee if don't work as
expected. Please, read the disclaimer*

## Installation

1. Do a fresh Arch Linux installation. *Remember to install `git` package
during installation*. *You can also install on your existing installation,
just skip to section 5*.
2. Install `paru`. *You can install whatever version you like, I prefer the
binary version*. *You can also use whatever AUR helper you want, but remeber
to uninstall `paru` at the end of the installation or remove the `paru-bin`
line inside the `pkglist.txt` file*  

```bash
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si
```  

1. Fork this repository or download it.  
2. If you forked it, use [yadm](https://yadm.io/) to download your forked repo.

  ```bash
  yadm clone https://github.com/youruser/yourforkedrepo.git
  ```  

1. If you downloaded it or cloned it, copy everything to your home directory
(all the .config and .local directory, and all the *" . "* files as well).
2. Use `paru` (or the AUR helper of choice) to install everything in the
`pkglist.txt` file. *You can use `pacman` too, but it won't install the AUR
packages*.

```bash
paru -S --needed - < pkglist.txt
```
