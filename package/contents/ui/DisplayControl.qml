import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: control
    property var display: ({})
    property bool busy: false
    signal modeRequested(string outputId, string modeId)
    spacing: 7
    Layout.fillWidth: true
    function rate(hz) { return Number(hz.toFixed(2)).toString() + " Hz" }
    RowLayout {
        Layout.fillWidth: true
        Text { text: control.display.name || "Display"; color: "#d5e8f4"; font.pixelSize: 12; font.weight: Font.Medium }
        Item { Layout.fillWidth: true }
        Text { text: control.display.width ? control.display.width + " × " + control.display.height : "Current mode unavailable"; color: "#8199ac"; font.pixelSize: 11 }
    }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: control.display.refresh_modes || []
            delegate: Button {
                required property var modelData
                objectName: "refresh-" + control.display.id + "-" + modelData.id
                implicitWidth: Math.max(82, contentItem.implicitWidth + 26)
                implicitHeight: 31
                enabled: !control.busy && !modelData.active
                onClicked: control.modeRequested(String(control.display.id), String(modelData.id))
                contentItem: Text {
                    text: control.rate(modelData.hz) + (modelData.active ? "  ✓" : "")
                    color: modelData.active ? "#c8ecff" : "#afc2d2"
                    font.pixelSize: 12; font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 8
                    color: modelData.active ? "#294963" : parent.hovered ? "#253b4b" : "#182c3a"
                    border.color: modelData.active ? "#5386ae" : "#2b4254"
                }
                ToolTip.visible: hovered
                ToolTip.text: modelData.active ? "Current refresh rate" : "Set " + control.display.name + " to " + control.rate(modelData.hz) + " at its current resolution"
            }
        }
    }
    Text {
        visible: !(control.display.refresh_modes || []).length
        text: "No refresh modes reported by KScreen"
        color: "#8da3b4"; font.pixelSize: 11
    }
}
