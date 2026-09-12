import QtQuick
Canvas {
    id: plot
    property var values: []
    property color accent: "#6fe3ce"
    property real ceiling: 100
    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const c = getContext("2d"); c.reset()
        if (!values || values.length < 2) return
        const max = ceiling > 0 ? ceiling : Math.max(10, ...values.filter(v => v !== null)) * 1.15
        c.strokeStyle = accent; c.lineWidth = 1.8; c.lineJoin = "round"
        c.beginPath(); let started = false
        for (let i=0;i<values.length;i++) {
            if (values[i] === null) { started=false; continue }
            const x = i/(values.length-1)*width
            const y = height-3-Math.min(1,Math.max(0,values[i]/max))*(height-6)
            if (!started) { c.moveTo(x,y); started=true } else c.lineTo(x,y)
        }
        c.stroke()
    }
}
