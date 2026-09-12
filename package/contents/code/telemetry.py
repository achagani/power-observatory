#!/usr/bin/env python3
"""Read-only, dependency-free telemetry for Power Observatory. No privileged reads."""
import ctypes as C
import json
import os
from pathlib import Path
import re
import subprocess
import time
import sys

U16, U32, U64 = C.c_uint16, C.c_uint32, C.c_uint64
class MetricsV3(C.LittleEndianStructure):
    _fields_ = [('size', U16), ('format', C.c_uint8), ('content', C.c_uint8)] + [
        ('temperature_gfx', U16), ('temperature_soc', U16), ('temperature_core', U16*16),
        ('temperature_skin', U16), ('average_gfx_activity', U16), ('average_vcn_activity', U16),
        ('average_ipu_activity', U16*8), ('average_core_c0_activity', U16*16),
        ('average_dram_reads', U16), ('average_dram_writes', U16),
        ('average_ipu_reads', U16), ('average_ipu_writes', U16), ('system_clock_counter', U64),
        ('average_socket_power', U32), ('average_ipu_power', U16), ('average_apu_power', U32),
        ('average_gfx_power', U32), ('average_dgpu_power', U32), ('average_all_core_power', U32),
        ('average_core_power', U16*16), ('average_sys_power', U16), ('stapm_power_limit', U16),
        ('current_stapm_power_limit', U16), ('average_gfxclk_frequency', U16),
        ('average_socclk_frequency', U16), ('average_vpeclk_frequency', U16),
        ('average_ipuclk_frequency', U16), ('average_fclk_frequency', U16),
        ('average_vclk_frequency', U16), ('average_uclk_frequency', U16),
        ('average_mpipu_frequency', U16), ('current_coreclk', U16*16),
        ('current_core_maxfreq', U16), ('current_gfx_maxfreq', U16),
        ('throttle_residency_prochot', U32), ('throttle_residency_spl', U32),
        ('throttle_residency_fppt', U32), ('throttle_residency_sppt', U32),
        ('throttle_residency_thm_core', U32), ('throttle_residency_thm_gfx', U32),
        ('throttle_residency_thm_soc', U32), ('time_filter_alphavalue', U32)]

def read(path, default=None):
    try: return Path(path).read_text().strip()
    except (OSError, ValueError): return default

def number(path, scale=1):
    try: return float(read(path)) / scale
    except (TypeError, ValueError): return None

def run(args):
    try:
        p = subprocess.run(args, capture_output=True, text=True, timeout=2,
                           env={**os.environ, 'LC_ALL':'C.UTF-8', 'QT_LOGGING_RULES':'*.debug=false'})
        return p.stdout.strip() if p.returncode == 0 else None
    except (OSError, subprocess.TimeoutExpired): return None

def metrics(path):
    try:
        b = Path(path).read_bytes()
        if len(b) < C.sizeof(MetricsV3) or b[2:4] != bytes([3, 0]): return {}
        m = MetricsV3.from_buffer_copy(b)
        if m.size != len(b): return {}
        out = {}
        for name, typ in m._fields_:
            v = getattr(m, name)
            invalid = 0xffffffff if typ == U32 else 0xffff
            out[name] = [None if x == 65535 else x for x in v] if isinstance(v, C.Array) else (None if v == invalid else v)
        return out
    except (OSError, ValueError): return {}

def percent_delta(new, old):
    if not old or len(new) != len(old): return None
    delta = sum(new)-sum(old)
    if delta <= 0: return None
    idle = new[3]-old[3] + new[4]-old[4]
    return round(max(0, min(100, 100*(1-idle/delta))), 1)

