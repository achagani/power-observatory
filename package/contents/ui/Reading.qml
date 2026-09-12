import QtQuick
import QtQuick.Layouts
import "InfoText.js" as InfoText
Item {
    id:row
    property string label
    property string value
    property string hint:""
    property color accent:"#e2ecf3"
    Layout.fillWidth:true
    implicitHeight:Math.max(30,labelText.implicitHeight+8,valueText.implicitHeight+8)
    Text {id:labelText; anchors.left:parent.left; anchors.verticalCenter:parent.verticalCenter; width:parent.width*.40-26; text:row.label; color:"#91a6b6"; font.pixelSize:12; wrapMode:Text.WordWrap}
    InfoButton {x:parent.width*.40-24; anchors.verticalCenter:parent.verticalCenter; heading:row.label; explanation:row.hint || InfoText.explain(row.label)}
    Text {id:valueText; anchors.right:parent.right; anchors.verticalCenter:parent.verticalCenter; width:parent.width*.56; text:row.value; color:row.accent; font.pixelSize:12; font.weight:Font.Medium; horizontalAlignment:Text.AlignRight; wrapMode:Text.Wrap}
}
