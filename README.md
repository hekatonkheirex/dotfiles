# Arch Linux Rice

## My personal Arch Linux config

---

> ### _-- Disclaimer --_
>
> _I am not a developer/programmer, just a Linux enthusiast. All these
> configurations are just what I learned along the way by myself. You may
> encounter some redundant lines of code._

---

![Screenshot](https://i.imgur.com/ljlYpNy.png)

- **Distro** • [Arch Linux](https://archlinux.org/) 🐧
- **Window Manager** • Main - [Niri](https://niri-wm.github.io/niri/) 🔥
- **Window Manager** • Backup - [MangoWM](https://mangowm.github.io/) 🥭
- **Colorscheme** • Main - Custom made Material Design 3 Expressive theme suite (Blue, Green, Yellow, Red, Purple, Orange) 🎨
- **Colorscheme** • Backup - Custom made Apple's macOS 26 Tahoe Dark Liquid Glass lookalike 🍎
- **Shell** • [Zsh](https://www.zsh.org) 🐚 with
  - [zinit](https://github.com/zdharma-continuum/zinit) 💤
  - [Starship](https://github.com/starship/starship) 🚀
- **Terminal** • [Kitty](https://sw.kovidgoyal.net/kitty/) 🐈
- **Panel / Desktop Shell** • Custom [Quickshell](https://quickshell.outfoxxed.me/) QML-based status bar, dashboard, and widgets 🐚 (replaces Waybar)
- **Lock Screen** • Custom [Quickshell](https://quickshell.outfoxxed.me/) lock screen with PAM + fingerprint authentication 🔒
- **Notification Daemon** • Custom [Quickshell](https://quickshell.outfoxxed.me/) notification toasts & history 🔔
- **Launcher** • Custom [Quickshell](https://quickshell.outfoxxed.me/) app launcher with offline voice search 🎙️
- **Icon Theme** • Custom Material Design 3 Expressive folders with specific category glyphs 📁 (inherits Adwaita/hicolor)
- **Kvantum Theme** • Custom Material Design 3 Expressive Qt themes 🎨
- **File Manager** • [Nautilus](https://apps.gnome.org/Nautilus/) 🗄️
- **Editor** • [Neovim](https://neovim.io/) 📝
- **Backup Editor** • [Zed](https://zed.dev/) 📝

## Before installation note

_You can review the `pkglist-official.txt` and `pkglist-aur.txt` files to
remove the packages you don't want and replace the ones you like, but I
cannot guarantee if they don't work as expected. Please, read the
disclaimer_

## Installation

There are two ways to install and manage these dotfiles: **Method A (Recommended)** using `yadm`, or **Method B** using a standard `git clone`.

Both methods leverage the built-in bootstrap script (`install.sh` / `.config/yadm/bootstrap`), which will automatically:
1. Detect or install `paru` (AUR helper) if not present.
2. Install official packages from `pkglist-official.txt`.
3. Install AUR packages from `pkglist-aur.txt`.
4. Prompt you to copy laptop/Thinkpad-specific configurations to `/etc` and `/usr/local/bin` (creating backups of existing files first).
5. Optionally regenerate your GRUB configuration and enable/restart systemd services (`tlp`, `throttled`, `NetworkManager`).

---

### Method A: Using YADM (Recommended)
[yadm](https://yadm.io/) is a tool designed specifically for managing dotfiles in your home directory directly.

1. Do a fresh Arch Linux installation (ensure `git` is installed).
2. Clone your repository directly into your home folder using `yadm`:
   ```bash
   yadm clone https://github.com/youruser/yourforkedrepo.git
   ```
3. The bootstrap script should run automatically upon clone. If it doesn't, or you want to run it again manually, run:
   ```bash
   yadm bootstrap
   ```

---

### Method B: Standard Git Clone
If you prefer not to use `yadm`, you can clone the repository normally and use the wrapper script.

1. Clone this repository to a temporary directory:
   ```bash
   git clone https://github.com/youruser/yourforkedrepo.git ~/dotfiles-temp
   cd ~/dotfiles-temp
   ```
2. Run the installation script:
   ```bash
   ./install.sh
   ```
3. Copy the configuration files to your home directory:
   ```bash
   # Copy config and local directories to your home folder
   cp -ri .config/ .local/ ~/
   # Copy other dotfiles (e.g. .zshrc, .zsh)
   cp -ri .zshrc .zsh ~/
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
- `login`, `logind.conf`, `sddm`, `sddm-greeter`, `gtklock`, `system-auth` and
`system-local-login`: All files needed to unlock the Thinkpad with the
fingerprint sensor. `sddm`, `sddm-greeter`, `gtklock`, `login`, `system-auth`
and `system-local-login` go into `/etc/pam.d/`, `logind.conf` goes into `/etc/systemd/`.
- `tlp.conf`: This needs to have the `tlp` package installed. This handles the
  power usage. Limits the charge thresholds, puts USB to autosuspend, and a lot
  more. This goes into `/etc/`. Also, this comes with a systemd service
  `sudo systemctl enable --now tlp.service`.
- `makepkg.conf` goes in `/etc/`. This is for faster linking AUR builds
(requires `mold` package).
- `journald.conf` goes in `/etc/systemd/`. Limits journal size from default
(10% of disk) to 200MB.
- `zram-generator` goes in `/etc/systemd/`. This enables zram swap (requires
`zram-generator` package).
- `timeshift-autosnap.conf` goes in `/etc/`. This enables btrfs backups when
  installing/upgrading/uninstalling packages.

---

## Disclaimer

Part of these configuration files and theme builders were generated and vibe-coded with the assistance of **Antigravity**, an AI agentic coding assistant designed by the Google DeepMind team. Each one affected by vide coding was added an expecific README file.
