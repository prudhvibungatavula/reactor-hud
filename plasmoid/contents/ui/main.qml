import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    readonly property string scriptPath: "/home/akash/.config/reactor-hud/scripts"

    // ── DATA SOURCES ─────────────────────────────────────────────────────────

    // Fans — from asus-isa-000a via sensors (confirmed: cpu=2800, gpu=2600)
    P5Support.DataSource {
        id: cpuFanSrc; engine: "executable"
        connectedSources: ["bash -c \"sensors asus-isa-000a 2>/dev/null | grep 'cpu_fan' | grep -oP '[0-9]+' | head -1\""]
        interval: 2000; property string value: "0"
        onNewData: (src, data) => { value = (data["stdout"] || "0").trim() }
    }
    P5Support.DataSource {
        id: gpuFanSrc; engine: "executable"
        connectedSources: ["bash -c \"sensors asus-isa-000a 2>/dev/null | grep 'gpu_fan' | grep -oP '[0-9]+' | head -1\""]
        interval: 2000; property string value: "0"
        onNewData: (src, data) => { value = (data["stdout"] || "0").trim() }
    }

    // CPU temp — sys_cpu_temp.sh (confirmed: outputs 69)
    P5Support.DataSource {
        id: cpuTempSrc; engine: "executable"
        connectedSources: [scriptPath + "/sys/sys_cpu_temp.sh"]
        interval: 2000; property string value: "0"
        onNewData: (src, data) => { value = (data["stdout"] || "0").trim() }
    }

    // NVME temp — sys_nvme_temp.sh (confirmed: outputs 42)
    P5Support.DataSource {
        id: nvmeTempSrc; engine: "executable"
        connectedSources: [scriptPath + "/sys/sys_nvme_temp.sh"]
        interval: 5000; property string value: "0"
        onNewData: (src, data) => { value = (data["stdout"] || "0").trim() }
    }

    Sensors.Sensor { id: igpuLoadS; sensorId: "gpu/gpu0/usage" }


    // dGPU — nvidia-smi: util,temp,memUsed,memTotal,watts
    P5Support.DataSource {
        id: nvidiaSrc; engine: "executable"
        connectedSources: ["bash -c \"nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' '\""]
        interval: 2000; property string value: ""
        onNewData: (src, data) => { value = (data["stdout"] || "").trim() }
    }

    // Workspace
    P5Support.DataSource {
        id: workspaceSrc; engine: "executable"
        connectedSources: [scriptPath + "/sys/sys_workspace.sh"]
        interval: 1000; property string value: ""
        onNewData: (src, data) => { value = (data["stdout"] || "").trim() }
    }

    // Uptime — raw seconds
    P5Support.DataSource {
        id: uptimeSrc; engine: "executable"
        connectedSources: ["bash -c \"cut -d. -f1 /proc/uptime\""]
        interval: 1000; property string value: "0"
        onNewData: (src, data) => { value = (data["stdout"] || "0").trim() }
    }

    // Kernel + loadavg
    P5Support.DataSource {
        id: sysinfoSrc; engine: "executable"
        connectedSources: ["bash -c \"echo $(uname -r | cut -d- -f1); cat /proc/loadavg | awk '{print $1}'\""]
        interval: 5000; property string value: ""
        onNewData: (src, data) => { value = (data["stdout"] || "").trim() }
    }

    // Disk — python reads df output, zero quoting issues
    P5Support.DataSource {
        id: diskSrc; engine: "executable"
        connectedSources: ["python3 -c \"import subprocess; o=subprocess.check_output(['df','-P','/']).decode().split('\\n')[1].split(); print(o[2],o[1],o[4])\""]
        interval: 10000; property string value: "0 1 0%"
        onNewData: (src, data) => { value = (data["stdout"] || "0 1 0%").trim() }
    }

    // Battery BAT1
    P5Support.DataSource {
        id: batCapSrc; engine: "executable"
        connectedSources: ["bash -c \"cat /sys/class/power_supply/BAT1/capacity\""]
        interval: 10000; property string value: "0"
        onNewData: (src, data) => { value = (data["stdout"] || "0").trim() }
    }
    P5Support.DataSource {
        id: batStatusSrc; engine: "executable"
        connectedSources: ["bash -c \"cat /sys/class/power_supply/BAT1/status\""]
        interval: 5000; property string value: "Unknown"
        onNewData: (src, data) => { value = (data["stdout"] || "Unknown").trim() }
    }
    P5Support.DataSource {
        id: batCurrentSrc; engine: "executable"
        connectedSources: ["bash -c \"cat /sys/class/power_supply/BAT1/current_now\""]
        interval: 10000; property string value: "0"
        onNewData: (src, data) => { value = (data["stdout"] || "0").trim() }
    }
    P5Support.DataSource {
        id: batVoltageSrc; engine: "executable"
        connectedSources: ["bash -c \"cat /sys/class/power_supply/BAT1/voltage_now\""]
        interval: 10000; property string value: "17139000"
        onNewData: (src, data) => { value = (data["stdout"] || "17139000").trim() }
    }

    P5Support.DataSource {
        id: procSrc; engine: "executable"
        connectedSources: [scriptPath + "/sys/sys_procs.sh"]
        interval: 5000; property string value: ""
        onNewData: (src, data) => { value = (data["stdout"] || "").trim() }
    }

    Sensors.Sensor { id: cpuSensor;  sensorId: "cpu/all/usage" }
    Sensors.Sensor { id: ramUsedS;   sensorId: "memory/physical/used" }
    Sensors.Sensor { id: ramTotalS;  sensorId: "memory/physical/total" }

    // ── FULL REPRESENTATION ──────────────────────────────────────────────────
    fullRepresentation: Item {
        id: container
        readonly property real dpr: Screen.devicePixelRatio
        Layout.preferredWidth:  260 * dpr
        Layout.preferredHeight: 950 * dpr
        Layout.minimumWidth:    100 * dpr
        Layout.minimumHeight:   300 * dpr
        width:  Layout.preferredWidth
        height: Layout.preferredHeight
        property real s: width / 330
        clip: true

        // ── THEME ─────────────────────────────────────────────────────────
        readonly property string fontFam:    "JetBrains Mono"
        readonly property string mainColor:  "#e8e8e8"   // white text
        readonly property string dimColor:   "#4b9da7"   // dim labels
        readonly property string lineColor:  "#61afef"   // borders/lines
        readonly property string orangeColor:"#ff8c00"
        readonly property string redColor:   "#ff4444"

        // ── COMPUTED VALUES ───────────────────────────────────────────────
        property int   cpuRpm:    parseInt(cpuFanSrc.value)   || 0
        property int   gpuRpm:    parseInt(gpuFanSrc.value)   || 0
        property int   cpuTemp:   parseInt(cpuTempSrc.value)  || 0
        property int   nvmeTemp:  parseInt(nvmeTempSrc.value) || 0
        property real  igpuLoad:  igpuLoadS.value || 0

        // dGPU — parse "41,57,91,12282,18.61"
        property var   nvArr:      nvidiaSrc.value.split(",")
        property bool  nvidiaOk:   nvidiaSrc.value.trim() !== "" && nvArr.length >= 5 && parseInt(nvArr[0]) >= 0
        property int   nvUtil:     nvidiaOk ? (parseInt(nvArr[0])   || 0) : 0
        property int   nvTemp:     nvidiaOk ? (parseInt(nvArr[1])   || 0) : 0
        property int   nvMemUsed:  nvidiaOk ? (parseInt(nvArr[2])   || 0) : 0
        property int   nvMemTotal: nvidiaOk ? (parseInt(nvArr[3])   || 1) : 1
        property real  nvWatts:    nvidiaOk ? (parseFloat(nvArr[4]) || 0) : 0

        property real  realCpu:    cpuSensor.value  || 0
        property real  realRam:    ramTotalS.value > 0 ? (ramUsedS.value / ramTotalS.value * 100) : 0
        property real  ramUsedGb:  ramTotalS.value > 0 ? ramUsedS.value  / 1073741824 : 0
        property real  ramTotGb:   ramTotalS.value > 0 ? ramTotalS.value / 1073741824 : 0

        // Disk — Number() preserves precision on large KB values (confirmed 998903672)
        property real   diskUsedKb:  Number(diskSrc.value.split(" ")[0]) || 0
        property real   diskTotalKb: Number(diskSrc.value.split(" ")[1]) || 1
        property int    diskPct:     parseInt((diskSrc.value.split(" ")[2] || "0%").replace("%","")) || 0
        property string diskUsed:    (diskUsedKb  / 1048576.0).toFixed(0) + "G"
        property string diskTotal:   (diskTotalKb / 1048576.0).toFixed(0) + "G"

        // Battery
        property int    batPct:     parseInt(batCapSrc.value)       || 0
        property string batStatus:  batStatusSrc.value              || "Unknown"
        property real   batCurUa:   parseFloat(batCurrentSrc.value) || 0
        property real   batVolUv:   parseFloat(batVoltageSrc.value) || 0
        property real   batWatts:   (batCurUa * batVolUv) / 1000000000000.0
        property bool   onBattery:  batStatus === "Discharging"
        property string meltdownDisplay: {
            if (batStatus === "Full")     return "  FULL  "
                if (batStatus === "Charging") return "CHARGING"
                    if (!onBattery)               return "  A/C   "
                        if (batWatts < 0.1)           return "--:--"
                            let wh  = batPct / 100.0 * 50.0
                            let hrs = wh / batWatts
                            let h   = Math.floor(hrs)
                            let mn  = Math.floor((hrs - h) * 60)
                            return (h<10?"0"+h:h) + ":" + (mn<10?"0"+mn:mn)
        }

        // Uptime
        property int    uptimeSecs: parseInt(uptimeSrc.value) || 0
        property string reactorUptime: {
            let h  = Math.floor(uptimeSecs / 3600)
            let m  = Math.floor((uptimeSecs % 3600) / 60)
            let sc = uptimeSecs % 60
            let ms = (tick * 50) % 1000
            return (h<10?"0"+h:h)+":"+(m<10?"0"+m:m)+":"+(sc<10?"0"+sc:sc)+"."+(ms<100?(ms<10?"00"+ms:"0"+ms):ms)
        }

        property string kernelVer:  sysinfoSrc.value.split("\n")[0] || "?"
        property string load1:      sysinfoSrc.value.split("\n")[1] || "?"
        property var procList: procSrc.value !== "" ? procSrc.value.split("\n").filter(l => l.trim() !== "") : []

        // Workspace
        property int activeWs: 1
        function parseActiveWs(raw) {
            let lines = raw.split("\n")
            for (let l of lines)
                if (l.indexOf("[ ACTIVE ]") !== -1) {
                    let m = l.match(/ws(\d+)/)
                    if (m) return parseInt(m[1])
                }
                return 1
        }

        // ── ANIMATION ─────────────────────────────────────────────────────
        property int    tick:        0
        property real   cpuFanFrame: 0.0
        property real   gpuFanFrame: 0.0

        property real pulseOpacity: 1.0
        SequentialAnimation on pulseOpacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.6; duration: 3000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 3000; easing.type: Easing.InOutSine }
        }

        property real scanY: 0
        NumberAnimation on scanY {
            from: 0; to: container.height
            duration: 8000; loops: Animation.Infinite; easing.type: Easing.Linear
        }

        // ── HELPERS ───────────────────────────────────────────────────────
        function fs(x) { return Math.max(1, Math.round(x * s)) }

        // █▓░ 10-block bar — matches usage_render_bar.sh
        function getBar(val) {
            let pct    = Math.max(0, Math.min(100, val || 0))
            let filled = Math.floor(pct * 10 / 100)
            let half   = (filled < 10 && (pct * 10 / 100 - filled) >= 0.5) ? 1 : 0
            let r = ""
            for (let i = 0; i < 10; i++) {
                if      (i < filled)              r += "\u2588"  // █
                    else if (i === filled && half)     r += "\u2593"  // ▓
                        else                               r += "\u2591"  // ░
            }
            return r
        }

        function tempColor(t) {
            if (t >= 90) return redColor
                if (t >= 75) return orangeColor
                    return mainColor
        }
        function rpmColor(r, mx) {
            if (r / mx >= 0.85) return redColor
                if (r / mx >= 0.65) return orangeColor
                    return mainColor
        }
        function fanChar(f) { return ["|","/","-","\\"][Math.floor(f) % 4] }

        // ── TIMER ─────────────────────────────────────────────────────────
        Timer {
            interval: 50; running: true; repeat: true
            onTriggered: {
                tick++
                let ca = cpuRpm > 100 ? cpuRpm / 60.0 * 0.05 / 4.0 : 0
                let ga = gpuRpm > 100 ? gpuRpm / 60.0 * 0.05 / 4.0 : 0
                cpuFanFrame = (cpuFanFrame + ca) % 4
                gpuFanFrame = (gpuFanFrame + ga) % 4
                activeWs = parseActiveWs(workspaceSrc.value)
            }
        }

        // ── NO BACKGROUND, NO OUTER BORDER ───────────────────────────────
        // scan line only
        Rectangle {
            x: 0; y: scanY; width: parent.width; height: 2*s
            color: mainColor; opacity: 0.03; z: 99
        }
        Rectangle {
            x: 0; y: scanY; width: parent.width; height: 1*s
            color: mainColor; opacity: 0.12; z: 99
        }

        // ── CONTENT ───────────────────────────────────────────────────────
        Column {
            anchors {
                top: parent.top; left: parent.left; right: parent.right
                topMargin: 8*s; leftMargin: 8*s; rightMargin: 8*s
            }
            spacing: 7*s



            // ── REACTOR UPTIME + MELTDOWN CLOCK ─────────────────────────
            Row {
                width: parent.width; spacing: 5*s

                Rectangle {
                    width: (parent.width - 5*s) * 0.5; height: 52*s
                    color: "transparent"; border.color: lineColor; border.width: 2*s
                    Column {
                        anchors.centerIn: parent; spacing: 3*s
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "[ REACTOR UPTIME ]"
                            color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: reactorUptime
                            color: mainColor; font.family: fontFam; font.pixelSize: fs(9.5); font.bold: true
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 5*s) * 0.5; height: 52*s
                    color: "transparent"
                    border.color: onBattery ? orangeColor : lineColor
                    border.width: 2*s
                    Column {
                        anchors.centerIn: parent; spacing: 3*s
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "[ MELTDOWN CLOCK ]"
                            color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: meltdownDisplay
                            color: onBattery ? orangeColor : mainColor
                            font.family: fontFam; font.pixelSize: fs(9.5); font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: onBattery && batWatts > 0.1
                            text: batWatts.toFixed(1) + "W  \u00b7  " + batPct + "%"
                            color: orangeColor; font.family: fontFam; font.pixelSize: fs(7); opacity: 0.85
                        }
                    }
                }
            }

            // ── CPU TEMP + GPU TEMP + WORKSPACE ─────────────────────────
            Row {
                width: parent.width; spacing: 5*s
                Rectangle {
                    width: (parent.width - 5*s) * 0.5; height: 44*s
                    color: "transparent"; border.color: lineColor; border.width: 2*s
                    Column {
                        anchors.centerIn: parent; spacing: 3*s
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "[ CPU TEMP ]"
                            color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "+" + cpuTemp + "\u00b0C"
                            color: tempColor(cpuTemp); font.family: fontFam; font.pixelSize: fs(12); font.bold: true
                        }
                    }
                }
                Rectangle {
                    width: (parent.width - 5*s) * 0.5; height: 44*s
                    color: "transparent"; border.color: lineColor; border.width: 2*s
                    Column {
                        anchors.centerIn: parent; spacing: 3*s
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "[ GPU TEMP ]"
                            color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: nvidiaOk ? "+" + nvTemp + "\u00b0C" : "--"
                            color: tempColor(nvidiaOk ? nvTemp : 0)
                            font.family: fontFam; font.pixelSize: fs(12); font.bold: true
                        }
                    }
                }
            }

            // ── THIN DIVIDER ─────────────────────────────────────────────
            Rectangle { width: parent.width; height: 1*s; color: lineColor; opacity: 0.6 }

            // ══════════════════════════════════════════════════════════════
            // STATS — 5 rows, each in its own box
            // LEFT: label + █▓░ bar + [pct]     RIGHT: detail
            // connected by spine with ◆ ticks
            // ══════════════════════════════════════════════════════════════
            Item {
                id: statsBlock
                width: parent.width
                // 5 rows × 34 + 4 gaps × 6
                height: 5 * 50*s + 4 * 6*s

                // LEFT column — each row is a box with label + bar + badge
                Column {
                    anchors.left:  parent.left
                    width: parent.width * 0.42
                    spacing: 6*s

                    // ── CPU LOAD
                    Column {
                        width: parent.width; spacing: 2*s
                        Text { text: "[ CPU LOAD ]"; color: dimColor; font.family: fontFam; font.pixelSize: fs(7) }
                        Rectangle {
                            width: parent.width; height: 36*s
                            color: "transparent"; border.color: lineColor; border.width: 2*s
                            Row {
                                anchors.centerIn: parent; spacing: 4*s
                                Text { text: getBar(realCpu); color: realCpu > 60 ? orangeColor : mainColor; font.family: fontFam; font.pixelSize: fs(13); opacity: pulseOpacity }
                                Rectangle {
                                    width: 28*s; height: 18*s; color: "transparent"
                                    border.color: lineColor; border.width: 2*s
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: Math.round(realCpu) + "%"; color: mainColor; font.family: fontFam; font.pixelSize: fs(8); font.bold: true }
                                }
                            }
                        }
                    }

                    // ── RAM USAGE
                    Column {
                        width: parent.width; spacing: 2*s
                        Text { text: "[ RAM USAGE ]"; color: dimColor; font.family: fontFam; font.pixelSize: fs(7) }
                        Rectangle {
                            width: parent.width; height: 36*s
                            color: "transparent"; border.color: lineColor; border.width: 2*s
                            Row {
                                anchors.centerIn: parent; spacing: 4*s
                                Text { text: getBar(realRam); color: realRam > 60 ? orangeColor : mainColor; font.family: fontFam; font.pixelSize: fs(13); opacity: pulseOpacity }
                                Rectangle {
                                    width: 28*s; height: 18*s; color: "transparent"
                                    border.color: lineColor; border.width: 2*s
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: Math.round(realRam) + "%"; color: mainColor; font.family: fontFam; font.pixelSize: fs(8); font.bold: true }
                                }
                            }
                        }
                    }

                    // ── STORAGE
                    Column {
                        width: parent.width; spacing: 2*s
                        Text { text: "[ STORAGE ]"; color: dimColor; font.family: fontFam; font.pixelSize: fs(7) }
                        Rectangle {
                            width: parent.width; height: 36*s
                            color: "transparent"; border.color: lineColor; border.width: 2*s
                            Row {
                                anchors.centerIn: parent; spacing: 4*s
                                Text { text: getBar(diskPct); color: diskPct > 60 ? orangeColor : mainColor; font.family: fontFam; font.pixelSize: fs(13); opacity: pulseOpacity }
                                Rectangle {
                                    width: 28*s; height: 18*s; color: "transparent"
                                    border.color: lineColor; border.width: 2*s
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: diskPct + "%"; color: mainColor; font.family: fontFam; font.pixelSize: fs(8); font.bold: true }
                                }
                            }
                        }
                    }

                    // ── GPU 0
                    Column {
                        width: parent.width; spacing: 2*s
                        Text { text: "[ GPU 0  iGPU ]"; color: dimColor; font.family: fontFam; font.pixelSize: fs(7) }
                        Rectangle {
                            width: parent.width; height: 36*s
                            color: "transparent"; border.color: lineColor; border.width: 2*s
                            Row {
                                anchors.centerIn: parent; spacing: 4*s
                                Text { text: getBar(igpuLoad); color: igpuLoad > 60 ? orangeColor : mainColor; font.family: fontFam; font.pixelSize: fs(13); opacity: pulseOpacity }
                                Rectangle {
                                    width: 28*s; height: 18*s; color: "transparent"
                                    border.color: lineColor; border.width: 2*s
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: Math.round(igpuLoad) + "%"; color: mainColor; font.family: fontFam; font.pixelSize: fs(8); font.bold: true }
                                }
                            }
                        }
                    }

                    // ── GPU 1
                    Column {
                        width: parent.width; spacing: 2*s
                        Text { text: "[ GPU 1  dGPU ]"; color: dimColor; font.family: fontFam; font.pixelSize: fs(7) }
                        Rectangle {
                            width: parent.width; height: 36*s
                            color: "transparent"; border.color: lineColor; border.width: 2*s
                            Row {
                                anchors.centerIn: parent; spacing: 4*s
                                Text {
text: nvidiaOk ? getBar(nvUtil) : getBar(0)
                    color: nvidiaOk ? (nvUtil > 60 ? orangeColor : mainColor) : redColor
                                    font.family: fontFam; font.pixelSize: fs(13)
                                    opacity: nvidiaOk ? pulseOpacity : 0.4
                                }
                                Rectangle {
                                    width: 28*s; height: 18*s; color: "transparent"
                                    border.color: nvidiaOk ? lineColor : "transparent"; border.width: 2*s
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        anchors.centerIn: parent
                                        text: nvidiaOk ? nvUtil + "%" : ""
                                        color: nvidiaOk ? mainColor : "transparent"
                                        font.family: fontFam; font.pixelSize: fs(8); font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }

                // PROCESS BOX — white outline, right side of widget
                Rectangle {
                    anchors.left:   parent.left
                    anchors.leftMargin: parent.width * 0.64
                    anchors.right:  parent.right
                    anchors.top:    parent.top
                    anchors.topMargin: 6*s
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6*s
                    color: "transparent"
                    border.color: "#61afef"
                    border.width: 2*s
                    clip: true

                    Column {
                        anchors.top:   parent.top
                        anchors.left:  parent.left
                        anchors.right: parent.right
                        anchors.topMargin: 8*s
                        anchors.bottomMargin: 8*s
                        anchors.leftMargin: 4*s
                        anchors.rightMargin: 4*s
                        spacing: 2*s

                        // header
                        Text {
                            text: "[ PROCS ]"
                            color: dimColor
                            font.family: "JetBrains Mono"; font.pixelSize: fs(8); font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Rectangle { width: parent.width; height: 1*s; color: mainColor; opacity: 0.25 }

                        // process rows
                        Repeater {
                            model: procList
                            Row {
                                width: parent.width; spacing: 0
                                Text {
                                    width: parent.width * 0.62
                                    text: modelData.trim().split(/\s+/)[0] || ""
                                    color: mainColor
                                    font.family: "JetBrains Mono"; font.pixelSize: fs(8)
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width * 0.38
                                    property string ram: modelData.trim().split(/\s+/)[1] || ""
                                    property int ramMb: parseInt(ram) || 0
                                    text: ram
                                    color: ramMb >= 2000 ? orangeColor : dimColor
                                    font.family: "JetBrains Mono"; font.pixelSize: fs(8)
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }



                // RIGHT column — compact boxes with connecting line from left
                Column {
                    anchors.left:  parent.left
                    anchors.leftMargin: parent.width * 0.42
                    width: parent.width * 0.20   // ← change this to resize right boxes
                    anchors.top:   parent.top
                    spacing: 6*s

                    // CPU detail
                    Item {
                        width: parent.width; height: 50*s
                        Rectangle { x: 0; y: parent.height*0.5-1*s; width: 8*s; height: 2*s; color: lineColor }
                        // left bracket ┌ └
                        Rectangle { x: 8*s; y: 6*s;                        width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: 8*s; y: 6*s;                        width: 6*s; height: 2*s;                   color: lineColor }
                        Rectangle { x: 8*s; y: parent.height*0.5;          width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: 8*s; y: parent.height-8*s;          width: 6*s; height: 2*s;                   color: lineColor }
                        // right bracket ┐ ┘
                        Rectangle { x: parent.width-2*s; y: 6*s;                    width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: parent.width-6*s; y: 6*s;                    width: 6*s; height: 2*s;                   color: lineColor }
                        Rectangle { x: parent.width-2*s; y: parent.height*0.5;      width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: parent.width-6*s; y: parent.height-8*s;      width: 6*s; height: 2*s;                   color: lineColor }
                        Column {
                            x: 20*s; anchors.verticalCenter: parent.verticalCenter; spacing: 1*s
                            Text { text: Math.round(realCpu) + "%"; color: mainColor; font.family: fontFam; font.pixelSize: fs(10); font.bold: true }
                            Text { text: "22 cores"; color: "#fab387"; font.family: fontFam; font.pixelSize: fs(7) }
                        }
                    }

                    // RAM detail
                    Item {
                        width: parent.width; height: 50*s
                        Rectangle { x: 0; y: parent.height*0.5-1*s; width: 8*s; height: 2*s; color: lineColor }
                        // left bracket ┌ └
                        Rectangle { x: 8*s; y: 6*s;                        width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: 8*s; y: 6*s;                        width: 6*s; height: 2*s;                   color: lineColor }
                        Rectangle { x: 8*s; y: parent.height*0.5;          width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: 8*s; y: parent.height-8*s;          width: 6*s; height: 2*s;                   color: lineColor }
                        // right bracket ┐ ┘
                        Rectangle { x: parent.width-2*s; y: 6*s;                    width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: parent.width-6*s; y: 6*s;                    width: 6*s; height: 2*s;                   color: lineColor }
                        Rectangle { x: parent.width-2*s; y: parent.height*0.5;      width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: parent.width-6*s; y: parent.height-8*s;      width: 6*s; height: 2*s;                   color: lineColor }
                        Column {
                            x: 20*s; anchors.verticalCenter: parent.verticalCenter; spacing: 1*s
                            Text { text: ramUsedGb.toFixed(1) + "G"; color: mainColor; font.family: fontFam; font.pixelSize: fs(10); font.bold: true }
                            Text { text: "/ " + ramTotGb.toFixed(0) + "G"; color: "#fab387"; font.family: fontFam; font.pixelSize: fs(7) }
                            Text { text: Math.round(realRam) + "%"; color: dimColor; font.family: fontFam; font.pixelSize: fs(7) }
                        }
                    }

                    // Storage detail
                    Item {
                        width: parent.width; height: 50*s
                        Rectangle { x: 0; y: parent.height*0.5-1*s; width: 8*s; height: 2*s; color: lineColor }
                        Rectangle { x: 8*s; y: 6*s;                        width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: 8*s; y: 6*s;                        width: 6*s; height: 2*s;                   color: lineColor }
                        Rectangle { x: 8*s; y: parent.height*0.5;          width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: 8*s; y: parent.height-8*s;          width: 6*s; height: 2*s;                   color: lineColor }
                        Rectangle { x: parent.width-2*s; y: 6*s;                    width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: parent.width-6*s; y: 6*s;                    width: 6*s; height: 2*s;                   color: lineColor }
                        Rectangle { x: parent.width-2*s; y: parent.height*0.5;      width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: parent.width-6*s; y: parent.height-8*s;      width: 6*s; height: 2*s;                   color: lineColor }
                        Column {
                            x: 20*s; anchors.verticalCenter: parent.verticalCenter; spacing: 1*s
                            Text { text: diskUsed; color: mainColor; font.family: fontFam; font.pixelSize: fs(10); font.bold: true }
                            Text { text: "/ " + diskTotal; color: "#fab387"; font.family: fontFam; font.pixelSize: fs(7) }
                            Text { text: diskPct + "%"; color: dimColor; font.family: fontFam; font.pixelSize: fs(7) }
                        }
                    }

                    // GPU 0 detail
                    Item {
                        width: parent.width; height: 50*s
                        Rectangle { x: 0; y: parent.height*0.5-1*s; width: 8*s; height: 2*s; color: lineColor }
                        Rectangle { x: 8*s; y: 6*s;                        width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: 8*s; y: 6*s;                        width: 6*s; height: 2*s;                   color: lineColor }
                        Rectangle { x: 8*s; y: parent.height*0.5;          width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: 8*s; y: parent.height-8*s;          width: 6*s; height: 2*s;                   color: lineColor }
                        Rectangle { x: parent.width-2*s; y: 6*s;                    width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: parent.width-6*s; y: 6*s;                    width: 6*s; height: 2*s;                   color: lineColor }
                        Rectangle { x: parent.width-2*s; y: parent.height*0.5;      width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: parent.width-6*s; y: parent.height-8*s;      width: 6*s; height: 2*s;                   color: lineColor }
                        Column {
                            x: 20*s; anchors.verticalCenter: parent.verticalCenter; spacing: 1*s
                            Text { text: Math.round(igpuLoad) + "%"; color: mainColor; font.family: fontFam; font.pixelSize: fs(10); font.bold: true }
                            Text { text: "Intel"; color: "#fab387"; font.family: fontFam; font.pixelSize: fs(7) }
                            Text { text: "card0"; color: "#fab387"; font.family: fontFam; font.pixelSize: fs(7) }
                        }
                    }

                    // GPU 1 detail
                    Item {
                        width: parent.width; height: 50*s
                        Rectangle { x: 0; y: parent.height*0.5-1*s; width: 8*s; height: 2*s; color: lineColor }
                        Rectangle { x: 8*s; y: 6*s;                        width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: 8*s; y: 6*s;                        width: 6*s; height: 2*s;                   color: lineColor }
                        Rectangle { x: 8*s; y: parent.height*0.5;          width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: 8*s; y: parent.height-8*s;          width: 6*s; height: 2*s;                   color: lineColor }
                        Rectangle { x: parent.width-2*s; y: 6*s;                    width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: parent.width-6*s; y: 6*s;                    width: 6*s; height: 2*s;                   color: lineColor }
                        Rectangle { x: parent.width-2*s; y: parent.height*0.5;      width: 2*s; height: parent.height*0.5-6*s; color: lineColor }
                        Rectangle { x: parent.width-6*s; y: parent.height-8*s;      width: 6*s; height: 2*s;                   color: lineColor }
                        Column {
                            x: 20*s; anchors.verticalCenter: parent.verticalCenter; spacing: 1*s
                            Text {
                                text: nvidiaOk ? nvUtil + "%" : "SLEEP"
                                color: nvidiaOk ? mainColor : dimColor
                                font.family: fontFam; font.pixelSize: fs(10); font.bold: true
                            }
                            Text {
                                text: nvidiaOk ? "+" + nvTemp + "\u00b0C" : "card1"
                                color: nvidiaOk ? tempColor(nvTemp) : "#fab387"
                                font.family: fontFam; font.pixelSize: fs(7)
                            }
                            Text {
                                text: nvidiaOk ? nvMemUsed + "/" + nvMemTotal + "M" : "dGPU off"
                                color: dimColor; font.family: fontFam; font.pixelSize: fs(7)
                            }
                        }
                    }
                }
            }

            // ── THIN DIVIDER ─────────────────────────────────────────────
            Rectangle { width: parent.width; height: 1*s; color: lineColor; opacity: 0.6 }

            // ── POWER GRID + COOLING ─────────────────────────────────────
            Row {
                width: parent.width; spacing: 5*s

                Column {
                    width: (parent.width - 5*s) * 0.5; spacing: 3*s
                    Text { text: "[ POWER GRID ]"; color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                    Row { spacing: 0
                        Text { text: "> bat:   "; color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                        Text { text: batPct + "% " + batStatus; color: mainColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                    }
                    Row { spacing: 0
                        Text { text: "> draw:  "; color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                        Text { text: batWatts.toFixed(1) + " W"; color: onBattery ? orangeColor : mainColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                    }
                    Row { spacing: 0
                        Text { text: "> volt:  "; color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                        Text { text: (batVolUv/1000000).toFixed(2) + " V"; color: mainColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                    }
                    Row { spacing: 0
                        Text { text: "> nvme:  "; color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                        Text { text: "+" + nvmeTemp + "\u00b0C"; color: tempColor(nvmeTemp); font.family: fontFam; font.pixelSize: fs(7.5) }
                    }
                }

                Column {
                    width: (parent.width - 5*s) * 0.5; spacing: 3*s
                    Text { text: "[ COOLING ]"; color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                    Row { spacing: 0
                        Text { text: "> cpu ["; color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                        Text { text: fanChar(cpuFanFrame); color: mainColor; font.family: fontFam; font.pixelSize: fs(7.5); font.bold: true }
                        Text { text: "] "; color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                        Text { text: cpuRpm + " RPM"; color: rpmColor(cpuRpm, 3500); font.family: fontFam; font.pixelSize: fs(7.5) }
                    }
                    Row { spacing: 0
                        Text { text: "> gpu ["; color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                        Text { text: fanChar(gpuFanFrame); color: mainColor; font.family: fontFam; font.pixelSize: fs(7.5); font.bold: true }
                        Text { text: "] "; color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                        Text { text: gpuRpm + " RPM"; color: rpmColor(gpuRpm, 3500); font.family: fontFam; font.pixelSize: fs(7.5) }
                    }
                    Row { spacing: 0
                        Text { text: "> dGPU:  "; color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                        Text { text: nvidiaOk ? nvWatts.toFixed(1) + " W" : "SLEEP"; color: nvidiaOk ? mainColor : dimColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                    }
                    Row { spacing: 0
                        Text { text: "> kern:  "; color: dimColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                        Text { text: kernelVer; color: mainColor; font.family: fontFam; font.pixelSize: fs(7.5) }
                    }
                }
            }

            // ── DIVIDER ──────────────────────────────────────────────────
            Rectangle { width: parent.width; height: 1*s; color: lineColor; opacity: 0.6 }

            // ── FOOTER ───────────────────────────────────────────────────
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: cpuTemp >= 90 || nvTemp >= 90 ? "[ THERMAL CRITICAL ]" : "[ ALL SYSTEMS NOMINAL ]"
                color: cpuTemp >= 90 || nvTemp >= 90 ? redColor : dimColor
                font.family: fontFam; font.pixelSize: fs(8); font.bold: true
                opacity: cpuTemp >= 90 || nvTemp >= 90 ? pulseOpacity : 0.6
            }

            Item { width: 1; height: 6*s }
        }

        Component.onCompleted: console.log("YoRHa HUD v13 | scale:", s)
    }
}
