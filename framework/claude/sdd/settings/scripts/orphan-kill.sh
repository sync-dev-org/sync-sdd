#!/bin/bash
set -euo pipefail

for pid in "$@"; do
  tmux kill-pane -t "$pid" 2>/dev/null || true
done
