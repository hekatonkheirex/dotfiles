#!/usr/bin/env bash

# Exit on error
set -e

# Resolve the absolute path of this script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_SCRIPT="$SCRIPT_DIR/.config/yadm/bootstrap"

# Check if bootstrap script exists
if [ -f "$BOOTSTRAP_SCRIPT" ]; then
    # Ensure it's executable
    chmod +x "$BOOTSTRAP_SCRIPT"
    # Execute the bootstrap script and pass all arguments along
    exec "$BOOTSTRAP_SCRIPT" "$@"
else
    echo "Error: Bootstrap script not found at $BOOTSTRAP_SCRIPT" >&2
    exit 1
fi
