import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: applet
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    property var telemetry: ({})
    property string failure: ""
    property bool collecting: false
    property bool controlling: false
    property double lastSuccess: 0
    property bool stale: false
    property string helper: decodeURIComponent(Qt.resolvedUrl("../code/telemetry.py").toString().replace(/^file:\/\//,""))
    property string command: "python3 '"+helper.replace(/'/g,"'\\''")+"'"
    preferredRepresentation: fullRepresentation
    function poll() {
        if (!collecting && !controlling) { collecting=true; source.connectSource(command) }
    }
    function control(args) {
        if (controlling || collecting) return
        controlling=true; failure=""; source.connectSource(command+" "+args)
    }
    Plasma5Support.DataSource {
        id: source
        engine: "executable"
        connectedSources: []
        onNewData: (name, data) => {
            source.disconnectSource(name)
            const isControl=name!==applet.command
            if (isControl) applet.controlling=false; else applet.collecting=false
            try {
                if (data["exit code"] !== 0) throw new Error(data.stderr || "Collector failed")
                let result=JSON.parse(data.stdout)
                if (isControl) {
                    if (!result.ok) throw new Error(result.error)
                    result=result.telemetry
                }
                applet.telemetry=result; applet.lastSuccess=Date.now(); applet.stale=false; applet.failure=""
            } catch(e) { applet.failure=String(e) }
        }
    }
    Timer {interval:2000; running:true; repeat:true; triggeredOnStart:true; onTriggered:{applet.stale=applet.lastSuccess>0 && Date.now()-applet.lastSuccess>8000; applet.poll()} }
    fullRepresentation: Dashboard {
        Layout.minimumWidth:480; Layout.minimumHeight:610
        Layout.preferredWidth:640; Layout.preferredHeight:890
        telemetry:applet.telemetry; stale:applet.stale; error:applet.failure
        controlBusy:applet.controlling || applet.collecting
        onProfileRequested:(profile)=>applet.control("--profile "+profile)
        onRefreshRequested:(outputId,modeId)=>{
            if (/^[A-Za-z0-9_-]+$/.test(outputId) && /^[A-Za-z0-9_-]+$/.test(modeId))
                applet.control("--display-mode "+outputId+" "+modeId)
        }
    }
    compactRepresentation: Button {
        text:applet.telemetry.apu_watts !== undefined ? Number(applet.telemetry.apu_watts).toFixed(0)+" W" : "Power"
        onClicked:applet.expanded=!applet.expanded
        ToolTip.visible:hovered
        ToolTip.text:"Power Observatory · APU power"
    }
    toolTipMainText:"Power Observatory"
    toolTipSubText:"Live power, thermals and compute"
}
