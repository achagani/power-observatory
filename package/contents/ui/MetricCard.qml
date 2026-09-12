import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Zones.js" as Zones
Rectangle {
    id: card
    property string title
    property string value
    property var load: null
    readonly property var zone: Zones.load(load)
    property string detail
    property color accent: "#6fe3ce"
    property var history: []
    property real ceiling: 100
    radius: 16; color: "#15232f"; border.color: "#263743"
    implicitHeight: 198
    ToolTip.visible:hover.hovered
    ToolTip.text:"Utilization zones: low <40%, moderate 40–80%, high 80–95%, near capacity ≥95%. High load is not hardware danger."
    HoverHandler {id:hover}
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 14; spacing: 3
        Text { text: card.title; color: card.accent; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.4 }
        Text { text: card.value; color: "#f0f5f8"; font.pixelSize: 27; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
        Text { text: card.detail; color: "#94a8b7"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
        Text {text:card.zone.label; color:card.zone.color; font.pixelSize:11; font.weight:Font.Medium}
        Sparkline { Layout.fillWidth: true; Layout.fillHeight: true; values: card.history; accent: card.accent; ceiling: card.ceiling }
    }
}
