# Architecture and measurement contract

`main.qml` starts one short-lived Python collector every two seconds through Plasma5Support's executable data engine. Polling and button-triggered controls are serialized within the widget. JSON feeds `Dashboard.qml`; the dashboard itself has no side effects, making offscreen testing possible.

The collector reads `/proc` and `/sys` without root. Its per-session cache under `$XDG_RUNTIME_DIR/power-observatory` stores CPU/compute baselines, battery smoothing and slower KScreen/profile snapshots. Display/profile queries run every ten seconds and are invalidated after a successful control or AC-presence change. No network access, system service or telemetry upload is used by the widget.

## Displays

KScreen JSON is normalized into one record per enabled, connected output: ID, connector name, current mode, resolution, scale, VRR policy and sorted `refresh_modes`. Modes are filtered to the current resolution. Rates are deduplicated to millihertz; the active mode wins ties. Fractional rates remain numeric rather than being rounded to an integer for mode selection.

Buttons send output and mode IDs through a strict character allowlist. The helper queries KScreen again, rejects unavailable outputs/modes or resolution-changing choices, then invokes `kscreen-doctor output.ID.mode.MODE`. It reads back the selected mode before reporting success. There are no synthetic modelines, automatic charger-based refresh changes, or display-disabling commands. A disconnected monitor produces an actionable error rather than selecting another display.

## Measurements

- CPU load: deltas of `/proc/stat`, excluding idle and I/O wait. The first sample needs a baseline.
- RAM: `MemTotal - MemAvailable`; swap and cache are separate. GPU reserved UMA is excluded from Linux RAM. GTT is an allocation from system RAM, not extra capacity.
- Battery flow: micro-units converted to watts/volts/watt-hours. Remaining time uses a 30-second exponential power average, reset on status changes. Zero/unknown flow has no estimate. AC plus discharging means the battery supplements the adapter.
- Charger mode: ASUS charge-mode ABI when available; online power supplies are the fallback. Nameplate watt ratings are optional local configuration. UCSI selected voltage × operating current describes a contract, never wall draw.
- AMD metrics: only the validated v3.0 binary table is decoded. Unknown revisions use generic available sensors. Sentinel values become null; valid zeros remain zero.
- GPU compute: deduplicated amdgpu client compute-time deltas for readable processes owned by the session user. Concurrent engines can exceed 100%; inaccessible clients are excluded.
- NPU: firmware IPU column activity, domain power, clocks and traffic. Runtime `suspended` is a power state, not a utilization measurement.
- Fans: ASUS and ACPI tachometers are displayed independently; ACPI can mirror a physical fan. Temperatures retain kernel source paths as tooltips.

## Limits and extension points

Hardware testing currently covers Ryzen AI MAX+ 395 / Radeon 8060S on an ASUS Flow Z13, Fedora KDE/Wayland. Other hardware is best-effort, with unsupported readings shown as unavailable. Intel/NVIDIA GPU telemetry needs a separate future backend. Battery selection currently uses the first system `BAT*` battery. Multiple simultaneous widget instances share baseline cache and should be avoided until per-instance sampling is implemented. The widget does not measure wall power or instantaneous VRR.

Add new backends behind capability detection with synthetic fixtures and explicit source/units. Keep the JSON schema additive when possible. A daemon or D-Bus-native backend may be considered if benchmarks demonstrate the need.

## Authoritative interfaces

- [KDE Plasma 6 porting API](https://develop.kde.org/docs/plasma/widget/porting_kf6/)
- [KScreen doctor implementation](https://github.com/KDE/libkscreen/blob/master/src/doctor/doctor.cpp)
- [AMD metrics ABI](https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/amd/include/kgd_pp_interface.h)
- [ASUS charge mode](https://github.com/torvalds/linux/blob/master/Documentation/ABI/testing/sysfs-platform-asus-wmi)
- [UCSI power contract](https://github.com/torvalds/linux/blob/master/drivers/usb/typec/ucsi/psy.c)

## Visual classification

`Zones.js` is the shared pure classification layer. Memory ratio thresholds are 60/85/95%; utilization thresholds are 40/80/95%. `MemoryGauge.qml` clamps only its painted fill, not the reported percentage or values. Missing totals and stale samples show unclassified states.

`PowerGauge.qml` and `ArcGauge.qml` display validated `power_bands` from the collector. These configurable reference bands classify consumption, not physical safety, firmware throttling or adapter headroom. They do not use charger nameplate wattage as a measured denominator. Numeric values remain visible when the pointer saturates.

`ThermalReading.qml` applies the same sensor's sanitized high/critical limits. Zero, common large sentinel values and inverted high limits are rejected. Critical is the only condition called Danger; missing limits remain unknown. See the [kernel hwmon ABI](https://docs.kernel.org/hwmon/sysfs-interface.html). No control behavior changes with a zone transition.
