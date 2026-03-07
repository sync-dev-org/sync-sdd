#!/bin/bash
# sdd-start exclusive — does NOT distinguish busy/idle slots.
# All non-Lead panes from previous session are reported as orphans.
# Do NOT call from other contexts without adding busy/idle filtering.
set -euo pipefail

MODE="${1:?Usage: orphan-detect.sh <primary|fallback> ...}"

if [ "$MODE" = "primary" ]; then
  WINDOW_ID="${2:?Usage: orphan-detect.sh primary <WINDOW_ID> <MY_PANE> [PANE_IDS...]}"
  MY_PANE="${3:?}"
  shift 3
  LIVE=$(tmux list-panes -t "$WINDOW_ID" -F '#{pane_id}' 2>/dev/null) || exit 0
  for pid in "$@"; do
    [ "$pid" = "$MY_PANE" ] && continue
    echo "$LIVE" | grep -qx "$pid" && echo "$pid"
  done
elif [ "$MODE" = "fallback" ]; then
  MY_PANE="${2:?Usage: orphan-detect.sh fallback <MY_PANE> <CURRENT_SID>}"
  CURRENT_SID="${3:?}"
  PANES=$(tmux list-panes -F '#{pane_id} #{pane_title}' 2>/dev/null) || exit 0
  echo "$PANES" | while read -r pid title; do
    [ "$pid" = "$MY_PANE" ] && continue
    case "$title" in sdd-*) ;; *) continue ;; esac
    case "$title" in sdd-"${CURRENT_SID}"-*) continue ;; esac
    echo "$pid $title"
  done
fi
