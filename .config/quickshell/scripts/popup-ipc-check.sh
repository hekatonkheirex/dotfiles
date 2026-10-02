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
exit $fail