def battery_data(p, ac, prev, now):
    status = read(p/'status', 'Unknown')
    power = number(p/'power_now', 1e6)
    voltage = number(p/'voltage_now', 1e6)
    if power is None:
        current = number(p/'current_now', 1e6)
        if current is not None and voltage is not None: power = abs(current*voltage)
    energy, full, design = [number(p/n, 1e6) for n in ('energy_now','energy_full','energy_full_design')]
    last = prev.get('battery_filter', {})
    avg = power
    if power is not None and last.get('status') == status and now-last.get('time', 0) < 30 and last.get('watts') is not None:
        alpha = 1 - pow(2.718281828, -max(0, now-last['time'])/30)
        avg = last['watts']*(1-alpha)+power*alpha
    seconds = None
    if avg is not None and avg > .1 and energy is not None:
        if status == 'Discharging': seconds = energy/avg*3600
        elif status == 'Charging' and full is not None: seconds = max(0, full-energy)/avg*3600
    b = dict(present=True, status=status, percent=number(p/'capacity'), watts=power,
             smoothed_watts=avg, voltage=voltage, energy=energy, full=full, design=design,
             health=full/design*100 if full is not None and design else None,
             cycles=number(p/'cycle_count'), limit=number(p/'charge_control_end_threshold'),
             seconds=seconds, ac=ac)
    return b, dict(status=status, watts=avg, time=now)

def parse_displays(config):
    """Offer only advertised refresh rates at each connected output's current size."""
    displays = []
    for output in config.get('outputs', []):
        if not output.get('enabled') or not output.get('connected'):
            continue
        current_id = str(output.get('currentModeId', ''))
        current = next((m for m in output.get('modes', []) if str(m['id']) == current_id), {})
        size = current.get('size', {})
        rates = {}
        for mode in output.get('modes', []):
            hz = mode.get('refreshRate')
            if not size or mode.get('size') != size or not isinstance(hz, (int, float)) or hz <= 0:
                continue
            key = round(hz, 3)
            choice = dict(id=str(mode['id']), hz=hz, active=str(mode['id']) == current_id)
            if key not in rates or choice['active']:
                rates[key] = choice
        displays.append(dict(id=str(output['id']), name=output.get('name'),
            mode_id=current_id, hz=current.get('refreshRate'),
            width=size.get('width'), height=size.get('height'), scale=output.get('scale'),
            refresh_modes=[rates[k] for k in sorted(rates)],
            vrr={0:'Never', 1:'Always', 2:'Automatic'}.get(output.get('vrrPolicy'), 'Unknown')))
    return displays

def display_mode_command(config, output_id, mode_id):
    """Revalidate against fresh KScreen state, including hotplug/resolution changes."""
    if not all(re.fullmatch(r'[A-Za-z0-9_-]+', str(v)) for v in (output_id, mode_id)):
        raise ValueError('Invalid display or mode identifier')
    output = next((o for o in parse_displays(config) if o['id'] == str(output_id)), None)
    if output is None:
        raise ValueError('Display disconnected or disabled. Refresh the widget and try again.')
    if not any(m['id'] == str(mode_id) for m in output['refresh_modes']):
        raise ValueError('Refresh mode is no longer available at this resolution. Refresh and try again.')
    return ['kscreen-doctor', f'output.{output_id}.mode.{mode_id}']

def slow_data():
    displays = []
    try:
        displays = parse_displays(json.loads(run(['kscreen-doctor','-j']) or '{}'))
    except (ValueError, TypeError, KeyError): pass
    return dict(displays=displays, profile=run(['powerprofilesctl','get']),
                profile_details=run(['powerprofilesctl','list']))

