#!/usr/bin/env bash
# Runs every gate: node wiring/model tests, python tests, qmllint, render checks.
# Exits nonzero on the first failing group. Render checks open scratch qs windows.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0
run() { printf '== %s\n' "$1"; shift; "$@" >/tmp/qs-check.out 2>&1 || { fail=1; tail -15 /tmp/qs-check.out; }; }
for t in $(find tests -name '*.test.mjs' -o -name test.mjs | sort); do run "$t" node "$t"; done
run pytest python3 -m pytest -q -p no:cacheprovider scripts/tests scripts/niri_config
run qmllint bash scripts/m3-qmllint-gate.sh
for s in controls-render controls-behavior sidebar-render bottom-bar-render powermenu-render \
         networks-render r6-render tag-strip-render settings-sidebar-render; do
  run "$s" bash "scripts/$s.sh"
done
run config-dump bash scripts/config-dump.sh check
rm -f /tmp/qs-check.out
[ "$fail" = 0 ] && echo "ALL GATES PASS" || { echo "GATE FAILURES"; exit 1; }
