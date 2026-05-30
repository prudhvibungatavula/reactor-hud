# ⚛️ Reactor HUD

> A KDE Plasma 6 system monitor widget with a terminal / sci-fi HUD aesthetic.  
> Built for daily use. Looks like it belongs in a spaceship.

---

## Preview

![preview](preview.png)

---

## Features

| Feature | Description |
|---|---|
| `█▓░` ASCII load bars | CPU, RAM, Storage, iGPU, dGPU — all animated |
| Reactor Uptime Clock | Live HH:MM:SS.ms uptime counter |
| Meltdown Clock | Battery time remaining with discharge rate |
| Process Monitor | Top background processes with RAM usage |
| Fan Indicators | Animated spinning fan chars `[ / ]` with RPM |
| GPU States | dGPU shows OFFLINE in red when powered down |
| Scan Line Effect | Slow CRT-style scan line sweeps the widget |
| Thermal Alerts | Bars turn orange >60%, red at critical temps |
| Bracket Connectors | Custom `┌ └` bracket UI connecting bars to data |

---

## Screenshots

> Add your own screenshots here after install

---

## Dependencies

### Required
- **KDE Plasma 6** — widget platform
- **lm-sensors** — CPU temp, fan RPM
  ```bash
  sudo pacman -S lm_sensors        # Arch
  sudo apt install lm-sensors      # Debian/Ubuntu
  sudo sensors-detect              # run once after install
  ```
- **JetBrains Mono** font
  ```bash
  sudo pacman -S ttf-jetbrains-mono
  ```
- `ps`, `df` — standard Linux utils (pre-installed)

### Optional
- **nvidia-smi** — dGPU stats (NVIDIA only). Widget gracefully shows offline state if unavailable
- **KSysGuard sensors** — iGPU load via `gpu/gpu0/usage` sensor

---

## Install

```bash
git clone https://github.com/prudhvibungatavula/reactor-hud
cd reactor-hud
bash install.sh
```

Then in KDE:
1. Right click desktop → **Add Widgets**
2. Search **Reactor HUD**
3. Drag onto desktop or panel

---

## File Structure

```
reactor-hud/
├── README.md               — this file
├── install.sh              — automated install script
│
├── plasmoid/               — the KDE widget package
│   ├── metadata.json       — widget ID, name, author info
│   └── contents/
│       ├── reactor.png     — widget icon
│       └── ui/
│           └── main.qml   — all widget logic and layout
│
└── scripts/                — shell scripts called by the widget
    └── sys/
        ├── sys_cpu_temp.sh     — reads CPU package temp via lm-sensors
        ├── sys_gpu_temp.sh     — reads GPU temp (nvidia-smi or sensors fallback)
        ├── sys_nvme_temp.sh    — reads NVMe SSD temp via lm-sensors
        ├── sys_fan_rpm.sh      — reads CPU/GPU fan RPM via lm-sensors
        ├── sys_fan_spin.sh     — animated fan character helper
        ├── sys_workspace.sh    — reads active KDE workspace number
        └── sys_procs.sh        — top processes by RAM usage
```

---

## How It Works

```
KDE Plasma
    └── main.qml (QML + JavaScript)
            ├── P5Support.DataSource  →  executes shell scripts every N seconds
            │       ├── sys_cpu_temp.sh   →  sensors coretemp → plain integer
            │       ├── sys_gpu_temp.sh   →  nvidia-smi or sensors fallback
            │       ├── sys_nvme_temp.sh  →  sensors nvme composite
            │       ├── sys_fan_rpm.sh    →  sensors asus-isa fan values
            │       ├── sys_workspace.sh  →  KDE workspace ID
            │       └── sys_procs.sh      →  ps sorted by RSS
            │
            ├── Sensors.Sensor  →  KSysGuard live sensors (no scripts needed)
            │       ├── cpu/all/usage      →  CPU load %
            │       ├── memory/physical/*  →  RAM used/total
            │       └── gpu/gpu0/usage     →  iGPU load %
            │
            ├── nvidia-smi (direct)  →  dGPU util, temp, VRAM, watts
            ├── /proc/uptime         →  raw seconds for reactor clock
            └── df -P /              →  disk used/total/pct
```

---

## Customisation

All theme values are at the top of `main.qml`:

```qml
readonly property string mainColor:  "#e8e8e8"   // main text
readonly property string dimColor:   "#4b9da7"   // labels
readonly property string lineColor:  "#61afef"   // borders
readonly property string orangeColor:"#ff8c00"   // warnings
readonly property string redColor:   "#ff4444"   // critical
readonly property string fontFam:    "JetBrains Mono"
```

Widget size:
```qml
Layout.preferredWidth:  260 * dpr
Layout.preferredHeight: 950 * dpr
```

---

## Updating

After editing `main.qml` locally:

```bash
cd ~/reactor-hud
cp ~/.local/share/plasma/plasmoids/com.socrates.reactorhud/contents/ui/main.qml plasmoid/contents/ui/
git add .
git commit -m "your change description"
git push
```

---

## Hardware Tested On

- ASUS laptop with Intel iGPU + NVIDIA dGPU
- KDE Plasma 6 on Arch Linux
- Kernel 7.0.10

---

## Author

**Prudhvi Akash Bungatavula**  
[github.com/prudhvibungatavula](https://github.com/prudhvibungatavula)

---

## License

GPL-3.0-or-later
