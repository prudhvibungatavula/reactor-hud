#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  Reactor HUD — Install Script
#  Author: Prudhvi Akash Bungatavula
# ─────────────────────────────────────────────────────────────────────────────

PLASMOID_ID="com.socrates.reactorhud"
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/$PLASMOID_ID"
SCRIPTS_DIR="$HOME/.config/reactor-hud/scripts"

echo "[ REACTOR HUD ] Installing..."

# copy plasmoid
mkdir -p "$PLASMOID_DIR/contents/ui"
cp plasmoid/metadata.json "$PLASMOID_DIR/"
cp plasmoid/contents/ui/main.qml "$PLASMOID_DIR/contents/ui/"
cp plasmoid/contents/reactor.png "$PLASMOID_DIR/contents/"

# copy scripts
mkdir -p "$SCRIPTS_DIR/sys"
cp scripts/sys/*.sh "$SCRIPTS_DIR/sys/"
chmod +x "$SCRIPTS_DIR/sys/"*.sh

echo "[ REACTOR HUD ] Done. Restart plasmashell to apply."
echo "  killall plasmashell; sleep 2; plasmashell &"
