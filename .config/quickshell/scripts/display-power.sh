#!/usr/bin/env sh
set -eu

case "${1:-}" in
    on|off)
        action="$1"
        ;;
    *)
        printf 'usage: %s {on|off}\n' "$0" >&2
        exit 2
        ;;
esac

outputs=$(/usr/bin/wlopm --json | /usr/bin/jq -r '.[].output')
if [ -z "$outputs" ]; then
    exit 0
fi

status=0
while IFS= read -r output; do
    [ -n "$output" ] || continue
    if ! /usr/bin/wlopm "--$action" "$output"; then
        status=1
    fi
done <<EOF
$outputs
EOF

exit "$status"
