#!/bin/bash
# Mole - Status command.
# Runs the Go system status panel.
# Shows live system metrics.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GO_BIN="$SCRIPT_DIR/status-go"
if [[ -x "$GO_BIN" ]]; then
    "$GO_BIN" "$@"
    rc=$?
    # Exit code 64 from status-go means "return to Mole main menu".
    if [[ $rc -eq 64 ]]; then
        if [[ -n "${MOLE_BIN:-}" && -x "${MOLE_BIN}" ]]; then
            exec "${MOLE_BIN}"
        fi
        exit 0
    fi
    exit "$rc"
fi

echo "Bundled status binary not found. Please reinstall Mole or run mo update to restore it." >&2
exit 1
