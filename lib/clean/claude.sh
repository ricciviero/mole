#!/bin/bash
# Claude (Code CLI + Desktop) Cleanup Module.
# Targets caches, sandbox VM bundles, vector DB, plugin caches, session logs.
# Preserves auth, user memories, installed skills/commands and plugin data dirs.
set -euo pipefail

# Returns 0 when Claude Desktop appears to be running. Used to skip cleanup of
# paths Electron may hold open (vm_bundles, Local Storage, IndexedDB).
# `pgrep -x "Claude"` missed the main process on macOS when Electron registered
# it under a Helper-style argv[0]; match the bundle path instead so we catch
# every helper (Renderer, GPU, Plugin, Utility, crashpad). The "Claude.app/"
# anchor avoids false positives with unrelated processes that happen to mention
# the word "claude".
is_claude_desktop_running() {
    pgrep -fi "Claude\.app/" > /dev/null 2>&1
}

# Claude CLI (~/.claude) — non-essential caches, logs, transcripts, history.
# Preserves: ~/.claude.json, settings.json, memory/, plugins/data/,
# commands/, skills/, plans/ — anything the user authored or that holds auth.
clean_claude_cli() {
    safe_clean ~/.claude/projects/* "Claude Code session transcripts"
    safe_clean ~/.claude/file-history/* "Claude Code file edit history"
    safe_clean ~/.claude/shell-snapshots/* "Claude Code shell snapshots"
    safe_clean ~/.claude/paste-cache/* "Claude Code paste cache"
    safe_clean ~/.claude/downloads/* "Claude Code downloads"
    safe_clean ~/.claude/debug/* "Claude Code debug logs"
    safe_clean ~/.claude/telemetry/* "Claude Code telemetry"
    safe_clean ~/.claude/statsig/* "Claude Code statsig cache"
    safe_clean ~/.claude/cache/* "Claude Code generic cache"
    safe_clean ~/.claude/backups/* "Claude Code backups"
    safe_clean ~/.claude/tasks/* "Claude Code task state"
    safe_clean ~/.claude/todos/* "Claude Code todo state"
    safe_clean ~/.claude/sessions/* "Claude Code session metadata"
    safe_clean ~/.claude/session-env/* "Claude Code session env"
    safe_clean ~/.claude/ide/* "Claude Code IDE lockfiles"
}

# Plugin caches (claude-mem, marketplaces, redistributables).
# data/ is the per-plugin persistent state — leave it alone.
clean_claude_plugin_caches() {
    safe_clean ~/.claude/plugins/cache/* "Claude plugin caches (claude-mem, etc.)"
    safe_clean ~/.claude/plugins/marketplaces/* "Claude plugin marketplace mirrors"
}

# Vector DB used by claude-mem MCP and its uv-installed Python deps.
clean_claude_chroma() {
    safe_clean ~/.cache/chroma/* "claude-mem chroma vector DB"

    # uv is shared by other tools, but its archive/wheel cache rebuilds itself
    # on next install — prefer the official command when available.
    if command -v uv > /dev/null 2>&1; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo -e "  ${YELLOW}${ICON_DRY_RUN}${NC} uv package cache · would run: uv cache clean"
            note_activity
        else
            if [[ -t 1 ]]; then
                start_section_spinner "Cleaning uv package cache..."
            fi
            if uv cache clean > /dev/null 2>&1; then
                if [[ -t 1 ]]; then
                    stop_section_spinner
                fi
                echo -e "  ${GREEN}${ICON_SUCCESS}${NC} uv package cache"
                note_activity
            else
                if [[ -t 1 ]]; then
                    stop_section_spinner
                fi
                debug_log "uv cache clean failed"
            fi
        fi
    fi
}

# Claude Desktop (Electron app) Application Support data.
# vm_bundles + Local Storage + IndexedDB stay locked while the app runs,
# so we gate those behind a process check. Everything else is safe to touch.
clean_claude_desktop() {
    local desktop_root="$HOME/Library/Application Support/Claude"
    [[ -d "$desktop_root" ]] || return 0

    if is_claude_desktop_running; then
        echo -e "  ${GRAY}${ICON_WARNING}${NC} Claude Desktop is running · skipping locked Electron paths (vm_bundles, Local Storage, IndexedDB)"
        note_activity
    else
        # The big one — Claude sandbox VM disk image, regenerated on next launch.
        safe_clean "$desktop_root/vm_bundles" "Claude Desktop sandbox VM bundle"
        safe_clean "$desktop_root/Local Storage/"* "Claude Desktop Local Storage"
        safe_clean "$desktop_root/Session Storage/"* "Claude Desktop Session Storage"
        safe_clean "$desktop_root/IndexedDB/"* "Claude Desktop IndexedDB"
    fi

    # These are always safe to clear — pure caches the app rebuilds on demand.
    safe_clean "$desktop_root/claude-code-vm/"* "Claude Desktop claude-code VM state"
    safe_clean "$desktop_root/claude-code/"* "Claude Desktop claude-code cache"
    safe_clean "$desktop_root/Cache/"* "Claude Desktop HTTP cache"
    safe_clean "$desktop_root/Code Cache/"* "Claude Desktop code cache"
    safe_clean "$desktop_root/GPUCache/"* "Claude Desktop GPU cache"
    safe_clean "$desktop_root/DawnGraphiteCache/"* "Claude Desktop Dawn Graphite cache"
    safe_clean "$desktop_root/DawnWebGPUCache/"* "Claude Desktop Dawn WebGPU cache"
    safe_clean "$desktop_root/Shared Dictionary/"* "Claude Desktop shared dictionary"
    safe_clean "$desktop_root/local-agent-mode-sessions/"* "Claude Desktop agent-mode sessions"
    safe_clean "$desktop_root/claude-code-sessions/"* "Claude Desktop claude-code sessions"
    safe_clean "$desktop_root/blob_storage/"* "Claude Desktop blob storage"

    safe_clean "$HOME/Library/Logs/Claude/"* "Claude Desktop logs"
    safe_clean "$HOME/Library/Caches/com.anthropic.claudefordesktop/"* "Claude Desktop system cache"
}

# Top-level entrypoint called from bin/clean.sh.
clean_claude_data() {
    clean_claude_cli
    clean_claude_plugin_caches
    clean_claude_chroma
    clean_claude_desktop
}
