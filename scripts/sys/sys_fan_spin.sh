#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  sys_fan_spin.sh
#  Outputs the next frame of a fan spinner: | / - \
#  Speed is proportional to RPM (faster rpm = faster frame advance)
#  Usage: ./sys_fan_spin.sh cpu
#         ./sys_fan_spin.sh gpu
# ─────────────────────────────────────────────────────────────────────────────
SPIN=('|' '/' '-' '\')
fan="${1:-cpu}"
cache="/tmp/${fan}_fan_frame"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load or init frame index
if [[ -f "$cache" ]]; then
  index=$(<"$cache")
else
  index=0
fi

# Get RPM
rpm=$("$script_dir/sys_fan_rpm.sh" "$fan" 2>/dev/null)
rpm="${rpm:-0}"

# Only advance frame if fan is spinning
if [[ "$rpm" -gt 100 ]]; then
  # Advance faster at higher RPM (skip frames at low RPM)
  # RPM 0-800: advance 1, 800-2000: advance 2, 2000+: advance 3
  if   [[ "$rpm" -ge 2000 ]]; then step=3
  elif [[ "$rpm" -ge 800  ]]; then step=2
  else                              step=1
  fi
  index=$(( (index + step) % ${#SPIN[@]} ))
  echo "$index" > "$cache"
  echo "${SPIN[$index]}"
else
  echo "|"
fi
