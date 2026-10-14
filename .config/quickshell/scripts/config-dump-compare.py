#!/usr/bin/env python3
"""Compare two config dumps. Usage: config-dump-compare.py BASE NEW ALLOW.json

ALLOW.json: {"removed": ["Config.legacyFlag", ...], "removedPrefixes": [...],
             "changed": {"Config.shapeLarge": [16, 20]}, "added": ["Config.newKey"]}
Exit 1 when a key disappears, changes value, or appears without being allowed.
"""
import json, sys

base = json.load(open(sys.argv[1]))
new = json.load(open(sys.argv[2]))
allow = json.load(open(sys.argv[3]))
removed_ok = set(allow.get("removed", []))
prefixes = tuple(allow.get("removedPrefixes", []))
changed_ok = allow.get("changed", {})
added_ok = set(allow.get("added", []))

problems = []
for k in sorted(base):
    if k not in new:
        if k in removed_ok or k.startswith(prefixes):
            continue
        problems.append(f"missing  {k} (was {base[k]!r})")
    elif new[k] != base[k]:
        exp = changed_ok.get(k)
        if exp is not None and exp[0] == base[k] and exp[1] == new[k]:
            continue
        problems.append(f"changed  {k}: {base[k]!r} -> {new[k]!r}")
for k in sorted(new):
    if k not in base and k not in added_ok:
        problems.append(f"added    {k} = {new[k]!r}")

if problems:
    print("\n".join(problems))
    print(f"config-dump: {len(problems)} unexplained difference(s)")
    sys.exit(1)
print(f"config-dump: ok ({len(new)} keys, {len(base) - len(new)} removed)")
