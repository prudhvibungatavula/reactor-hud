# Reactor HUD

A KDE Plasma system monitor widget with a terminal/HUD aesthetic.

## Features
- Live CPU, RAM, Storage, iGPU, dGPU load bars with █▓░ ASCII art
- Battery time remaining + discharge rate
- Reactor uptime clock
- Background process list with RAM usage
- Animated fan spin indicators
- Scan line effect

## Dependencies
- KDE Plasma 6
- `lm-sensors` — CPU/fan temps
- `nvidia-smi` — dGPU stats (optional, shows offline state if unavailable)
- `JetBrains Mono` font
- `ps`, `df` — standard Linux utils

## Install
```bash
git clone https://github.com/prudhvibungatavula/reactor-hud
cd reactor-hud
bash install.sh
```

Then add the widget in KDE: Right click desktop → Add Widgets → search **Reactor HUD**

## File Structure
## Author
Prudhvi Akash Bungatavula
