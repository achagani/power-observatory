.pragma library

var colors=["#75e3c5","#83bcff","#f0c582","#f48e92"]
function finite(v){return typeof v==="number"&&isFinite(v)}
function number(v,unit,digits){return finite(v)?v.toFixed(digits===undefined?0:digits)+(unit||""):"—"}
function gib(v){return number(finite(v)?v/1073741824:null," GiB",1)}
function ratio(used,total){return finite(used)&&used>=0&&finite(total)&&total>0?used/total*100:null}
function neutral(label,identity){return {edges:[],colors:["#83bcff"],labels:[label||"Reading"],identity:identity||""}}
function load(){return {edges:[40,80,95],colors:colors,labels:["Low load","Moderate","High load","Near capacity"]}}
function memory(total){return {edges:[60,85,95],colors:colors,labels:["Low use","Moderate","High use","Near full"],identity:String(total)}}
function power(edges){return {edges:edges,colors:colors,labels:["Low draw","Moderate","High draw","Very high draw"]}}
function thermal(s){
    var crit=finite(s.critical)&&s.critical>0?s.critical:null
    var high=finite(s.high)&&s.high>0?s.high:null
    var warn=crit!==null?Math.min(high===null?crit*.9:high,crit*.9):high
    if(warn===null)return {edges:[],colors:["#8294a3"],labels:["Limit unavailable"]}
    var edges=[warn], palette=[colors[0],colors[2]],labels=["Below limit",high!==null&&high<=warn?"Over high limit":"Near critical"]
    if(crit!==null){edges.push(crit);palette.push("#ff6578");labels.push("Critical temperature")}
    return {edges:edges,colors:palette,labels:labels}
}
function make(id,title,value,display,detail,maximum,unit,policy,info){
    return {id:id,title:title,value:finite(value)?value:null,display:display,detail:detail,maximum:maximum,unit:unit,policy:policy,info:info}
}
function build(t){
    var cpu=t.cpu||{},gpu=t.gpu||{},ram=t.ram||{},npu=t.npu||{},battery=t.battery||{}
    var result={},defs={apu:[30,60,90],cpu:[15,35,60],gpu:[10,25,50],npu:[2,5,10],battery:[15,30,45]}
    var utilizationInfo="Average activity. Zones: low <40%, moderate 40–80%, high 80–95%, near capacity ≥95%. High utilization is not hardware danger."
    result.cpu=make("cpu","CPU activity",cpu.busy,number(cpu.busy,"%",1),number(cpu.temp,"°C")+" · "+number(cpu.ghz," GHz",2),100,"%",load(),"CPU usage across all logical threads, measured from /proc/stat. "+utilizationInfo)
    result.gpu=make("gpu","GPU activity",gpu.busy,number(gpu.busy,"%",1),number(gpu.temp,"°C")+" · "+number(gpu.clock," MHz"),100,"%",load(),"Overall AMD GPU busy time from the driver. This includes graphics and compute work. "+utilizationInfo)
    result.compute=make("compute","GPU compute activity",gpu.compute,number(gpu.compute,"%",1),"Compute-engine time",100,"%",load(),"Compute-engine activity from readable applications owned by your Linux account. Other users and inaccessible processes are excluded. Parallel engines can exceed 100%; the number stays exact while the plot clips at 100%. This is not GPU memory usage or overall GPU activity.")
    result.media=make("media","Video engine",gpu.media,number(gpu.media,"%",1),"Encode / decode activity",100,"%",load(),"AMD firmware's video engine activity. Not all video software uses hardware acceleration. "+utilizationInfo)
    result.npu=make("npu","NPU activity",npu.busy,number(npu.busy,"%",1),npu.state||"State unavailable",100,"%",load(),"Mean firmware activity across supported IPU columns. Suspended describes the NPU's runtime power state, not an independently measured utilization percentage. "+utilizationInfo)
    var memories=[['ram','System RAM',ram.used,ram.total,'Used = MemTotal − MemAvailable. Linux system RAM excludes firmware-reserved GPU memory.'],['vram','GPU memory',gpu.vram_used,gpu.vram_total,'GPU-reserved UMA/VRAM allocation. On a unified-memory machine this is a firmware-reserved pool; it is not additional physical memory.'],['gtt','GPU shared memory',gpu.gtt_used,gpu.gtt_total,'GTT allocations use Linux system RAM. Do not add this to RAM/VRAM totals as extra physical capacity.']]
    memories.forEach(function(m){var p=ratio(m[2],m[3]);result[m[0]]=make(m[0],m[1],p,number(p,"%",1),gib(m[2])+" / "+gib(m[3]),100,"%",memory(m[3]),m[4]+" Zones: low <60%, moderate 60–85%, high 85–95%, near full ≥95%. These describe capacity pressure, not hardware safety.")})
    ;[['apu','APU power',t.apu_watts,'Whole-chip power; not AC wall consumption.'],['cpuPower','CPU power',cpu.watts,'CPU core power; already a component of chip power.'],['gpuPower','GPU power',gpu.watts,'GPU domain power; already a component of chip power.'],['npuPower','NPU power',npu.watts,'NPU domain power reported by AMD firmware.'],['batteryPower','Battery discharge',battery.status==='Discharging'?battery.watts:null,'System power drawn from the battery. AC plus discharge means the battery is supplementing the adapter. Charging watts are not graded against discharge bands.']].forEach(function(m){
        var domain={cpuPower:'cpu',gpuPower:'gpu',npuPower:'npu',batteryPower:'battery'}[m[0]]||m[0]
        var edges=(t.power_bands||{})[domain]||defs[domain]
        var ref=(t.power_references||{})[domain]||{source:'Estimated reference',maximum:edges[2]*4/3}
        var policy=power(edges);policy.identity=ref.source+':' +(ref.field||'')
        result[m[0]]=make(m[0],m[1],m[2],number(m[2]," W",1),ref.source+" · "+number(ref.maximum," W",1),ref.maximum," W",policy,m[3]+" "+ref.source+". "+(ref.field||"")+". Reference zones: low <"+edges[0]+" W, moderate "+edges[0]+"–"+edges[1]+" W, high "+edges[1]+"–"+edges[2]+" W, very high ≥"+edges[2]+" W. These configurable display bands are not safety limits, enforced power limits, or charger headroom.")
    })
    ;(t.fans||[]).forEach(function(s,i){
        var id='fan:'+(s.identity||s.path||s.name+':'+i)
        var max=finite(s.reference_rpm)&&s.reference_rpm>0?s.reference_rpm:null
        var source=s.reference_source||"Reference unavailable"
        var policy=max!==null?{edges:[max*.4,max*.8,max*.95],colors:colors,
            labels:["Low effort","Moderate effort","High effort","Near reference"],identity:source}:neutral('Unclassified')
        result[id]=make(id,s.name.replace('cpu_fan','CPU fan').replace('gpu_fan','GPU fan'),s.value,number(s.value,' RPM'),
            source,max||Math.max(1,s.value||0),' RPM',policy,
            "Measured fan speed. "+source+": "+number(max,' RPM')+". Zones at 40%, 80%, and 95% describe speed relative to this reference, not thermal danger. A driver high threshold is not necessarily a rated maximum. An estimated range rounds the session's observed peak upward to 1000 RPM and only grows; it cannot establish physical capacity. A newly observed idle fan remains unclassified until a positive reading arrives. ACPI may mirror another fan. Configure fan_reference_rpm using this sensor key: "+(s.identity||s.path||'unavailable'))
    })
    ;(t.sensors||[]).forEach(function(s,i){var id='temp:'+(s.path||s.name+':'+i),max=finite(s.critical)&&s.critical>0?s.critical:(finite(s.high)&&s.high>0?Math.max(s.high,s.value||0):Math.max(120,Math.ceil((s.value||0)/10)*10));result[id]=make(id,s.name,s.value,number(s.value,'°C',1),(finite(s.critical)?"Driver critical · "+number(s.critical,'°C'):(finite(s.high)?"Driver high · "+number(s.high,'°C'):"Estimated display range")),max,"°C",thermal(s),"Temperature from this sensor only. Driver high: "+number(s.high,'°C')+"; critical: "+number(s.critical,'°C')+". Amber begins at the lower of the high limit or 90% of critical; a red Critical temperature state requires the reported critical threshold. If neither exists, the value stays unclassified. Source: "+(s.path||'unavailable'))})
    return result
}
