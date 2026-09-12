.pragma library

var colors = ["#75e3c5", "#83bcff", "#f0c582", "#f48e92"]
var muted = "#8294a3"
function valid(v) { return typeof v === "number" && isFinite(v) && v >= 0 }
function clamp(v) { return Math.max(0, Math.min(1, v)) }
function band(value, edges, labels) {
    if (!valid(value)) return {index: -1, label: "Unavailable", color: muted}
    var index = 0
    while (index < edges.length && value >= edges[index]) index++
    return {index: index, label: labels[index], color: colors[index]}
}
function memory(used, total) {
    var ratio = valid(used) && valid(total) && total > 0 ? used / total : null
    var zone = band(ratio, [0.60, 0.85, 0.95], ["Low use", "Moderate", "High use", "Near full"])
    zone.ratio = ratio
    return zone
}
function load(percent) {
    return band(percent, [40, 80, 95], ["Low load", "Moderate", "High load", "Near capacity"])
}
function power(watts, edges) {
    return band(watts, edges, ["Low draw", "Moderate", "High draw", "Very high draw"])
}
function thermal(value, high, critical) {
    if (typeof value !== "number" || !isFinite(value)) return {index:-1, label:"Unavailable", color:muted}
    if (valid(critical) && critical > 0 && value >= critical)
        return {index:3, label:"Danger · critical", color:colors[3]}
    if (valid(high) && high > 0 && value >= high)
        return {index:2, label:"High · over max", color:colors[2]}
    if (valid(critical) && critical > 0 && value >= 0.9 * critical)
        return {index:2, label:"Near critical", color:colors[2]}
    if ((valid(high) && high > 0) || (valid(critical) && critical > 0))
        return {index:0, label:"Below limit", color:colors[0]}
    return {index:-1, label:"Limit unavailable", color:muted}
}
