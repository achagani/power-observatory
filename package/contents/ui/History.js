.pragma library

function finite(v) { return typeof v === "number" && isFinite(v) }
function colorAt(value, edges, colors) {
    var i=0
    while(i<edges.length && value>=edges[i]) i++
    return colors[Math.min(i,colors.length-1)]
}
function append(points, time, value, policy, windowSeconds) {
    if (!finite(time)) return points || []
    var copy=(points || []).slice()
    // Ignore duplicate/older timestamps (e.g. a control response for the same sample).
    if (copy.length && time<=copy[copy.length-1].t) return copy
    copy.push({t:time,v:finite(value)?value:null,edges:policy.edges.slice(),colors:policy.colors.slice(),
               key:JSON.stringify([policy.edges,policy.colors,policy.identity || ""])})
    var cutoff=time-windowSeconds
    // Keep one predecessor so a line crossing the left boundary can be clipped.
    while(copy.length>1 && copy[1].t<cutoff) copy.shift()
    return copy.slice(-256)
}
function segments(points, start, end, gapSeconds) {
    var result=[]
    for(var i=1;i<points.length;i++) {
        var a=points[i-1], b=points[i]
        if(!finite(a.v)||!finite(b.v)||b.t<=a.t||b.t-a.t>gapSeconds||a.key!==b.key) continue
        if(b.t<start||a.t>end) continue
        var cuts=[Math.max(0,(start-a.t)/(b.t-a.t)),Math.min(1,(end-a.t)/(b.t-a.t))]
        if(cuts[0]>=cuts[1]) continue
        if(b.v!==a.v) for(var j=0;j<a.edges.length;j++) {
            var f=(a.edges[j]-a.v)/(b.v-a.v)
            if(f>cuts[0]&&f<cuts[1]) cuts.push(f)
        }
        cuts.sort(function(x,y){return x-y})
        for(var k=1;k<cuts.length;k++) {
            var lo=cuts[k-1],hi=cuts[k]
            result.push({t0:a.t+(b.t-a.t)*lo,t1:a.t+(b.t-a.t)*hi,
                v0:a.v+(b.v-a.v)*lo,v1:a.v+(b.v-a.v)*hi,
                color:colorAt(a.v+(b.v-a.v)*(lo+hi)/2,a.edges,a.colors)})
        }
    }
    return result
}
