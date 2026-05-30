#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  sys_cpu_temp.sh
#  Outputs CPU temperature as a plain number (e.g. 72)
#  Requires: lm-sensors (run `sensors-detect` once first)
# ─────────────────────────────────────────────────────────────────────────────
temp=$(sensors 2>/dev/null \
  | grep -E 'Tctl|Tdie|Package id 0|CPU Temperature|Core 0' \
  | head -1 \
  | grep -oP '[+-]?\d+\.\d+(?=°C)' \
  | head -1 \
  | awk '{printf "%d", $1}')
echo "${temp:-0}"
