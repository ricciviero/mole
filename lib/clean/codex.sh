#!/bin/bash
# Codex CLI Cleanup Module.
# Targets archived/active session logs, shell snapshots, vendor imports, debug logs.
# Preserves: config.toml, memories/, rules/, skills/, plugins/, sqlite/ (auth).
set -euo pipefail

clean_codex_data() {
    [[ -d "$HOME/.codex" ]] || return 0

    # Archived sessions dominate disk usage on heavy use (often >500 MB/week).
    safe_clean ~/.codex/archived_sessions/* "Codex archived session transcripts"
    safe_clean ~/.codex/sessions/* "Codex active session transcripts"
    safe_clean ~/.codex/log/* "Codex CLI logs"
    safe_clean ~/.codex/cache/* "Codex CLI cache"
    safe_clean ~/.codex/shell_snapshots/* "Codex shell snapshots"
    safe_clean ~/.codex/tmp/* "Codex temp files"
    safe_clean ~/.codex/vendor_imports/* "Codex vendored plugin imports"
}
