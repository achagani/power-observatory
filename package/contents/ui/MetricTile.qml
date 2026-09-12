import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "History.js" as History

Rectangle {
    id:card
    property string title: "Metric"
    property string readingText: "—"
    property string detail: ""
    property string explanation: ""
    property var value: null
    property real maximum:100
    property string scaleUnit:"%"
    property var policy: ({edges:[],colors:["#83bcff"],labels:["Reading"]})
    property var samples:[]
    property double now:0
    property int windowSeconds:120
    property bool stale:false
    property bool compact:false
    readonly property bool available:!stale&&History.finite(value)
    readonly property color statusColor:available?History.colorAt(value,policy.edges,policy.colors):"#8294a3"
    readonly property real fillFraction:available&&maximum>0?Math.max(0,Math.min(1,value/maximum)):0
    readonly property string statusText: {
        if(stale)return "Stale"
        if(!available)return "Unavailable"
        var i=0;while(i<policy.edges.length && value>=policy.edges[i])i++
        return policy.labels[Math.min(i,policy.labels.length-1)]
    }
    implicitHeight:compact?212:220
    radius:14; color:"#142430"; border.color:"#293d4b"
    Accessible.name:title+": "+readingText+", "+statusText
    ColumnLayout {
        anchors.fill:parent; anchors.margins:12; spacing:3
        RowLayout {
            Layout.fillWidth:true; spacing:2
            Text {text:card.title; color:"#a9c3d6"; font.pixelSize:10; font.weight:Font.DemiBold; font.letterSpacing:0.6; Layout.fillWidth:true; elide:Text.ElideRight}
            InfoButton {objectName:card.objectName+"-info"; heading:card.title; explanation:card.explanation+"\nTrend: last 2 minutes, fixed 0–"+card.maximum+card.scaleUnit+" display scale. Colors preserve the zones recorded at the time. Gaps mean missing samples or a changed measurement basis. The bar is the latest reading."}
        }
        Text {text:card.readingText; color:"#f0f5f8"; font.pixelSize:card.compact?23:25; font.weight:Font.DemiBold; Layout.fillWidth:true; elide:Text.ElideRight}
        Text {text:card.detail; visible:text.length>0; color:"#9bb1c2"; font.pixelSize:10; Layout.fillWidth:true; elide:Text.ElideRight}
        RowLayout {
            Layout.fillWidth:true
            Text {text:"Last 2 minutes"; font.pixelSize:9; color:"#88a2b6"}
            Item {Layout.fillWidth:true}
            Text {text:card.maximum+card.scaleUnit; font.pixelSize:9; color:"#88a2b6"}
        }
        TrendChart {objectName:card.objectName+"-trend"; Layout.fillWidth:true; Layout.fillHeight:true; Layout.minimumHeight:42; samples:card.samples; now:card.now; maximum:card.maximum; windowSeconds:card.windowSeconds}
        RowLayout {
            Layout.fillWidth:true
            Text {text:"−2m"; font.pixelSize:8; color:"#8099ac"}
            Item {Layout.fillWidth:true}
            Text {text:"−1m"; font.pixelSize:8; color:"#8099ac"}
            Item {Layout.fillWidth:true}
            Text {text:"now"; font.pixelSize:8; color:"#8099ac"}
        }
        Rectangle {
            id:bar
            Layout.fillWidth:true; Layout.topMargin:5; implicitHeight:6; radius:3; color:"#2c4050"
            Rectangle {height:parent.height; width:parent.width*card.fillFraction; radius:3; color:card.statusColor; Behavior on width {NumberAnimation {duration:180}}}
            Repeater {model:card.policy.edges; delegate:Rectangle {required property real modelData; visible:modelData>0&&modelData<card.maximum; x:Math.min(1,Math.max(0,modelData/card.maximum))*bar.width; y:-2; width:1; height:10; color:"#b6c8d5"; opacity:.6}}
        }
        RowLayout {
            Layout.fillWidth:true; Layout.topMargin:3
            Text {text:card.statusText; color:card.statusColor; font.pixelSize:10; font.weight:Font.Medium; Layout.fillWidth:true; elide:Text.ElideRight}
            Text {text:card.available&&card.value>card.maximum?"↑ over scale":"now"; color:"#8fa7b9"; font.pixelSize:9}
        }
    }
}
