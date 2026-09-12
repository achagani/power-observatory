import QtQuick
import QtQuick.Layouts
Rectangle {
    id: card
    property string title
    property string value
    property string detail
    property color accent: "#6fe3ce"
    property var history: []
    property real ceiling: 100
    radius: 16; color: "#15232f"; border.color: "#263743"
    implicitHeight: 136
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 14; spacing: 3
        Text { text: card.title; color: card.accent; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.4 }
        Text { text: card.value; color: "#f0f5f8"; font.pixelSize: 27; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
        Text { text: card.detail; color: "#94a8b7"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
        Sparkline { Layout.fillWidth: true; Layout.fillHeight: true; values: card.history; accent: card.accent; ceiling: card.ceiling }
    }
}
