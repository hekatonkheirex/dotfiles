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
- **Theme Suite** • Four selectable Quickshell UI styles: Material 3, Neo Brutalism, Nothing, and Ghost, with shared desktop synchronization
- **Terminal** • [Kitty](https://sw.kovidgoyal.net/kitty/) configured with expressive dynamic themes
- **Shell** • Zsh with [zinit](https://github.com/zdharma-continuum/zinit) and [Starship](https://github.com/starship/starship) prompt
- **File Manager** • Gnome Nautilus

### Current Quickshell configuration and styles

Quickshell is a single QML shell rooted at [`shell.qml`](.config/quickshell/shell.qml). It owns the bar, launcher, Quick Menu, Command Center, popups, notifications, OSD, lock screen, and shared desktop state. The bar supports top, bottom, left, and right placement, plus continuous full-bar and floating-pills layouts.

The current tracked state is `layout=left`, `fullBar=true`, automatic color mode (`themePreference=0`), Material 3 UI style (`themeStyle=material3`), and `colorscheme=matugen` for terminal/Niri synchronization. These values are persisted in [`settings.json`](.config/quickshell/settings.json), [`layout`](.config/quickshell/layout), and [`colorscheme`](.config/quickshell/colorscheme); the supported values remain configurable from the Appearance panel.

The two Quickshell UI styles share the same semantic palette and controls:

- **Material 3**: Roboto Flex typography, tonal surface elevation, expressive corner radii, and soft focus/elevation treatment.
- **Neo Brutalism**: JetBrains Mono typography, high-contrast semantic ink, heavier borders, compact radii, and hard offset shadows. Its Niri gaps, focus ring, window radius, and shadow are synchronized by the existing theme scripts.

The style changes geometry and ink treatment only. It does not replace the Matugen palette. The shell-specific file map is documented in [`~/.config/quickshell/README.md`](.config/quickshell/README.md).

The generated GTK/Qt desktop themes are named `Material3-Expressive-Dynamic` and `Material3-Expressive-Dynamic-Dark`; they are synchronized independently from the Quickshell UI style.

---

## 🛠️ Deep Dive: Custom Scripts & Utilities

To glue the desktop environment together, several custom scripts handle system triggers, application menus, voice commands, and power states.

### 💻 Quickshell Helpers (`.config/quickshell/`)

- **[`voice-search.py`](.config/quickshell/scripts/voice-search.py)**: An offline voice recognition launcher search tool.
  - *What it does*: It uses the `python-vosk` library and a local offline speech-to-text Vosk model (automatically downloaded on first run, ~40MB) to transcribe recorded voice input and output search queries in plain text.
- **[`desktop-parser.py`](.config/quickshell/bin/desktop-parser.py)**: An efficient desktop application parser.
  - *What it does*: It scans standard XDG applications paths (`/usr/share/applications`, `~/.local/share/applications`), extracts details from `.desktop` files, resolves application icons from your current icon themes, caches the results to `/tmp/qs-app-cache-<uid>.json` (with cache invalidation matched to the directories' modified timestamps), and outputs JSON data to feed the launcher panel.
- **[`idle.sh`](.config/quickshell/scripts/idle.sh)**: Swayidle wrapper.
  - *What it does*: Handles multi-level inactivity timeouts:
    - **150 seconds**: Dims screen brightness to 10% (saving previous level).
    - **300 seconds by default**: Invokes the screen locker (configurable through `idleLockTimeoutSeconds`).
    - **600 seconds**: Shuts off monitor displays (using `niri` monitor controls or `wlopm`).
    - **900 seconds by default**: Puts the machine to sleep (`systemctl suspend`, configurable through `idleSuspendTimeoutSeconds`).
- **[`safe-logout.sh`](.config/quickshell/scripts/safe-logout.sh)**: A clean session terminate utility.
  - *What it does*: First attempts composer-specific clean exits (e.g. `niri msg action quit`). If the desktop environment remains active after a half-second grace period, it sends a direct `SIGKILL` to the active systemd session using `loginctl kill-session`.
- **Trigger Scripts (`launcher`, `quickmenu`, `commandcenter`, `lock`)**:
  - *What they do*: Simple wrappers that touch `/tmp/` trigger files (e.g., `/tmp/qslauncher-trigger`, `/tmp/qslock-trigger`, `/tmp/qsquickmenu-trigger`). The main Quickshell QML shell watches these files to toggle overlays and UI dashboards instantly.

### 🎨 Material You Theming Pipeline

Quickshell's semantic colors are wallpaper-derived through **matugen**. The authored light and dark roles in `config/Colors.qml` are deterministic first-boot fallbacks; they are not the primary palette source.

- **[`matugen-and-cache.sh`](.local/bin/matugen-and-cache.sh)**: Runs `matugen --type scheme-fidelity --prefer saturation`, caches both light and dark semantic roles in `~/.cache/matugen/current_palette.json` under `scheme-expressive`, and regenerates the Quickshell `Colors.qml` template.
- **[`generate-all-themes.sh`](.local/bin/generate-all-themes.sh)**: Regenerates the dynamic Material 3 and Neo GTK, icon, SDDM, and Kvantum outputs from the cached palette. The fixed Nothing and Ghost assets are installed by the UI suite installer.
- **[`sync-theme-mode.sh`](.local/bin/sync-theme-mode.sh)**: Applies `light`, `dark`, or `auto` mode across GNOME settings, GTK 3/4, Libadwaita CSS links, Kvantum, Qt6ct, icons, Kitty, and Niri.
- **[`auto-detect-theme.sh`](.local/bin/auto-detect-theme.sh)**: Reads the current wallpaper from the awww cache, measures its mean brightness with ImageMagick, and returns `light` or `dark` for automatic mode.
- **[`sync-terminal-theme.sh`](.local/bin/sync-terminal-theme.sh)**: Synchronizes Kitty, Starship/fzf, btop, Neovim state, and generated Niri decoration colors. It accepts the `matugen` or `claude` terminal palette selector and the Quickshell `material3`, `neo-brutalism`, `nothing`, or `ghost` UI style.

The theming flow:
1. [`apply-wallpaper.sh`](.config/quickshell/scripts/apply-wallpaper.sh) applies the selected wallpaper with `awww` first.
2. `matugen-and-cache.sh` refreshes the light/dark role cache and Quickshell template.
3. `generate-all-themes.sh` rebuilds the GTK, icon, SDDM, and Kvantum themes.
4. `sync-theme-mode.sh auto` detects the wallpaper brightness and applies the matching desktop mode.
5. Quickshell restarts so `Colors.qml` loads the fresh palette.

The tracked [`colorscheme`](.config/quickshell/colorscheme) is currently `matugen`. `claude` is available as a fixed alternate palette for Kitty and Niri synchronization; Quickshell itself continues to consume the Matugen role cache. [`apply-accent-color.sh`](.config/quickshell/scripts/apply-accent-color.sh) remains only as a compatibility entry point and does not provide runtime accent editing.

Theme changes are runtime settings now; switching between Material 3, Neo Brutalism, Nothing, or Ghost, or between light, dark, and automatic mode, does not require a yadm branch checkout.

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

We provide an interactive installer that checks package dependencies, configures an AUR helper, installs standard/AUR packages, copies system configurations, and can clone/build/install the four UI style families without storing generated theme assets in yadm.

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

   The final bootstrap step offers to clone the theme sources into `~/Projects`, run their existing installers, install the system SDDM themes and bridge, and synchronize the active desktop. The source projects and generated outputs remain outside yadm.

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
