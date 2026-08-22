#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir/.."

qmllint shell.qml \
  config/*.qml \
  bar/*.qml \
  bar/settings/*.qml \
  bar/primitives/*.qml \
  bar/themes/material3/*.qml \
  bar/themes/neo_brutalism/*.qml \
  bar/themes/nothing/*.qml \
  bar/themes/ghost/*.qml