def charger_data(ac):
    mode = number('/sys/class/firmware-attributes/asus-armoury/attributes/charge_mode/current_value')
    if mode is None: mode = number('/sys/devices/platform/asus-nb-wmi/charge_mode')
    ports=[]
    for p in Path('/sys/class/power_supply').glob('*'):
        if read(p/'type') not in ('USB','USB_C') or (number(p/'online') or 0) <= 0: continue
        # UCSI's *_now are the selected PDO voltage and RDO operating current,
        # not measured consumption. *_max can refer to different advertised PDOs.
        volts = number(p/'voltage_now',1e6) if p.name.startswith('ucsi-') else None
        amps = number(p/'current_now',1e6) if p.name.startswith('ucsi-') else None
        ports.append(dict(name=p.name, volts=volts, amps=amps,
                          limit_watts=volts*amps if volts and amps else None))
    kind = 'battery' if ac is False else 'barrel' if ac and mode in (1,3) else 'usb' if ac and (mode==2 or ports) else 'ac' if ac else 'unknown'
    # Charger nameplate ratings are user configuration, not sensor measurements.
    try:
        settings=json.loads((Path(os.environ.get('XDG_CONFIG_HOME',str(Path.home()/'.config')))/'power-observatory/settings.json').read_text())
        rating=settings.get(kind+'_rated_watts')
        if not isinstance(rating,(int,float)) or isinstance(rating,bool) or not 0 < rating < 1000: rating=None
    except (OSError, ValueError, AttributeError): rating=None
    label={'battery':'Battery only','barrel':'ASUS adapter',
           'usb':'USB-C','ac':'AC adapter','unknown':'Power source unknown'}[kind]
    if rating: label += f' · {rating:g} W rated'
    return dict(kind=kind, mode=mode, ports=ports, label=label, rated_watts=rating,
        recommended={'battery':'power-saver','usb':'balanced','barrel':'performance'}.get(kind,'balanced'))

def compute_counters():
    counters = {}
    for proc in Path('/proc').glob('[0-9]*'):
        try:
            if proc.stat().st_uid != os.getuid(): continue
            for fd in (proc/'fd').iterdir():
                try:
                    if not os.readlink(fd).startswith('/dev/dri/'): continue
                    data = read(proc/'fdinfo'/fd.name, '')
                    fields = dict(line.split(':',1) for line in data.splitlines() if ':' in line)
                    if fields.get('drm-driver','').strip() != 'amdgpu': continue
                    key = fields.get('drm-pdev','').strip()+':'+fields['drm-client-id'].strip()
                    if 'drm-engine-compute' in fields:
                        counters[key] = int(fields['drm-engine-compute'].split()[0])
                except (OSError, KeyError, ValueError): continue
        except OSError: continue
    return counters

