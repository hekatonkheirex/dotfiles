#!/usr/bin/env bash
# Install the Siji bitmap icon font (siji-ng 1.2) used by the dwm style.
set -euo pipefail
dest="${HOME}/.local/share/fonts/misc"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
curl -fsSL -o "$work/s.tgz" https://github.com/begss/siji-ng/archive/refs/tags/v1.2.tar.gz
echo "01c12d033b9cca98ff9292951149949ecee85c9d14cd859ad260e050a40230ecc00c683a905459d0254115d578265a5ea67a81ea4b11e442f41078c45eb192dc  $work/s.tgz" | sha512sum -c -
tar xzf "$work/s.tgz" -C "$work"
src="$work/siji-ng-1.2"
(cd "$src" && PYTHONPATH=bin python3 bin/otb1cli.py -o siji.otb siji.bdf)
mkdir -p "$dest"
install -m644 "$src/siji.otb" "$dest/siji.otb"
fc-cache -f "$dest"
fc-list | grep -qi siji && echo "siji installed in $dest"
