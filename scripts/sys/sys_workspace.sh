#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  sys_workspace.sh
#  Prints workspace 1–4 status: [ ACTIVE ] or [INACTIVE]
#  Works with KDE Plasma (qdbus) and Hyprland (hyprctl) — auto-detects
# ─────────────────────────────────────────────────────────────────────────────

# Detect compositor
if command -v hyprctl &>/dev/null && hyprctl activeworkspace &>/dev/null 2>&1; then
  # Hyprland
  CURRENT=$(hyprctl activeworkspace -j 2>/dev/null | grep -oP '"id":\s*\K\d+' | head -1)
elif command -v qdbus &>/dev/null; then
  # KDE Plasma — VirtualDesktop number
  CURRENT=$(qdbus org.kde.KWin /VirtualDesktopManager currentDesktop 2>/dev/null \
    | grep -oP '\d+$' | head -1)
  # qdbus returns a UUID on newer Plasma; map to number
  if [[ -z "$CURRENT" || ! "$CURRENT" =~ ^[0-9]+$ ]]; then
    CURRENT=$(qdbus org.kde.KWin /VirtualDesktopManager desktops 2>/dev/null \
      | grep -n "$(qdbus org.kde.KWin /VirtualDesktopManager currentDesktop 2>/dev/null)" \
      | cut -d: -f1)
    CURRENT=$(( (CURRENT + 1) / 2 ))
  fi
else
  CURRENT=1
fi

[[ -z "$CURRENT" || ! "$CURRENT" =~ ^[0-9]+$ ]] && CURRENT=1

for i in {1..4}; do
  if [[ "$i" -eq "$CURRENT" ]]; then
    echo "ws${i}= [ ACTIVE ]"
  else
    echo "ws${i}= [INACTIVE]"
  fi
done
