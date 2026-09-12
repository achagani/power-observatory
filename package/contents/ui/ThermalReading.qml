import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "Zones.js" as Zones

ColumnLayout {
    id: row
    property var sensor: ({})
    property bool stale: false
    readonly property var zone: Zones.thermal(stale ? null : sensor.value,sensor.high,sensor.critical)
    readonly property real maximum: Zones.valid(sensor.critical) && sensor.critical>0 ? sensor.critical : Zones.valid(sensor.high) && sensor.high>0 ? sensor.high : 0
    Layout.fillWidth:true; spacing:2; Layout.bottomMargin:8
    Reading {
        label:row.sensor.name || "Temperature"
        value:row.stale || typeof row.sensor.value !== "number" || !isFinite(row.sensor.value)?"—":row.sensor.value.toFixed(1)+" °C"
        accent:row.zone.color; hint:row.sensor.path || ""
    }
    RowLayout {
        Layout.fillWidth:true
        Rectangle {
            Layout.fillWidth:true; height:4; radius:2; color:"#293c49"
            Rectangle {height:4; radius:2; width:parent.width*(row.maximum>0 && !row.stale ? Zones.clamp((row.sensor.value || 0)/row.maximum):0); color:row.zone.color}
        }
        Text {text:row.zone.label; font.pixelSize:10; color:row.zone.color}
    }
    ToolTip.visible:hover.hovered
    ToolTip.text:(sensor.path || "")+"\nDriver high: "+(Zones.valid(sensor.high)?sensor.high.toFixed(1)+" °C":"unavailable")+"; critical: "+(Zones.valid(sensor.critical)?sensor.critical.toFixed(1)+" °C":"unavailable")+". Near critical starts at 90% of the reported critical value."
    HoverHandler {id:hover}
}
