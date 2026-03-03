#!/bin/bash
set -euo pipefail

SID="${1:?Usage: multiview-grid.sh <SID> <LEAD_PANE_ID>}"
LEAD="${2:?Usage: multiview-grid.sh <SID> <LEAD_PANE_ID>}"

split() { tmux split-window "$@" -d -P -F '#{pane_id}'; }
title() { tmux select-pane -t "$1" -T "$2"; }

title "$LEAD" "sdd-${SID}-lead"

BOTTOM=$(split -v -p 50 -t "$LEAD")
RIGHT=$(split -h -p 50 -t "$LEAD")

TR_TOP=$RIGHT
TR_BOT=$(split -v -p 50 -t "$RIGHT")
S1=$TR_TOP
S2=$(split -h -p 50 -t "$TR_TOP")
S3=$TR_BOT
S4=$(split -h -p 50 -t "$TR_BOT")

BL_TOP=$BOTTOM
BL_BOT=$(split -v -p 50 -t "$BOTTOM")
BR_TOP=$(split -h -p 50 -t "$BL_TOP")
BR_BOT=$(split -h -p 50 -t "$BL_BOT")

S5=$BL_TOP
S6=$(split -h -p 50 -t "$BL_TOP")
S7=$BL_BOT
S8=$(split -h -p 50 -t "$BL_BOT")

S9=$BR_TOP
S10=$(split -h -p 50 -t "$BR_TOP")
S11=$BR_BOT
S12=$(split -h -p 50 -t "$BR_BOT")

SLOTS=("$S1" "$S2" "$S3" "$S4" "$S5" "$S6" "$S7" "$S8" "$S9" "$S10" "$S11" "$S12")

for i in "${!SLOTS[@]}"; do
  title "${SLOTS[$i]}" "sdd-${SID}-slot-$((i+1))"
done

for i in "${!SLOTS[@]}"; do
  echo "slot-$((i+1)):${SLOTS[$i]}"
done
