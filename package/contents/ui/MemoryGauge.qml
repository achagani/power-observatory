import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Zones.js" as Zones

Rectangle {
    id: card
    property string title: "MEMORY"
    property var used: null
    property var total: null
    property string hint: ""
    readonly property var zone: Zones.memory(used, total)
    readonly property real fillFraction: zone.ratio === null ? 0 : Zones.clamp(zone.ratio)
    implicitHeight: 123
    radius: 13; color: "#142430"; border.color: "#283c49"
    Layout.fillWidth: true
    function gib(v) { return Zones.valid(v) ? (v/1073741824).toFixed(1)+" GiB" : "—" }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 13; spacing: 7
        RowLayout {
            Layout.fillWidth: true
            Text {text:card.title; color:"#a9c3d6"; font.pixelSize:10; font.bold:true; font.letterSpacing:1; Layout.fillWidth:true; elide:Text.ElideRight}
            Text {text:card.zone.ratio===null ? "—" : Math.round(card.zone.ratio*100)+"%"; color:card.zone.color; font.pixelSize:18; font.weight:Font.DemiBold}
        }
        Rectangle {
            id: track
            Layout.fillWidth:true; height:9; radius:4; color:"#2a3c49"
            Rectangle {width:parent.width*card.fillFraction; height:parent.height; radius:4; color:card.zone.color; Behavior on width {NumberAnimation {duration:250}}}
            Repeater {model:[0.60,0.85,0.95]; delegate:Rectangle {required property real modelData; x:modelData*track.width; width:1; height:track.height+4; y:-2; color:"#91a6b6"; opacity:0.55}}
        }
        Text {text:card.gib(card.used)+" / "+card.gib(card.total); color:"#e0ebf3"; font.pixelSize:11; Layout.fillWidth:true; elide:Text.ElideRight}
        Text {text:card.zone.label; color:card.zone.color; font.pixelSize:11; font.weight:Font.Medium}
    }
    ToolTip.visible:hover.hovered
    ToolTip.text:hint+"\nUse zones: low <60%, moderate 60–85%, high 85–95%, near full ≥95%. Capacity pressure, not hardware danger."
    HoverHandler {id:hover}
    Accessible.name:title+": "+gib(used)+" of "+gib(total)+", "+zone.label
}
