import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Zones.js" as Zones

Rectangle {
    id: card
    property string title: "APU POWER"
    property var watts: null
    property var bands: [30,60,90]
    property string hint: "Chip power, not wall draw."
    property var history: []
    property bool showHistory: false
    readonly property var zone: Zones.power(watts,bands)
    implicitHeight: showHistory ? 198 : 177
    radius:16; color:"#15232f"; border.color:"#2a3c49"
    ColumnLayout {
        anchors.fill:parent; anchors.margins:12; spacing:1
        Text {text:card.title; color:"#f0c582"; font.pixelSize:10; font.bold:true; font.letterSpacing:1.1; Layout.fillWidth:true; elide:Text.ElideRight}
        ArcGauge {Layout.fillWidth:true; Layout.fillHeight:true; Layout.minimumHeight:80; reading:card.watts; edges:card.bands; maximum:card.bands[2]*4/3}
        Text {text:card.zone.label; color:card.zone.color; font.pixelSize:11; font.weight:Font.DemiBold; Layout.alignment:Qt.AlignHCenter}
        Text {text:"Reference zones"; color:"#889faf"; font.pixelSize:9; Layout.alignment:Qt.AlignHCenter}
        Text {text:card.bands.join(" / ")+" W"; color:"#a4b7c6"; font.pixelSize:9; Layout.alignment:Qt.AlignHCenter}
        Sparkline {visible:card.showHistory; Layout.fillWidth:true; Layout.preferredHeight:18; values:card.history; accent:card.zone.color; ceiling:card.bands[2]*4/3}
    }
    ToolTip.visible:hover.hovered
    ToolTip.text:hint+"\nLow <"+bands[0]+" W; moderate "+bands[0]+"–"+bands[1]+" W; high "+bands[1]+"–"+bands[2]+" W; very high ≥"+bands[2]+" W.\nConfigurable reference bands, not hardware safety limits."
    HoverHandler {id:hover}
    Accessible.name:title+": "+(Zones.valid(watts)?watts.toFixed(1)+" watts":"unavailable")+", "+zone.label+", reference zones"
}
