#!/usr/bin/env bash
# Gate check for the shell `popup` IPC: every name opens and reports itself,
# an unknown name returns false, and dismissPopups clears the state.
set -u
fail=0
for n in audio brightness media weather llm battery notification calendar quickmenu launcher sidebar networks; do
  qs ipc call shell dismissPopups >/dev/null; sleep 0.4
  r=$(qs ipc call shell popup "$n"); c=$(qs ipc call shell currentPopup)
  if [ "$r" = true ] && [ "$c" = "$n" ]; then echo "ok   $n"; else echo "FAIL $n (popup=$r current=$c)"; fail=1; fi
done
qs ipc call shell dismissPopups >/dev/null
[ "$(qs ipc call shell popup nope)" = false ] && echo "ok   unknown -> false" || { echo "FAIL unknown name"; fail=1; }
[ -z "$(qs ipc call shell currentPopup)" ] && echo "ok   dismissed" || { echo "FAIL not dismissed"; fail=1; }
# In-memory Settings tab selection round-trips (restores the persisted value).
orig=$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.config/quickshell/settings.json')))['lastSettingsTab'])")
[ "$(qs ipc call shell settingsTab 5)" = 5 ] && echo "ok   settingsTab" || { echo "FAIL settingsTab"; fail=1; }
qs ipc call shell settingsTab "$orig" >/dev/null
# forgetPrompt opens the networks window with the confirmation row only (no
# forget runs); "" clears the row.
qs ipc call shell dismissPopups >/dev/null; sleep 0.4
r=$(qs ipc call shell forgetPrompt ProbeNet); c=$(qs ipc call shell currentPopup)
[ "$r" = ProbeNet ] && [ "$c" = networks ] && echo "ok   forgetPrompt opens networks" || { echo "FAIL forgetPrompt open ($r, $c)"; fail=1; }
[ "$(qs ipc call shell forgetPrompt "")" = "" ] && echo "ok   forgetPrompt clears" || { echo "FAIL forgetPrompt"; fail=1; }
qs ipc call shell dismissPopups >/dev/null
# Bottom-bar page toggle: closed opens, same page closes, another page switches.
qs ipc call shell dismissPopups >/dev/null; sleep 0.4
qs ipc call shell openSidebarPage 2 >/dev/null
[ "$(qs ipc call shell currentPopup)" = sidebar ] && echo "ok   openSidebarPage opens" || { echo "FAIL openSidebarPage open"; fail=1; }
qs ipc call shell openSidebarPage 2 >/dev/null
[ -z "$(qs ipc call shell currentPopup)" ] && echo "ok   openSidebarPage same page closes" || { echo "FAIL openSidebarPage close"; fail=1; }
qs ipc call shell openSidebarPage 0 >/dev/null; qs ipc call shell openSidebarPage 1 >/dev/null
[ "$(qs ipc call shell currentPopup)" = sidebar ] && echo "ok   openSidebarPage switches" || { echo "FAIL openSidebarPage switch"; fail=1; }
page=$(qs ipc call shell bottomBarState | jq -r .page)
[ "$page" = 1 ] && echo "ok   openSidebarPage page 1" || { echo "FAIL openSidebarPage page ($page)"; fail=1; }
qs ipc call shell openSidebarPage 2 >/dev/null
page=$(qs ipc call shell bottomBarState | jq -r .page)
[ "$page" = 2 ] && echo "ok   openSidebarPage page 2 (media)" || { echo "FAIL openSidebarPage page 2 ($page)"; fail=1; }
qs ipc call shell dismissPopups >/dev/null
exit $fail