def collect(previous=None, with_slow=True):
    prev = previous or {}; now = time.monotonic()
    state = dict(time=now)
    cpu_ticks = {}
    for line in (read('/proc/stat','')).splitlines():
        parts=line.split()
        if parts and re.fullmatch(r'cpu\d*',parts[0]): cpu_ticks[parts[0]]=list(map(int,parts[1:9]))
    state['cpu_ticks']=cpu_ticks
    usages={k:percent_delta(v,prev.get('cpu_ticks',{}).get(k)) for k,v in cpu_ticks.items()}
    mem={}
    for line in (read('/proc/meminfo','')).splitlines():
        k,v=line.split(':',1); mem[k]=int(v.split()[0])*1024
    total=mem.get('MemTotal',0); used=total-mem.get('MemAvailable',0)
    ram=dict(total=total, used=used, available=mem.get('MemAvailable'), percent=used/total*100 if total else None,
        swap_total=mem.get('SwapTotal'), swap_used=mem.get('SwapTotal',0)-mem.get('SwapFree',0), cached=mem.get('Cached'))
    sensors=[]; fans=[]; cpu_temp=None; apu_watts=None
    for h in sorted(Path('/sys/class/hwmon').glob('*')):
        name=read(h/'name','unknown')
        for f in sorted(h.glob('temp*_input')):
            value=number(f,1000)
            if value is None: continue
            label=read(h/(f.name.replace('_input','_label')), f.stem.replace('_input',''))
            sensors.append(dict(name=name+' · '+label, value=value, unit='°C', path=str(f)))
            if name=='k10temp' and label=='Tctl': cpu_temp=value
        for f in sorted(h.glob('fan*_input')):
            value=number(f)
            if value is not None: fans.append(dict(name=read(h/(f.name.replace('_input','_label')),name),value=value,unit='RPM',path=str(f)))
        if name=='amdgpu': apu_watts=number(h/'power1_average',1e6)
    gpu_path=next((p for p in Path('/sys/class/drm').glob('card[0-9]*/device') if read(p/'vendor')=='0x1002'),None)
    gpu={}; m={}
    counters = compute_counters(); state['compute_counters'] = counters
    old_counters = prev.get('compute_counters', {})
    common = counters.keys() & old_counters.keys()
    elapsed = now-prev.get('time',now)
    compute = (sum(max(0,counters[k]-old_counters[k]) for k in common)/elapsed/1e7
               if common and 0 < elapsed < 30 else None)
    if gpu_path:
        m=metrics(gpu_path/'gpu_metrics')
        def mv(name,scale=1):
            v=m.get(name); return v/scale if v is not None else None
        gpu=dict(busy=number(gpu_path/'gpu_busy_percent'), vram_used=number(gpu_path/'mem_info_vram_used'),
            vram_total=number(gpu_path/'mem_info_vram_total'), gtt_used=number(gpu_path/'mem_info_gtt_used'),
            gtt_total=number(gpu_path/'mem_info_gtt_total'), clock=mv('average_gfxclk_frequency'),
            mem_clock=mv('average_uclk_frequency'), watts=mv('average_gfx_power',1000),
            media=mv('average_vcn_activity'), temp=mv('temperature_gfx',100),
            policy=read(gpu_path/'power_dpm_force_performance_level'), compute=compute)
        if mv('average_apu_power',1000) is not None: apu_watts=mv('average_apu_power',1000)
    npu_path=next(Path('/sys/class/accel').glob('accel*/device'),None)
    npu=dict(present=bool(npu_path), name=read(npu_path/'vbnv') if npu_path else None,
             state=read(npu_path/'power/runtime_status') if npu_path else None,
             columns=m.get('average_ipu_activity',[]), watts=m.get('average_ipu_power'), clock=m.get('average_ipuclk_frequency'),
             reads=m.get('average_ipu_reads'), writes=m.get('average_ipu_writes'))
    if npu['watts'] is not None: npu['watts']/=1000
    # Per-column firmware activity, never label runtime power state as utilization.
    valid=[v for v in npu['columns'] if v is not None and 0<=v<=100]
    npu['busy']=sum(valid)/len(valid) if valid else None
    battery_path=next((p for p in Path('/sys/class/power_supply').glob('*') if read(p/'type')=='Battery' and read(p/'scope')!='Device' and p.name.startswith('BAT')),None)
    online=[number(p/'online') for p in Path('/sys/class/power_supply').glob('*') if read(p/'type') in ('Mains','USB','USB_C')]
    ac=any(v is not None and v>0 for v in online) if any(v is not None for v in online) else None
    battery=dict(present=False,ac=ac)
    if battery_path: battery,state['battery_filter']=battery_data(battery_path,ac,prev,now)
    slow=prev.get('slow',{})
    if with_slow and (not slow or now-prev.get('slow_time',0)>10 or ac != prev.get('ac')):
        slow=slow_data(); state['slow_time']=now
    else: state['slow_time']=prev.get('slow_time',0)
    state['slow']=slow
    state['ac']=ac
    policies=list(Path('/sys/devices/system/cpu/cpufreq').glob('policy*'))
    first=policies[0] if policies else Path('/nonexistent')
    clocks=[number(p/'scaling_cur_freq',1e6) for p in policies]; clocks=[v for v in clocks if v is not None]
    model=next((line.split(':',1)[1].strip() for line in read('/proc/cpuinfo','').splitlines() if line.startswith('model name')), 'CPU')
    cpu=dict(name=model, busy=usages.get('cpu'), cores=[usages[k] for k in sorted(usages,key=lambda k:int(k[3:] or -1)) if k!='cpu'],
        temp=cpu_temp, ghz=sum(clocks)/len(clocks) if clocks else None,
        watts=(m['average_all_core_power']/1000) if m.get('average_all_core_power') is not None else None,
        governor=read(first/'scaling_governor'), epp=read(first/'energy_performance_preference'),
        driver=read(first/'scaling_driver'), min_ghz=number(first/'scaling_min_freq',1e6),
        max_ghz=number(first/'scaling_max_freq',1e6), boost=read('/sys/devices/system/cpu/cpufreq/boost'),
        load=read('/proc/loadavg','').split()[:3])
    backlight=next(Path('/sys/class/backlight').glob('*'),None); brightness=None
    if backlight:
        actual,maximum=number(backlight/'actual_brightness'),number(backlight/'max_brightness')
        if actual is not None and maximum: brightness=100*actual/maximum
    # Values exported by ASUS firmware are raw controls; not necessarily enforced watts.
    asus={p.name:number(p) for p in Path('/sys/devices/platform/asus-nb-wmi').glob('ppt_*')}
    limits={k:(m[k]/1000 if m.get(k) is not None else None) for k in ('stapm_power_limit','current_stapm_power_limit')}
    out=dict(timestamp=time.time(), cpu=cpu, ram=ram, gpu=gpu, npu=npu, battery=battery,
        apu_watts=apu_watts, sensors=sensors, fans=fans, charger=charger_data(ac), profile=slow.get('profile'),
        profile_details=slow.get('profile_details'), platform_profile=read('/sys/firmware/acpi/platform_profile'),
        displays=slow.get('displays',[]), brightness=brightness, limits=limits, asus_controls=asus,
        dram_reads=m.get('average_dram_reads'), dram_writes=m.get('average_dram_writes'),
        uptime=float(read('/proc/uptime','0 0').split()[0]))
    return out,state

