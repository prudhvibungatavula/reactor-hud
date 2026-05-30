#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  sys_nvme_temp.sh
#  Outputs NVMe temperature as a plain number (e.g. 38)
#  Requires: lm-sensors or nvme-cli
# ─────────────────────────────────────────────────────────────────────────────

# Try lm-sensors first (nvme hwmon)
temp=$(sensors 2>/dev/null \
  | grep -E 'Composite|nvme' \
  | grep -i 'composite\|temp1' \
  | head -1 \
  | grep -oP '[+-]?\d+\.\d+(?=°C)' \
  | head -1 \
  | awk '{printf "%d", $1}')

# Fallback: nvme-cli
if [[ -z "$temp" || "$temp" == "0" ]]; then
  if command -v nvme &>/dev/null; then
    dev=$(ls /dev/nvme?n1 2>/dev/null | head -1)
    if [[ -n "$dev" ]]; then
      temp=$(nvme smart-log "$dev" 2>/dev/null \
        | grep 'temperature' \
        | head -1 \
        | grep -oP '\d+(?= C)')
    fi
  fi
fi

echo "${temp:-0}"
