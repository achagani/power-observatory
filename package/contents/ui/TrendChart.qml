import QtQuick
import "History.js" as History

Canvas {
    id:chart
    property var samples:[]
    property double now:0
    property real maximum:100
    property int windowSeconds:120
    readonly property var coloredSegments:History.segments(samples,now-windowSeconds,now,8)
    onColoredSegmentsChanged:requestPaint()
    onMaximumChanged:requestPaint()
    onWidthChanged:requestPaint()
    onHeightChanged:requestPaint()
    onPaint: {
        var c=getContext("2d");c.reset()
        var bottom=height-2,top=2,h=Math.max(1,bottom-top)
        var start=now-windowSeconds
        function x(t){return (t-start)/chart.windowSeconds*chart.width}
        function y(v){return bottom-Math.max(0,Math.min(1,v/chart.maximum))*h}
        c.lineWidth=1;c.strokeStyle="#2b4050"
        for(var i=0;i<=2;i++){c.beginPath();c.moveTo(i*width/2,top);c.lineTo(i*width/2,bottom);c.stroke()}
        c.beginPath();c.moveTo(0,bottom);c.lineTo(width,bottom);c.stroke()
        c.save();c.beginPath();c.rect(0,0,width,height);c.clip()
        for(var j=0;j<coloredSegments.length;j++) {
            var s=coloredSegments[j],x0=x(s.t0),x1=x(s.t1),y0=y(s.v0),y1=y(s.v1)
            // The translucent area never covers the current meter or reduces line opacity.
            c.globalAlpha=.10;c.fillStyle=s.color;c.beginPath();c.moveTo(x0,bottom);c.lineTo(x0,y0);c.lineTo(x1,y1);c.lineTo(x1,bottom);c.closePath();c.fill()
            c.globalAlpha=1;c.strokeStyle=s.color;c.lineWidth=2;c.lineCap="butt";c.beginPath();c.moveTo(x0,y0);c.lineTo(x1,y1);c.stroke()
        }
        // Isolated first samples are visible as dots; unknown samples remain empty.
        c.globalAlpha=1
        for(var k=0;k<samples.length;k++) {
            var p=samples[k]
            if(!History.finite(p.v)||p.t<start||p.t>now)continue
            c.fillStyle=History.colorAt(p.v,p.edges,p.colors);c.beginPath();c.arc(x(p.t),y(p.v),1.2,0,Math.PI*2);c.fill()
        }
        c.restore()
    }
}
