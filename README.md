# Arch Linux Rice

## My personal Arch Linux config

---

> ### _-- Disclaimer --_
>
> _I am not a developer/programmer, just a Linux enthusiast. All these
> configurations are just what I learned along the way by myself. You may
> encounter some redundant lines of code._

---

![Screenshot](https://i.imgur.com/WhXSclg.png)

- **Distro** • [Arch Linux](https://archlinux.org/) 🐧
- **Window Manager** • Main - [Niri](https://niri-wm.github.io/niri/) 🔥
- **Window Manager** • Backup - [MangoWM](https://mangowm.github.io/) 🥭
- **Colorscheme** • Custom made Apple's macOS 26 Tahoe Dark Liquid Glass
lookalike 🍎
  - **Backup Colorscheme** • [Oxocarbon](https://github.com/nyoom-engineering/oxocarbon)
  💻
  - **Backup Colorscheme** • [Catppuccin](https://github.com/catppuccin) 🐈
  - **Backup Colorscheme** • [Gruvbox](https://github.com/gruvbox-community/gruvbox)
    🌈
  - **Backup Colorscheme** • [Rose Pine](https://rosepinetheme.com) 🌹

- **Shell** • [Zsh](https://www.zsh.org) 🐚 with
  - [zinit](https://github.com/zdharma-continuum/zinit) 💤
  - [Starship](https://github.com/starship/starship) 🚀
- **Terminal** • [Kitty](https://sw.kovidgoyal.net/kitty/) 🐈
- **Panel** • [Waybar](https://github.com/Alexays/Waybar) 🍫
- **Notification Daemon** •
  [mako](https://github.com/emersion/mako) 🔔
- **Launcher** • [Rofi](https://github.com/davatorium/rofi) ⚓
- **File Manager** • [Nautilus](https://apps.gnome.org/Nautilus/) 🗄️
- **Editor** • [Neovim](https://neovim.io/) 📝
- **Backup Editor** • [Zed](https://zed.dev/) 📝

## Before installation note

_You can review the `pkglist-official.txt` and `pkglist-aur.txt` files to
remove the packages you don't want and replace the ones you like, but I
cannot guarantee if they don't work as expected. Please, read the
disclaimer_

## Installation

1. Do a fresh Arch Linux installation. _Remember to install `git` package
   during installation_. _You can also install on your existing installation,
   just skip to section 5_.
2. Install `paru`. _You can install whatever version you like_. _You can also
use whatever AUR helper you want, but remember to uninstall `paru` at the end
of the installation or remove the `paru` line inside the `pkglist-aur.txt` file_

```bash
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

1. Fork this repository or download it.
2. If you forked it, use [yadm](https://yadm.io/) to download your forked repo.

```bash
yadm clone https://github.com/youruser/yourforkedrepo.git
```

1. If you downloaded it or cloned it, copy everything to your home directory
   (all the .config and .local directory, and all the _" . "_ files as well).
2. Use `paru` (or the AUR helper of choice) to install everything in the
   `pkglist-official.txt` and `pkglist-aur.txt` file. _You can use `pacman`
   too, but it won't install the AUR packages_.

```bash
paru -S --needed (cat pkglist-official.txt)
paru -S --needed (cat pkglist-aur.txt)
```

## Useful configurations for Thinkpads/laptops

In `.config/thinkpad` added some useful configuration files that need to be put
under root permissions.

- `00-macrandomize.conf`: This file is a NetworkManager rule and needs to be put
  in `/etc/NetworkManager/conf.d/`. After that, restart the systemd service with
  `systemctl restart NetworkManager`.
- `99-backlight-automation.rules`: This is an UDEV rule that needs to be in `/etc/udev/rules.d/`.
- `backlight_auto.sh`: This is the "application" that runs the UDEV rule mentioned
  before. What this does is set the display backlight to 30% when using battery
  and 100% when plugged in.
- `grub`: This is the GRUB configuration. It is designed to not display all the
  init commands and shows a nice splash logo, with the help of plymouth.
- `login`, `logind.conf`, `sddm`, `system-auth` and `system-local-login`: All
  files needed to unlock the Thinkpad with the fingerprint sensor. `sddm`,
  `login`, `system-auth` and `system-local-login` go into `/etc/pam.d/`,
  `logind.conf` goes into `/etc/systemd/`.
- `tlp.conf`: This needs to have the `tlp` package installed. This handles the
  power usage. Limits the charge thresholds, puts USB to autosuspend, and a lot
  more. This goes into `/etc/`. Also, this comes with a systemd service
  `sudo systemctl enable --now tlp.service`.
