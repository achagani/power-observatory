import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property var telemetry: ({})
    property bool stale: false
    property string error: ""
    property int tab: 0
    property int pollSeconds: 2
    property bool controlBusy: false
    signal profileRequested(string profile)
    signal refreshRequested(string outputId, string modeId)
    property var cpuHistory: []
    property var gpuHistory: []
    property var powerHistory: []
    readonly property var cpu: telemetry.cpu || ({})
    readonly property var ram: telemetry.ram || ({})
    readonly property var gpu: telemetry.gpu || ({})
    readonly property var npu: telemetry.npu || ({})
    readonly property var battery: telemetry.battery || ({})
    readonly property var display: (telemetry.displays || [])[0] || ({})
    readonly property color mint: "#75e3c5"
    readonly property color blue: "#83bcff"
    readonly property color amber: "#f0c582"
    radius: 22
    color: "#0d1822"
    border.color: "#304250"
    implicitWidth: 640
    implicitHeight: 850
    function has(v) { return v !== null && v !== undefined && v !== "" }
    function num(v, unit, digits) { return has(v) ? Number(v).toFixed(digits === undefined ? 0 : digits) + (unit || "") : "—" }
    function txt(v) { return has(v) ? String(v) : "Unavailable" }
    function gib(v) { return num(has(v) ? v/1073741824 : null, " GiB", 1) }
    function duration(s) {
        if (!has(s)) return "Estimating…"
        const minutes = Math.max(1, Math.round(s/60))
        return Math.floor(minutes/60) + "h " + (minutes%60) + "m"
    }
    function append(a,v) { let b=a.slice(-59); b.push(has(v)?v:null); return b }
    onTelemetryChanged: {
        cpuHistory=append(cpuHistory || [],(telemetry.cpu || {}).busy)
        gpuHistory=append(gpuHistory || [],(telemetry.gpu || {}).busy)
        powerHistory=append(powerHistory || [],telemetry.apu_watts)
    }
    component Caption: Text {
        color: "#6fe0c0"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.8
        Layout.topMargin: 14; Layout.bottomMargin: 3
    }
    component Note: Text {
        color: "#7f95a7"; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true
        lineHeight: 1.25
    }
    component Divider: Rectangle { color: "#243441"; Layout.fillWidth: true; implicitHeight: 1; Layout.topMargin: 8; Layout.bottomMargin: 8 }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 22; spacing: 14
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 3
                Text { text: "POWER OBSERVATORY"; color: root.mint; font.pixelSize: 10; font.bold: true; font.letterSpacing: 2.1 }
                Text { text: "Your machine, in motion."; color: "#edf5fa"; font.pixelSize: 21; font.weight: Font.DemiBold }
            }
            Item { Layout.fillWidth: true }
            Rectangle { width: 7; height: 7; radius: 4; color: root.stale ? "#f0a87b" : root.mint }
            Text { text: root.stale ? "STALE" : (root.telemetry.timestamp ? "LIVE" : "STARTING"); color: root.stale ? "#f0a87b" : root.mint; font.pixelSize: 10; font.letterSpacing: 1 }
        }
        Rectangle {
            Layout.fillWidth: true; implicitHeight: powerLayout.implicitHeight+28; radius: 16
            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop {position:0; color:"#19382f"} GradientStop {position:1;color:"#172837"} }
            border.color: "#305347"
            ColumnLayout {
                id: powerLayout; anchors.fill: parent; anchors.margins: 14; spacing: 10
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: root.txt((root.telemetry.charger || {}).label).toUpperCase(); color: root.mint; font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.7; Layout.fillWidth:true; elide:Text.ElideRight }
                    Item { Layout.fillWidth: true }
                    Text { text: root.txt(root.telemetry.profile || root.telemetry.platform_profile).toUpperCase(); color: "#ccece3"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1 }
                }
                RowLayout {
                    Text { text: root.num(root.battery.percent,"%"); color:"#f1fbf5"; font.pixelSize: 34; font.weight: Font.DemiBold }
                    ColumnLayout {
                        Layout.leftMargin: 9; spacing: 3
                        Text { text: root.battery.status === "Discharging" ? root.duration(root.battery.seconds)+" remaining" : root.battery.status === "Charging" ? root.duration(root.battery.seconds)+" to full" : root.txt(root.battery.status); color:"#deede9"; font.pixelSize: 13 }
                        Text { text: root.battery.status === "Discharging" ? root.num(root.battery.watts," W",1)+" battery draw" : root.battery.status === "Charging" ? root.num(root.battery.watts," W",1)+" into battery" : "Battery flow  "+root.num(root.battery.watts," W",1); color:"#93b5ad"; font.pixelSize:11 }
                    }
                    Item { Layout.fillWidth: true }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 3
                        Text { text: root.num(root.display.hz," Hz"); color: root.blue; font.pixelSize: 23; font.weight:Font.DemiBold; Layout.alignment:Qt.AlignRight }
                        Text { text: root.has(root.display.width) ? root.display.width+" × "+root.display.height : "Display unavailable"; color:"#91acbe"; font.pixelSize:10; Layout.alignment:Qt.AlignRight }
                    }
                }
                Rectangle {
                    Layout.fillWidth:true; height:4; radius:2; color:"#2b4843"
                    Rectangle { width:parent.width*Math.min(100,root.battery.percent || 0)/100; height:4; radius:2; color:root.mint; Behavior on width { NumberAnimation {duration:300} } }
                }
                RowLayout {
                    Layout.fillWidth:true; spacing:6
                    Repeater {
                        model:[{name:"Saver",key:"power-saver"},{name:"Balanced",key:"balanced"},{name:"Performance",key:"performance"}]
                        delegate: Button {
                            required property var modelData
                            Layout.fillWidth:true; Layout.preferredWidth:1; implicitHeight:29
                            enabled:!root.controlBusy && !!root.telemetry.timestamp
                            onClicked:root.profileRequested(modelData.key)
                            contentItem:Text {text:modelData.name; horizontalAlignment:Text.AlignHCenter; verticalAlignment:Text.AlignVCenter; font.pixelSize:11; color:root.telemetry.profile===modelData.key?"#effff7":"#9dbdb6"}
                            background:Rectangle {radius:7; color:root.telemetry.profile===modelData.key?"#376052":parent.hovered?"#29483f":"#203a36"; border.color:root.telemetry.profile===modelData.key?"#669882":"transparent"}
                            ToolTip.visible:hovered
                            ToolTip.text:"Set "+modelData.name+" power profile"+((root.telemetry.charger || {}).recommended===modelData.key?" · suggested for this source":"")
                        }
                    }
                }
                Text {visible:root.battery.ac===true && root.battery.status==="Discharging"; text:"Battery is supplementing the adapter · "+root.num(root.battery.watts," W",1); color:root.amber; font.pixelSize:11; Layout.fillWidth:true; wrapMode:Text.WordWrap}
            }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            MetricCard { Layout.fillWidth:true; Layout.preferredWidth:1; title:"CPU"; value:root.num(root.cpu.busy,"%",1); detail:root.num(root.cpu.temp,"°C")+"  ·  "+root.num(root.cpu.ghz," GHz",2); history:root.cpuHistory; accent:root.mint }
            MetricCard { Layout.fillWidth:true; Layout.preferredWidth:1; title:"GPU"; value:root.num(root.gpu.busy,"%",1); detail:root.num(root.gpu.temp,"°C")+"  ·  "+root.num(root.gpu.clock," MHz"); history:root.gpuHistory; accent:root.blue }
            MetricCard { Layout.fillWidth:true; Layout.preferredWidth:1; title:"APU POWER"; value:root.num(root.telemetry.apu_watts," W",1); detail:"Chip power · not wall draw"; history:root.powerHistory; accent:root.amber; ceiling:0 }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Repeater {
                model: ["Overview", "Compute", "Power", "Sensors"]
                delegate: Button {
                    required property string modelData
                    required property int index
                    Layout.fillWidth:true; Layout.preferredWidth:1
                    implicitHeight: 34
                    onClicked: root.tab=index
                    contentItem: Text { text: modelData; horizontalAlignment:Text.AlignHCenter; verticalAlignment:Text.AlignVCenter; font.pixelSize:12; font.weight:Font.Medium; color: root.tab===index ? "#b4f4df" : "#8da3b4" }
                    background: Rectangle { radius:9; color:root.tab===index ? "#213d36" : parent.hovered ? "#1a2b38" : "#14232f"; border.color:root.tab===index ? "#365d50" : "transparent" }
                }
            }
        }
        ScrollView {
            id: scroll
            Layout.fillWidth:true; Layout.fillHeight:true; clip:true
            contentWidth:availableWidth
            ScrollBar.horizontal.policy:ScrollBar.AlwaysOff
            ColumnLayout {
                width:scroll.availableWidth; spacing:2
                ColumnLayout {
                    visible:root.tab===0; Layout.fillWidth:true; spacing:2
                    Caption {text:"DISPLAY REFRESH"; Layout.topMargin:0}
                    Repeater {
                        model:root.telemetry.displays || []
                        delegate:DisplayControl {
                            required property var modelData
                            display:modelData; busy:root.controlBusy
                            onModeRequested:(outputId,modeId)=>root.refreshRequested(outputId,modeId)
                        }
                    }
                    Note {visible:!(root.telemetry.displays || []).length; text:"Display modes unavailable. Check that kscreen-doctor is installed and your Plasma session is running."}
                    Caption {text:"MEMORY & COOLING"}
                    Reading {label:"System RAM"; value:root.gib(root.ram.used)+" / "+root.gib(root.ram.total); hint:"Used = MemTotal − MemAvailable. GPU-reserved memory is excluded from Linux RAM."}
                    Rectangle { Layout.fillWidth:true; height:5; radius:3; color:"#233340"; Layout.bottomMargin:8; Rectangle {width:parent.width*(root.ram.percent || 0)/100; height:5; radius:3; color:root.blue} }
                    Reading {label:"GPU reserved memory (UMA)"; value:root.gib(root.gpu.vram_used)+" / "+root.gib(root.gpu.vram_total); hint:"Firmware-reserved GPU memory, reported as VRAM by amdgpu. It is physically unified memory."}
                    Repeater { model: (root.telemetry.fans || []).filter(f=>f.name!=="acpi_fan"); delegate: Reading {required property var modelData; label:modelData.name.replace("cpu_fan","CPU fan").replace("gpu_fan","GPU fan"); value:root.num(modelData.value," RPM"); hint:modelData.path; accent:root.mint} }
                    Caption {text:"ACCELERATORS"}
                    Reading {label:"GPU compute · your processes"; value:root.num(root.gpu.compute,"%",1); hint:"Sum of per-client compute engine time / elapsed time. Can exceed 100% with parallel engines; excludes inaccessible processes."}
                    Reading {label:"NPU · firmware column average"; value:root.num(root.npu.busy,"%",1)+"  ·  "+root.txt(root.npu.state); hint:"Mean activity of the firmware IPU columns, not the runtime power-state percentage."}
                    Reading {label:"NPU power / clock"; value:root.num(root.npu.watts," W",2)+"  /  "+root.num(root.npu.clock," MHz")}
                    Caption {text:"DISPLAY & SESSION"}
                    Reading {label:"Brightness / scale"; value:root.num(root.telemetry.brightness,"%")+"  /  "+root.num(root.display.scale ? root.display.scale*100 : null,"%")}
                    Reading {label:"CPU policy"; value:root.txt(root.cpu.epp)+"  ·  boost "+(root.cpu.boost==="1" ? "on" : root.cpu.boost==="0" ? "off" : "unknown")}
                    Reading {label:"Uptime"; value:root.duration(root.telemetry.uptime)}
                }
                ColumnLayout {
                    visible:root.tab===1; Layout.fillWidth:true; spacing:2
                    Caption {text:"CPU · "+(root.cpu.cores || []).length+" LOGICAL THREADS"; Layout.topMargin:0}
                    GridLayout {
                        Layout.fillWidth:true; columns:8; columnSpacing:5; rowSpacing:5
                        Repeater {
                            model:root.cpu.cores || []
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                Layout.fillWidth:true; implicitHeight:34; radius:6; color:"#172f30"
                                Rectangle {anchors.bottom:parent.bottom; width:parent.width; height:parent.height*(parent.modelData || 0)/100; radius:6; color:"#326552"}
                                Text {anchors.centerIn:parent; text:index+" · "+root.num(parent.modelData,"%"); color:"#c6eadd"; font.pixelSize:9}
                            }
                        }
                    }
                    Reading {label:"CPU core power"; value:root.num(root.cpu.watts," W",2)}
                    Reading {label:"Frequency policy range"; value:root.num(root.cpu.min_ghz,"",2)+"–"+root.num(root.cpu.max_ghz," GHz",2)}
                    Reading {label:"Load average · 1 / 5 / 15 min"; value:(root.cpu.load || []).join(" / ")}
                    Caption {text:"AMD GPU · MEMORY & ENGINES"}
                    Reading {label:"Compute engine · your processes"; value:root.num(root.gpu.compute,"%",1)}
                    Reading {label:"Video engine"; value:root.num(root.gpu.media,"%",1)}
                    Reading {label:"GPU domain power"; value:root.num(root.gpu.watts," W",2)}
                    Reading {label:"GPU / memory clock"; value:root.num(root.gpu.clock," MHz")+" / "+root.num(root.gpu.mem_clock," MHz")}
                    Reading {label:"Reserved GPU memory"; value:root.gib(root.gpu.vram_used)+" / "+root.gib(root.gpu.vram_total)}
                    Reading {label:"GTT · shared system allocation"; value:root.gib(root.gpu.gtt_used)+" / "+root.gib(root.gpu.gtt_total)}
                    Reading {label:"DRAM read / write"; value:root.num(root.telemetry.dram_reads," MB/s")+" / "+root.num(root.telemetry.dram_writes," MB/s")}
                    Caption {text:"RYZEN AI · NPU"}
                    Reading {label:"Device / runtime power state"; value:root.txt(root.npu.name)+" · "+root.txt(root.npu.state)}
                    Reading {label:"Firmware column activity"; value:(root.npu.columns || []).map(v=>root.num(v,"%")).join(" · ")}
                    Reading {label:"Power / clock"; value:root.num(root.npu.watts," W",2)+" / "+root.num(root.npu.clock," MHz")}
                    Reading {label:"NPU read / write"; value:root.num(root.npu.reads," MB/s")+" / "+root.num(root.npu.writes," MB/s")}
                    Caption {text:"SYSTEM MEMORY"}
                    Reading {label:"Available / cache"; value:root.gib(root.ram.available)+" / "+root.gib(root.ram.cached)}
                    Reading {label:"Swap used / total"; value:root.gib(root.ram.swap_used)+" / "+root.gib(root.ram.swap_total)}
                    Note {text:"GPU compute covers readable processes in your session; parallel engines can exceed 100%. NPU readings come from AMD firmware. Suspended describes its power state."}
                }
                ColumnLayout {
                    visible:root.tab===2; Layout.fillWidth:true; spacing:2
                    Caption {text:"ACTIVE POWER POLICY"; Layout.topMargin:0}
                    Reading {label:"Detected source"; value:root.txt((root.telemetry.charger || {}).label)}
                    Reading {label:"Suggested profile"; value:root.txt((root.telemetry.charger || {}).recommended); hint:"Suggestion only. Source changes never automatically change your profile."}
                    Repeater {model:(root.telemetry.charger || {}).ports || []; delegate:Reading {required property var modelData; label:"USB-C negotiated contract"; value:root.num(modelData.limit_watts," W",1)+" · "+root.num(modelData.volts," V",1)+" × "+root.num(modelData.amps," A",1)} }
                    Note {text:"Configured charger ratings are nameplate capacities, not measured draw. USB-C negotiation can be lower. Source detection never automatically changes the selected profile."}
                    Reading {label:"Power profiles daemon"; value:root.txt(root.telemetry.profile); accent:root.mint}
                    Reading {label:"Firmware platform profile"; value:root.txt(root.telemetry.platform_profile)}
                    Reading {label:"CPU driver / governor"; value:root.txt(root.cpu.driver)+" / "+root.txt(root.cpu.governor)}
                    Reading {label:"Energy performance preference"; value:root.txt(root.cpu.epp)}
                    Reading {label:"CPU boost"; value:root.cpu.boost==="1"?"Enabled":root.cpu.boost==="0"?"Disabled":"Unavailable"}
                    Reading {label:"GPU performance policy"; value:root.txt(root.gpu.policy)}
                    Reading {label:"STAPM limit / current"; value:root.num((root.telemetry.limits || {}).stapm_power_limit," W",1)+" / "+root.num((root.telemetry.limits || {}).current_stapm_power_limit," W",1)}
                    Caption {text:"BATTERY & ENERGY"}
                    Reading {label:"Battery state"; value:root.txt(root.battery.status)}
                    Reading {label:"Instantaneous battery flow"; value:root.num(root.battery.watts," W",2)}
                    Reading {label:"Smoothed flow · 30 s"; value:root.num(root.battery.smoothed_watts," W",2)}
                    Reading {label:"Remaining / full energy"; value:root.num(root.battery.energy," Wh",1)+" / "+root.num(root.battery.full," Wh",1)}
                    Reading {label:"Design capacity / health"; value:root.num(root.battery.design," Wh",1)+" / "+root.num(root.battery.health,"%",1)}
                    Reading {label:"Voltage / cycles"; value:root.num(root.battery.voltage," V",2)+" / "+root.num(root.battery.cycles,"")}
                    Reading {label:"Charge limit"; value:root.num(root.battery.limit,"%")}
                    Note {text:"Time estimates use battery energy and a 30-second smoothed flow. They adapt to workload and may vary. APU power is chip power; total AC wall draw is not exposed by this hardware."}
                    Caption {text:"DISPLAYS"}
                    Repeater {
                        model:root.telemetry.displays || []
                        delegate:DisplayControl {
                            required property var modelData
                            display:modelData; busy:root.controlBusy
                            onModeRequested:(outputId,modeId)=>root.refreshRequested(outputId,modeId)
                        }
                    }
                    Note {text:"Only refresh rates at each screen's current resolution are offered. Mode changes are verified with KScreen. Display information refreshes every 10 seconds."}
                    Caption {text:"ASUS FIRMWARE CONTROLS · RAW"}
                    Repeater {model:Object.keys(root.telemetry.asus_controls || {}); delegate: Reading {required property string modelData; label:modelData; value:root.num(root.telemetry.asus_controls[modelData],"")} }
                    Note {text:"ASUS PPT control readbacks are shown raw. They are not reliable measurements of the enforced power limit."}
                }
                ColumnLayout {
                    visible:root.tab===3; Layout.fillWidth:true; spacing:2
                    Caption {text:"FAN TACHOMETERS"; Layout.topMargin:0}
                    Repeater {model:root.telemetry.fans || []; delegate:Reading {required property var modelData; label:modelData.name; value:root.num(modelData.value," RPM"); hint:modelData.path; accent:root.mint} }
                    Note {text:"The ACPI fan may mirror one of the ASUS fans; it is shown as a separate sensor, not a third physical fan."}
                    Caption {text:"TEMPERATURE SENSORS"}
                    Repeater {model:root.telemetry.sensors || []; delegate:Reading {required property var modelData; label:modelData.name; value:root.num(modelData.value," °C",1); hint:modelData.path; accent:modelData.value>85?"#f6ab85":"#cfe4ef"} }
                    Caption {text:"TELEMETRY NOTES"}
                    Note {text:"Hover a sensor for its kernel source path. A dash means unavailable, never zero. AMD metrics v3 provide GPU, CPU and NPU domain readings. All monitoring is read-only."}
                }
                Note {visible:root.error.length>0; text:root.error; color:"#f0a87b"; Layout.topMargin:12}
            }
        }
        Rectangle {Layout.fillWidth:true; height:1; color:"#263644"}
        RowLayout {
            Layout.fillWidth:true
            Text {text:root.txt(root.cpu.name).toUpperCase(); color:"#6e879a"; font.pixelSize:9; font.letterSpacing:0.7; Layout.fillWidth:true; elide:Text.ElideRight}
            Text {text:root.pollSeconds+"s live · 10s display/profile"; color:"#6e879a"; font.pixelSize:9}
        }
    }
}