def main():
    runtime=Path(os.environ.get('XDG_RUNTIME_DIR',f'/tmp/power-observatory-{os.getuid()}'))/'power-observatory'
    runtime.mkdir(mode=0o700,parents=True,exist_ok=True)
    cache=runtime/'state.json'
    try: previous=json.loads(cache.read_text())
    except (OSError,ValueError): previous={}
    if len(sys.argv)>1:
        # Strict allowlists; subprocess argument arrays, never a shell.
        try:
            if len(sys.argv)==3 and sys.argv[1]=='--profile' and sys.argv[2] in ('power-saver','balanced','performance'):
                p=subprocess.run(['powerprofilesctl','set',sys.argv[2]],capture_output=True,text=True,timeout=8)
            elif len(sys.argv)==4 and sys.argv[1]=='--display-mode':
                config=json.loads(run(['kscreen-doctor','-j']) or '{}')
                command=display_mode_command(config,sys.argv[2],sys.argv[3])
                p=subprocess.run(command,capture_output=True,text=True,timeout=8)
            else: raise ValueError('Unsupported control request')
            if p.returncode: raise ValueError(p.stderr.strip() or 'The desktop rejected this change')
            previous['slow_time']=0
            out,state=collect(previous)
            if sys.argv[1]=='--display-mode':
                actual=next((o for o in out['displays'] if o['id']==sys.argv[2]),{})
                if actual.get('mode_id') != sys.argv[3]:
                    raise ValueError('KScreen did not confirm the requested mode. Check Display Settings.')
            temp=runtime/f'state-{os.getpid()}.tmp'; temp.write_text(json.dumps(state)); temp.replace(cache)
            print(json.dumps({'ok':True,'telemetry':out})); return
        except (OSError,ValueError,StopIteration,subprocess.TimeoutExpired) as e:
            print(json.dumps({'ok':False,'error':str(e) or 'Requested display mode is unavailable'})); return
    out,state=collect(previous)
    temp=runtime/f'state-{os.getpid()}.tmp'; temp.write_text(json.dumps(state)); temp.replace(cache)
    print(json.dumps(out,allow_nan=False,separators=(',',':')))

if __name__=='__main__': main()
