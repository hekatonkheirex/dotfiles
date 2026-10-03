#!/usr/bin/env bash
# Gate check for the shell `popup` IPC: every name opens and reports itself,
# an unknown name returns false, and dismissPopups clears the state.
set -u
fail=0
for n in audio brightness media weather battery notification calendar quickmenu launcher; do
  qs ipc call shell dismissPopups >/dev/null; sleep 0.4
  r=$(qs ipc call shell popup "$n"); c=$(qs ipc call shell currentPopup)
  if [ "$r" = true ] && [ "$c" = "$n" ]; then echo "ok   $n"; else echo "FAIL $n (popup=$r current=$c)"; fail=1; fi
done
qs ipc call shell dismissPopups >/dev/null
[ "$(qs ipc call shell popup nope)" = false ] && echo "ok   unknown -> false" || { echo "FAIL unknown name"; fail=1; }
[ -z "$(qs ipc call shell currentPopup)" ] && echo "ok   dismissed" || { echo "FAIL not dismissed"; fail=1; }
# In-memory style switch (never saved) round-trips.
[ "$(qs ipc call shell style ghost "")" = ghost ] && echo "ok   style ghost" || { echo "FAIL style ghost"; fail=1; }
[ "$(qs ipc call shell style material3 "")" = material3 ] && echo "ok   style material3" || { echo "FAIL style material3"; fail=1; }
# In-memory Settings tab selection round-trips (restores the persisted value).
orig=$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.config/quickshell/settings.json')))['lastSettingsTab'])")
[ "$(qs ipc call shell settingsTab 5)" = 5 ] && echo "ok   settingsTab" || { echo "FAIL settingsTab"; fail=1; }
qs ipc call shell settingsTab "$orig" >/dev/null
[ "$(qs ipc call shell forgetPrompt "")" = "" ] && echo "ok   forgetPrompt clears" || { echo "FAIL forgetPrompt"; fail=1; }
exit $fail
