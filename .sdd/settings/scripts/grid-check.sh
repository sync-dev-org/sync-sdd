#!/bin/bash
set -euo pipefail

WINDOW_ID="${1:?Usage: grid-check.sh <WINDOW_ID> <PANE_ID1> [PANE_ID2 ...]}"
shift

LIVE=$(tmux list-panes -t "$WINDOW_ID" -F '#{pane_id}' 2>/dev/null) || exit 1

ALL_ALIVE=true
for pid in "$@"; do
  if echo "$LIVE" | grep -qx "$pid"; then
    echo "$pid"
  else
    ALL_ALIVE=false
  fi
done

$ALL_ALIVE && exit 0 || exit 1
