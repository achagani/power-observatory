import QtQuick
import "Zones.js" as Zones

Item {
    id: gauge
    property var reading: null
    property real maximum: 120
    property var edges: [30,60,90]
    property string unit: "W"
    property int digits: 1
    readonly property var zone: Zones.power(reading,edges)
    readonly property real fraction: Zones.valid(reading) && maximum>0 ? Zones.clamp(reading/maximum) : 0
    implicitWidth: 170; implicitHeight: 100
    Canvas {
        id: arc
        anchors.fill:parent
        onWidthChanged:requestPaint()
        onHeightChanged:requestPaint()
        Connections {target:gauge; function onReadingChanged(){arc.requestPaint()} function onMaximumChanged(){arc.requestPaint()} function onEdgesChanged(){arc.requestPaint()} }
        onPaint: {
            var c=getContext("2d"); c.reset()
            var cx=width/2, cy=height*0.61, r=Math.min(width*0.41,height*0.52)
            var start=Math.PI*0.75, sweep=Math.PI*1.5
            var stops=[0].concat(gauge.edges.map(v=>Zones.clamp(v/gauge.maximum))).concat([1])
            c.lineWidth=6; c.lineCap="round"
            for(var i=0;i<4;i++) {
                c.beginPath(); c.strokeStyle=gauge.zone.index<0?"#354650":Zones.colors[i]
                c.globalAlpha=gauge.zone.index<0?0.5:0.45
                c.arc(cx,cy,r,start+sweep*stops[i]+0.025,start+sweep*stops[i+1]-0.025); c.stroke()
            }
            c.globalAlpha=1
            if(gauge.zone.index>=0) {
                var angle=start+sweep*gauge.fraction
                var px=cx+Math.cos(angle)*r, py=cy+Math.sin(angle)*r
                c.beginPath(); c.fillStyle="#f0f7fb"; c.arc(px,py,4.5,0,Math.PI*2); c.fill()
            }
        }
    }
    Text {x:0; y:parent.height*0.46; width:parent.width; horizontalAlignment:Text.AlignHCenter; text:Zones.valid(gauge.reading)?Number(gauge.reading).toFixed(gauge.digits):"—"; color:"#f0f5f8"; font.pixelSize:27; font.weight:Font.DemiBold}
    Text {anchors.horizontalCenter:parent.horizontalCenter; y:parent.height*0.79; text:gauge.unit; color:"#90a8ba"; font.pixelSize:10}
}
