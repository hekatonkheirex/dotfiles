#!/usr/bin/env python3
import json, os, sys, re
from pathlib import Path

XDG_DATA_HOME = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
XDG_DATA_DIRS = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")

APP_DIRS = [
    XDG_DATA_HOME / "applications",
    *(Path(d) / "applications" for d in XDG_DATA_DIRS),
]

ICON_DIRS = []
for d in [XDG_DATA_HOME, *(Path(p) for p in XDG_DATA_DIRS)]:
    icon_dir = d / "icons"
    if icon_dir.exists():
        for themedir in icon_dir.iterdir():
            icondir = themedir / "apps"
            if icondir.exists():
                ICON_DIRS.append(icondir)
    hicolor = d / "icons" / "hicolor"
    if hicolor.exists():
        for szdir in hicolor.iterdir():
            icondir = szdir / "apps"
            if icondir.exists():
                ICON_DIRS.append(icondir)
ICON_DIRS.append(Path("/usr/share/pixmaps"))

def parse_desktop(path):
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return None
    entry = {}
    section = None
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            continue
        if section != "Desktop Entry":
            continue
        m = re.match(r"^([A-Za-z-]+)\[(.+)\]=(.*)", line)
        if m:
            key, lang, val = m.groups()
            if lang.startswith("en"):
                if key not in entry:
                    entry[key] = val.strip()
            continue
        m = re.match(r"^([A-Za-z-]+)=(.*)", line)
        if m:
            key, val = m.groups()
            if key not in entry:
                entry[key] = val.strip()
    return entry

def resolve_icon(icon_name):
    if not icon_name or icon_name.startswith("/"):
        return icon_name or ""
    for d in ICON_DIRS:
        for ext in (".png", ".svg", ".xpm", ".webp"):
            p = d / f"{icon_name}{ext}"
            if p.exists():
                return str(p)
    return ""

def main():
    apps = []
    seen = set()
    for appdir in APP_DIRS:
        if not appdir.exists():
            continue
        for f in sorted(appdir.iterdir()):
            if f.suffix != ".desktop":
                continue
            entry = parse_desktop(f)
            if not entry:
                continue
            no_display = entry.get("NoDisplay", "false").lower()
            if no_display in ("true", "1"):
                continue
            name = entry.get("Name", f.stem)
            exec_cmd = entry.get("Exec", "")
            if not exec_cmd:
                continue
            key = (name, exec_cmd)
            if key in seen:
                continue
            seen.add(key)
            icon_name = entry.get("Icon", "")
            apps.append({
                "name": name,
                "exec": exec_cmd,
                "icon": resolve_icon(icon_name),
                "comment": entry.get("Comment", ""),
                "terminal": entry.get("Terminal", "false").lower() == "true",
            })
    apps.sort(key=lambda a: a["name"].lower())
    print(json.dumps(apps))

if __name__ == "__main__":
    main()
