#!/bin/bash
set -euo pipefail

SID="${1:?Usage: multiview-grid.sh <SID> <LEAD_PANE_ID>}"
LEAD="${2:?Usage: multiview-grid.sh <SID> <LEAD_PANE_ID>}"

split() { tmux split-window "$@" -d -P -F '#{pane_id}'; }
title() { tmux select-pane -t "$1" -T "$2"; }

# New grid creation only. Reuse decisions are made by sdd-start via state.yaml + grid-check.sh.
title "$LEAD" "sdd-${SID}-lead"
WINDOW_ID=$(tmux display-message -t "$LEAD" -p '#{window_id}')

CREATED=()
cleanup() {
  for pid in "${CREATED[@]}"; do
    tmux kill-pane -t "$pid" 2>/dev/null || true
  done
}
trap cleanup ERR

BOTTOM=$(split -v -p 50 -t "$LEAD"); CREATED+=("$BOTTOM")
RIGHT=$(split -h -p 50 -t "$LEAD"); CREATED+=("$RIGHT")

TR_TOP=$RIGHT
TR_BOT=$(split -v -p 50 -t "$RIGHT"); CREATED+=("$TR_BOT")
S1=$TR_TOP
S2=$(split -h -p 50 -t "$TR_TOP"); CREATED+=("$S2")
S3=$TR_BOT
S4=$(split -h -p 50 -t "$TR_BOT"); CREATED+=("$S4")

BL_TOP=$BOTTOM
BL_BOT=$(split -v -p 50 -t "$BOTTOM"); CREATED+=("$BL_BOT")
BR_TOP=$(split -h -p 50 -t "$BL_TOP"); CREATED+=("$BR_TOP")
BR_BOT=$(split -h -p 50 -t "$BL_BOT"); CREATED+=("$BR_BOT")

S5=$BL_TOP
S6=$(split -h -p 50 -t "$BL_TOP"); CREATED+=("$S6")
S7=$BL_BOT
S8=$(split -h -p 50 -t "$BL_BOT"); CREATED+=("$S8")

S9=$BR_TOP
S10=$(split -h -p 50 -t "$BR_TOP"); CREATED+=("$S10")
S11=$BR_BOT
S12=$(split -h -p 50 -t "$BR_BOT"); CREATED+=("$S12")

SLOTS=("$S1" "$S2" "$S3" "$S4" "$S5" "$S6" "$S7" "$S8" "$S9" "$S10" "$S11" "$S12")

for i in "${!SLOTS[@]}"; do
  title "${SLOTS[$i]}" "sdd-${SID}-slot-$((i+1))"
done

trap - ERR

tmux set-option -w -t "$WINDOW_ID" pane-border-status top
tmux set-option -w -t "$WINDOW_ID" pane-border-format " #{pane_title} "

echo "window_id:${WINDOW_ID}"
for i in "${!SLOTS[@]}"; do
  echo "slot-$((i+1)):${SLOTS[$i]}"
done
