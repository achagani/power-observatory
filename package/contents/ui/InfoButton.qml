import QtQuick
import QtQuick.Controls

ToolButton {
    id: info
    property string heading: "About this reading"
    property string explanation: ""
    readonly property bool popupVisible: details.visible
    implicitWidth:24; implicitHeight:24
    hoverEnabled:true
    focusPolicy:Qt.StrongFocus
    Accessible.name:"Information: "+heading
    Accessible.description:explanation
    contentItem: Text {text:"i"; font.pixelSize:12; font.bold:true; color:info.hovered||info.activeFocus?"#d9edff":"#92acbf"; horizontalAlignment:Text.AlignHCenter; verticalAlignment:Text.AlignVCenter}
    background: Rectangle {radius:12; color:info.hovered||info.activeFocus?"#2b4354":"transparent"; border.color:info.activeFocus?"#83bcff":"#3d5364"; border.width:1; anchors.centerIn:parent; width:16; height:16}
    onClicked:details.visible?details.close():details.open()
    Keys.onReturnPressed:click()
    Keys.onEnterPressed:click()
    ToolTip {
        visible:(info.hovered||info.activeFocus)&&!details.visible
        delay:250; timeout:12000
        width:Math.min(360,Overlay.overlay?Overlay.overlay.width-24:360)
        margins:12; padding:12
        contentItem:Text {text:info.heading+"\n"+info.explanation+"\nClick or press Enter to keep this open."; color:"#d1e3ef"; font.pixelSize:12; wrapMode:Text.WordWrap}
        background:Rectangle {radius:10; color:"#172a38"; border.color:"#557187"}
    }
    Popup {
        id:details
        parent:Overlay.overlay
        anchors.centerIn:parent
        width:Math.min(360,parent ? parent.width-32 : 360)
        padding:18; modal:false; focus:true
        closePolicy:Popup.CloseOnEscape|Popup.CloseOnPressOutside
        background:Rectangle {radius:14; color:"#172a38"; border.color:"#557187"}
        contentItem:Column {
            spacing:12
            Text {width:parent.width; text:info.heading; color:"#edf5fb"; font.pixelSize:15; font.bold:true; wrapMode:Text.WordWrap}
            Text {width:parent.width; text:info.explanation; color:"#b4c8d8"; font.pixelSize:12; wrapMode:Text.WordWrap; lineHeight:1.25}
            Button {text:"Close"; onClicked:details.close(); Accessible.name:"Close metric information"}
        }
    }
}
