#!/usr/bin/env bash
# sys_fan_rpm.sh — outputs fan RPM as plain integer, 0 if not found
fan="${1:-cpu}"

if [[ "$fan" == "cpu" ]]; then
  rpm=$(sensors 2>/dev/null \
    | grep -iE 'cpu_fan|fan1|cpu fan' \
    | head -1 \
    | grep -oP '\d+(?= RPM)')

elif [[ "$fan" == "gpu" ]]; then
  # NVIDIA via nvidia-smi (returns %)
  if command -v nvidia-smi &>/dev/null; then
    pct=$(nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits 2>/dev/null \
      | head -1 | tr -d ' %')
    if [[ "$pct" =~ ^[0-9]+$ ]]; then
      rpm=$(( pct * 28 ))
    fi
  fi
  # lm-sensors fallback
  if [[ -z "$rpm" || "$rpm" == "0" ]]; then
    rpm=$(sensors 2>/dev/null \
      | grep -iE 'gpu_fan|fan2|fan3' \
      | head -1 \
      | grep -oP '\d+(?= RPM)')
  fi
fi

# Sanitize — must be a plain integer
rpm="${rpm//[^0-9]/}"
echo "${rpm:-0}"
