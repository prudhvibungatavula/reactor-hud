#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  sys_gpu_temp.sh
#  Outputs GPU temperature as a plain number (e.g. 59)
#  Tries nvidia-smi first, falls back to lm-sensors (AMD/integrated)
# ─────────────────────────────────────────────────────────────────────────────

# NVIDIA
if command -v nvidia-smi &>/dev/null; then
  temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
  if [[ -n "$temp" && "$temp" =~ ^[0-9]+$ ]]; then
    echo "$temp"
    exit 0
  fi
fi

# AMD / lm-sensors fallback
temp=$(sensors 2>/dev/null \
  | grep -E 'edge|GPU Temperature|junction' \
  | head -1 \
  | grep -oP '[+-]?\d+\.\d+(?=°C)' \
  | head -1 \
  | awk '{printf "%d", $1}')
echo "${temp:-0}"
