#!/usr/bin/env bash
# Get the window ID for the current pane
# Usage: window-id.sh
# Output: window ID (e.g., @0)
tmux display-message -p '#{window_id}'
