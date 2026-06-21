# Arch Linux Rice & Custom Desktop Environment 🐧✨

This repository contains my personal configurations, customized scripts, and system optimization rules for a modern, fluid Wayland-based desktop environment built on top of the **Niri** window manager and a custom **Quickshell** shell.

---

![Desktop Screenshot](https://i.imgur.com/ljlYpNy.png)

---

> [!NOTE]
> All themes, scripts, and helper components are customized to form a unified, expressive ecosystem. Standard configuration tools have been replaced by custom QML panels and Python scripts to provide a fast and tailored user experience.

---

## 🎨 System Overview

- **Window Manager** • Main: [Niri](https://niri-wm.github.io/niri/) (Scroll-stacking Wayland compositor)
- **Desktop Shell & Panels** • Custom [Quickshell](https://quickshell.outfoxxed.me/) (QML-based status bar, widgets, volume/brightness popups, notifications, and desktop dashboard)
- **Theme Suite** • Custom Material Design 3 Expressive themes (supporting Blue, Green, Yellow, Red, Purple, and Orange variants)
- **Terminal** • [Kitty](https://sw.kovidgoyal.net/kitty/) configured with expressive dynamic themes
- **Shell** • Zsh with [zinit](https://github.com/zdharma-continuum/zinit) and [Starship](https://github.com/starship/starship) prompt
- **File Manager** • Gnome Nautilus

---

## 🛠️ Deep Dive: Custom Scripts & Utilities

To glue the desktop environment together, several custom scripts handle system triggers, application menus, voice commands, and power states.

### 💻 Quickshell Helpers (`.config/quickshell/`)

- **[`voice-search.py`](file:///.config/quickshell/scripts/voice-search.py)**: An offline voice recognition launcher search tool.
  - *What it does*: It uses the `python-vosk` library and a local offline speech-to-text Vosk model (automatically downloaded on first run, ~40MB) to transcribe recorded voice input and output search queries in plain text.
- **[`desktop-parser.py`](file:///.config/quickshell/bin/desktop-parser.py)**: An efficient desktop application parser.
  - *What it does*: It scans standard XDG applications paths (`/usr/share/applications`, `~/.local/share/applications`), extracts details from `.desktop` files, resolves application icons from your current icon themes, caches the results to `/tmp/qs-app-cache-<uid>.json` (with cache invalidation matched to the directories' modified timestamps), and outputs JSON data to feed the launcher panel.
- **[`idle.sh`](file:///.config/quickshell/scripts/idle.sh)**: Swayidle wrapper.
  - *What it does*: Handles multi-level inactivity timeouts:
    - **150 seconds**: Dims screen brightness to 10% (saving previous level).
    - **300 seconds**: Invokes the screen locker.
    - **600 seconds**: Shuts off monitor displays (using `niri` monitor controls or `wlopm`).
    - **900 seconds**: Puts the machine to sleep (`systemctl suspend`).
- **[`safe-logout.sh`](file:///.config/quickshell/scripts/safe-logout.sh)**: A clean session terminate utility.
  - *What it does*: First attempts composer-specific clean exits (e.g. `niri msg action quit` or `labwc --exit`). If the desktop environment remains active after a half-second grace period, it sends a direct `SIGKILL` to the active systemd session using `loginctl kill-session`.
- **Trigger Scripts (`launcher`, `lock`, `quickmenu`)**:
  - *What they do*: Simple wrappers that touch `/tmp/` trigger files (e.g., `/tmp/qslauncher-trigger`, `/tmp/qslock-trigger`, `/tmp/qsquickmenu-trigger`). The main Quickshell QML shell watches these files to toggle overlays and UI dashboards instantly.

### 🔋 Thinkpad / Laptop Optimizations (`.config/thinkpad/`)

System-level rules located in `.config/thinkpad` automate power management, security, and hardware features:

- **`tlp.conf`**: Power-saving settings that restrict battery charge thresholds (e.g., 75% to 80% to maintain battery health) and enable aggressive autosuspend for PCI/USB hardware.
- **`backlight_auto.sh` & `99-backlight-automation.rules`**: Auto-brightness triggers. Set display brightness to 100% on AC power and dim to 30% when operating on battery.
- **`throttled.conf`**: Configuration for `throttled` (lenovo-fix) to stop Intel CPU thermal throttling on laptops.
- **`00-macrandomize.conf`**: NetworkManager rule to randomize MAC addresses on Wi-Fi connections for enhanced privacy.
- **`zram-generator.conf`**: Enables compressed zram swap devices dynamically.
- **PAM Rules (`login`, `sddm`, `sddm-greeter`, `system-auth`, `system-local-login`)**: Configured to enable seamless fingerprint reader integration alongside passwords.
- **`timeshift-autosnap.conf`**: Triggers automated BTRFS snapshot backups immediately before `pacman` executes updates or modifications.

---

## 🚀 Installation & Bootstrapping

We provide an interactive installer that checks package dependencies, configures an AUR helper, installs standard/AUR packages, and copies system configurations.

### Method A: YADM (Recommended)

[yadm](https://yadm.io/) allows you to clone this repository directly into your home folder and manages it seamlessly.

1. Perform a fresh Arch Linux installation. Make sure `git` is installed.
2. Clone the repository using `yadm`:

    ```bash
    yadm clone https://github.com/youruser/yourforkedrepo.git
    ```

3. The bootstrap script will trigger automatically. You can also re-trigger it at any time:

    ```bash
    yadm bootstrap
    ```

### Method B: Standard Git Clone

If you prefer not to use `yadm`, you can download and run the script manually:

1. Clone this repository:

    ```bash
    git clone https://github.com/youruser/yourforkedrepo.git ~/dotfiles-temp
    cd ~/dotfiles-temp
    ```

2. Execute the installation script:

    ```bash
    ./install.sh
    ```

3. Merge the configuration files to your home directory:

    ```bash
    cp -ri .config/ .local/ ~/
    cp -ri .zshrc .zsh ~/
    ```

---

## 🔒 Disclaimer & Support

> [!CAUTION]
> Applying system-level configuration files (like PAM, GRUB, and UDEV rules) modifies core system operations. The bootstrap installer creates automatic backups (`.bak` files) of existing configurations, but you should review system changes before rebooting.
