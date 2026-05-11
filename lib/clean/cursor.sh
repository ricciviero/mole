#!/bin/bash
# Cursor IDE Cleanup Module.
# Targets Electron caches, GPU caches, logs, AI tracking.
# Preserves: User/ (settings, snippets, keybindings), extensions/, projects/,
# skills-cursor/, IndexedDB/ (workspace state).
set -euo pipefail

is_cursor_running() {
    pgrep -x "Cursor" > /dev/null 2>&1
}

clean_cursor_data() {
    local desktop_root="$HOME/Library/Application Support/Cursor"

    if [[ -d "$desktop_root" ]]; then
        if is_cursor_running; then
            echo -e "  ${GRAY}${ICON_WARNING}${NC} Cursor is running · skipping locked Electron paths"
            note_activity
        else
            safe_clean "$desktop_root/Local Storage/"* "Cursor Local Storage"
            safe_clean "$desktop_root/Session Storage/"* "Cursor Session Storage"
        fi

        # Always-safe rebuildable caches.
        safe_clean "$desktop_root/Cache/"* "Cursor HTTP cache"
        safe_clean "$desktop_root/CachedData/"* "Cursor cached data"
        safe_clean "$desktop_root/CachedProfilesData/"* "Cursor cached profiles"
        safe_clean "$desktop_root/Code Cache/"* "Cursor code cache"
        safe_clean "$desktop_root/GPUCache/"* "Cursor GPU cache"
        safe_clean "$desktop_root/DawnGraphiteCache/"* "Cursor Dawn Graphite cache"
        safe_clean "$desktop_root/DawnWebGPUCache/"* "Cursor Dawn WebGPU cache"
        safe_clean "$desktop_root/Shared Dictionary/"* "Cursor shared dictionary"
        safe_clean "$desktop_root/logs/"* "Cursor app logs"

        # User/logs and User/History grow without bound; the rest of User/ is config.
        safe_clean "$desktop_root/User/logs/"* "Cursor user logs"
        safe_clean "$desktop_root/User/History/"* "Cursor file history"
        safe_clean "$desktop_root/User/workspaceStorage/"* "Cursor workspace storage cache"
    fi

    # CLI-side: AI tracking telemetry only. extensions/, projects/, skills-cursor/
    # and plugins/ hold user-installed assets — leave them alone.
    if [[ -d "$HOME/.cursor" ]]; then
        safe_clean ~/.cursor/ai-tracking/* "Cursor AI tracking logs"
    fi

    safe_clean "$HOME/Library/Logs/Cursor/"* "Cursor system logs"
}
