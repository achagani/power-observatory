import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
Item {
    id: row
    property string label
    property string value
    property string hint: ""
    property color accent: "#e2ecf3"
    Layout.fillWidth: true
    implicitHeight: Math.max(29, labelText.implicitHeight+8, valueText.implicitHeight+8)
    Text {
        id: labelText
        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
        width:parent.width*0.43
        text:row.label; color:"#91a6b6"; font.pixelSize:12; wrapMode:Text.WordWrap
    }
    Text {
        id: valueText
        anchors.right:parent.right; anchors.verticalCenter:parent.verticalCenter
        width:parent.width*0.54
        text:row.value; color:row.accent; font.pixelSize:12; font.weight:Font.Medium
        horizontalAlignment:Text.AlignRight; wrapMode:Text.Wrap
    }
    ToolTip.visible:hover.hovered && row.hint.length>0
    ToolTip.text:row.hint
    HoverHandler {id:hover}
}
