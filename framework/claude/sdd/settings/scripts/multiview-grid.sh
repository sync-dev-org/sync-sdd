#!/bin/bash
set -euo pipefail

SID="${1:?Usage: multiview-grid.sh <SID> <LEAD_PANE_ID>}"
LEAD="${2:?Usage: multiview-grid.sh <SID> <LEAD_PANE_ID>}"

OTHER_LEADS=$(tmux list-panes -a -F '#{pane_title}' | grep -c '^sdd-.*-lead$' || true)
if [ "$OTHER_LEADS" -ge 2 ]; then
  echo "ERROR: Max 2 Leads reached. Grid creation skipped." >&2
  exit 1
fi

split() { tmux split-window "$@" -d -P -F '#{pane_id}'; }
title() { tmux select-pane -t "$1" -T "$2"; }

title "$LEAD" "sdd-${SID}-lead"

BOTTOM=$(split -v -p 67 -t "$LEAD")
RIGHT=$(split -h -p 33 -t "$LEAD")

S1=$RIGHT
S2=$(split -v -p 50 -t "$RIGHT")

MID_RIGHT=$(split -h -p 67 -t "$BOTTOM")
LEFT=$BOTTOM
RIGHT_COL=$(split -h -p 50 -t "$MID_RIGHT")
MID=$MID_RIGHT

L1=$LEFT;  L2=$(split -v -p 75 -t "$LEFT")
L3=$(split -v -p 67 -t "$L2"); L4=$(split -v -p 50 -t "$L3")

M1=$MID;   M2=$(split -v -p 75 -t "$MID")
M3=$(split -v -p 67 -t "$M2"); M4=$(split -v -p 50 -t "$M3")

R1=$RIGHT_COL; R2=$(split -v -p 75 -t "$RIGHT_COL")
R3=$(split -v -p 67 -t "$R2"); R4=$(split -v -p 50 -t "$R3")

SLOTS=("$S1" "$S2" "$L1" "$M1" "$R1" "$L2" "$M2" "$R2" "$L3" "$M3" "$R3" "$L4" "$M4" "$R4")

for i in "${!SLOTS[@]}"; do
  title "${SLOTS[$i]}" "sdd-${SID}-slot-$((i+1))"
done

for i in "${!SLOTS[@]}"; do
  echo "slot-$((i+1)):${SLOTS[$i]}"
done
