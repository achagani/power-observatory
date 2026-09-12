import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Zones.js" as Zones
import "History.js" as History
import "Metrics.js" as Metrics

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
    property var histories: ({})
    property var fanIds: []
    property var temperatureIds: []
    property bool liveClock: true
    property double now: Date.now()/1000
    readonly property var metrics: Metrics.build(telemetry)
    property int historySeconds: 120
    onTabChanged:if(scroll && scroll.contentItem)scroll.contentItem.contentY=0
    Timer {interval:1000; running:root.liveClock; repeat:true; onTriggered:root.now=Date.now()/1000}
    readonly property var cpu: telemetry.cpu || ({})
    readonly property var ram: telemetry.ram || ({})
    readonly property var gpu: telemetry.gpu || ({})
    readonly property var npu: telemetry.npu || ({})
    readonly property var battery: telemetry.battery || ({})
    readonly property var display: (telemetry.displays || [])[0] || ({})
    readonly property var criticalSensors: stale ? [] : (telemetry.sensors || []).filter(s => Zones.valid(s.critical) && s.critical > 0 && typeof s.value === "number" && isFinite(s.value) && s.value >= s.critical)
    readonly property color mint: "#75e3c5"
    readonly property color blue: "#83bcff"
    readonly property color amber: "#f0c582"
    radius: 22
    color: "#0d1822"
    border.color: "#304250"
    implicitWidth: 640
    implicitHeight: 850
    function bands(key) {
        const defaults={apu:[30,60,90],cpu:[15,35,60],gpu:[10,25,50],npu:[2,5,10],battery:[15,30,45]}
        return (telemetry.power_bands || {})[key] || defaults[key]
    }
    function has(v) { return v !== null && v !== undefined && v !== "" }
    function num(v, unit, digits) { return has(v) ? Number(v).toFixed(digits === undefined ? 0 : digits) + (unit || "") : "—" }
    function txt(v) { return has(v) ? String(v) : "Unavailable" }
    function gib(v) { return num(has(v) ? v/1073741824 : null, " GiB", 1) }
    function duration(s) {
        if (!has(s)) return "Estimating…"
        const minutes = Math.max(1, Math.round(s/60))
        return Math.floor(minutes/60) + "h " + (minutes%60) + "m"
    }
    function record(data) {
        var current=Metrics.build(data), updated={}, timestamp=data.timestamp
        var fans=Object.keys(current).filter(k=>k.indexOf("fan:")===0)
        var temperatures=Object.keys(current).filter(k=>k.indexOf("temp:")===0)
        if(JSON.stringify(fans)!==JSON.stringify(fanIds || []))fanIds=fans
        if(JSON.stringify(temperatures)!==JSON.stringify(temperatureIds || []))temperatureIds=temperatures
        Object.keys(histories || {}).forEach(function(key){updated[key]=histories[key]})
        Object.keys(current).forEach(function(key){
            var m=current[key]
            updated[key]=History.append(updated[key]||[],timestamp,m.value,m.policy,historySeconds)
        })
        Object.keys(updated).forEach(function(key){
            if(!current[key] && updated[key].length){
                var last=updated[key][updated[key].length-1]
                var valid=updated[key].filter(p=>History.finite(p.v))
                if(!valid.length || timestamp-valid[valid.length-1].t>historySeconds)delete updated[key]
                else updated[key]=History.append(updated[key],timestamp,null,{edges:last.edges,colors:last.colors,identity:'missing'},historySeconds)
            }
        })
        histories=updated
    }
    onTelemetryChanged:record(telemetry)
    component Tile: MetricTile {
        property string metricId
        readonly property var metric:root.metrics[metricId] || ({})
        objectName:metricId+"-tile"
        Layout.fillWidth:true; Layout.preferredWidth:1
        title:metric.title||metricId; readingText:metric.display||"—"; detail:metric.detail||""
        value:metric.value; maximum:metric.maximum||100; scaleUnit:metric.unit||""
        policy:metric.policy||Metrics.neutral("Unavailable")
        explanation:metric.info||"No data is available for this reading."
        samples:root.histories[metricId]||[]; now:root.now; stale:root.stale
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
            objectName:"thermal-danger"
            visible:root.criticalSensors.length>0
            Layout.fillWidth:true; implicitHeight:dangerRow.implicitHeight+18
            radius:10; color:"#49262e"; border.color:"#a35765"
            RowLayout {
                id:dangerRow; anchors.fill:parent; anchors.margins:9
                Text {text:"⚠"; color:"#ff6578"; font.pixelSize:20; Accessible.name:"Critical temperature warning"}
                Text {Layout.fillWidth:true; wrapMode:Text.WordWrap; text:root.criticalSensors.length ? "Critical temperature · "+root.criticalSensors[0].name+" "+root.num(root.criticalSensors[0].value,"°C",1)+(root.criticalSensors.length>1?" +"+(root.criticalSensors.length-1):"") : ""; color:"#ffd2d5"; font.pixelSize:11; font.weight:Font.DemiBold}
                Button {text:"Sensors"; implicitHeight:28; onClicked:root.tab=3}
            }
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
                    InfoButton {heading:"Battery, adapter and profile"; explanation:"Battery percentage and flow come from the battery driver. Remaining time uses stored energy and a 30-second smoothed discharge rate. Charger ratings are configured nameplate capacities, not wall draw. The profile buttons request a manual profile change; the source never switches profiles automatically."}
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
            Tile {metricId:"cpu"; compact:true}
            Tile {metricId:"gpu"; compact:true}
            Tile {metricId:"apu"; compact:true}
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
            objectName:"details-scroll"
            Layout.fillWidth:true; Layout.fillHeight:true; clip:true
            contentWidth:availableWidth
            ScrollBar.horizontal.policy:ScrollBar.AlwaysOff
            ColumnLayout {
                width:scroll.availableWidth; spacing:2
                ColumnLayout {
                    visible:root.tab===0; Layout.fillWidth:true; spacing:2
                    Caption {text:"MEMORY · CURRENT & LAST 2 MINUTES"; Layout.topMargin:0}
                    RowLayout {Layout.fillWidth:true; spacing:10; Tile {metricId:"ram"} Tile {metricId:"vram"}}
                    Caption {text:"DISPLAY REFRESH"}
                    Repeater {
                        model:root.telemetry.displays || []
                        delegate:DisplayControl {
                            required property var modelData
                            display:modelData; busy:root.controlBusy
                            onModeRequested:(outputId,modeId)=>root.refreshRequested(outputId,modeId)
                        }
                    }
                    Note {visible:!(root.telemetry.displays || []).length; text:"Display modes unavailable. Check that kscreen-doctor is installed and your Plasma session is running."}
                    Caption {text:"COOLING"}
                    GridLayout {
                        Layout.fillWidth:true; columns:2; rowSpacing:10; columnSpacing:10
                        Repeater {model:root.fanIds; delegate:Tile {required property string modelData; metricId:modelData}}
                    }
                    Caption {text:"ACCELERATORS"}
                    RowLayout {Layout.fillWidth:true; spacing:10; Tile {metricId:"compute"} Tile {metricId:"npu"}}
                    Caption {text:"DISPLAY & SESSION"}
                    Reading {label:"Brightness / scale"; value:root.num(root.telemetry.brightness,"%")+"  /  "+root.num(root.display.scale ? root.display.scale*100 : null,"%")}
                    Reading {label:"CPU policy"; value:root.txt(root.cpu.epp)+"  ·  boost "+(root.cpu.boost==="1" ? "on" : root.cpu.boost==="0" ? "off" : "unknown")}
                    Reading {label:"Uptime"; value:root.duration(root.telemetry.uptime)}
                }
                ColumnLayout {
                    visible:root.tab===1; Layout.fillWidth:true; spacing:2
                    RowLayout {Layout.fillWidth:true
                        Caption {text:"CPU · "+(root.cpu.cores || []).length+" LOGICAL THREADS"; Layout.topMargin:0; Layout.fillWidth:true}
                        InfoButton {heading:"Logical-thread activity"; explanation:"Each cell shows the current utilization of one logical CPU thread, from /proc/stat deltas. The overall CPU trend appears in the header card. Values are workload, not temperature or hardware danger."}
                    }
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
                    Reading {label:"CPU core power"; value:root.num(root.cpu.watts," W",2)+" · "+Zones.power(root.cpu.watts,root.bands("cpu")).label; accent:Zones.power(root.stale?null:root.cpu.watts,root.bands("cpu")).color}
                    Reading {label:"Frequency policy range"; value:root.num(root.cpu.min_ghz,"",2)+"–"+root.num(root.cpu.max_ghz," GHz",2)}
                    Reading {label:"Load average · 1 / 5 / 15 min"; value:(root.cpu.load || []).join(" / ")}
                    Caption {text:"AMD GPU · MEMORY & ENGINES"}
                    RowLayout {Layout.fillWidth:true; spacing:10; Tile {metricId:"compute"} Tile {metricId:"media"}}
                    Reading {label:"GPU domain power"; value:root.num(root.gpu.watts," W",2); hint:root.metrics.gpuPower.info}
                    Reading {label:"GPU / memory clock"; value:root.num(root.gpu.clock," MHz")+" / "+root.num(root.gpu.mem_clock," MHz"); hint:"GPU core and memory clock frequencies reported by AMD firmware."}
                    RowLayout {Layout.fillWidth:true; spacing:10; Tile {metricId:"vram"} Tile {metricId:"gtt"}}
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
                    Caption {text:"POWER · CURRENT & LAST 2 MINUTES"; Layout.topMargin:0}
                    Note {text:"Green low · blue moderate · amber high · coral very high draw. Reference bands describe consumption, not hardware danger."}
                    GridLayout {
                        Layout.fillWidth:true; columns:2; columnSpacing:10; rowSpacing:10; Layout.topMargin:8
                        Tile {metricId:"apu"}
                        Tile {metricId:"cpuPower"}
                        Tile {metricId:"gpuPower"}
                        Tile {metricId:"npuPower"}
                        Tile {metricId:"batteryPower"; visible:root.battery.status==="Discharging"}
                    }
                    Caption {text:"ACTIVE POWER POLICY"}
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
                    Caption {text:"COOLING · CURRENT & LAST 2 MINUTES"; Layout.topMargin:0}
                    GridLayout {
                        Layout.fillWidth:true; columns:2; rowSpacing:10; columnSpacing:10
                        Repeater {model:root.fanIds; delegate:Tile {required property string modelData; metricId:modelData}}
                    }
                    Caption {text:"TEMPERATURES · DRIVER LIMITS"}
                    GridLayout {
                        Layout.fillWidth:true; columns:2; rowSpacing:10; columnSpacing:10
                        Repeater {model:root.temperatureIds; delegate:Tile {required property string modelData; metricId:modelData}}
                    }
                    Caption {text:"TELEMETRY NOTES"}
                    Note {text:"Danger is shown only at a driver-reported critical temperature. Missing limits remain unclassified. Hover a sensor for its source and limits. AMD metrics v3 provide GPU, CPU and NPU domain readings. All monitoring is read-only."}
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
