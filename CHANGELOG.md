# Changelog

## 1.3.1

- Discover per-fan references and supported AMD sustained power limits on each poll.
- Color fan speed relative to its own reference; remove the hardcoded 6000 RPM range.
- Label driver, configured, estimated and unavailable references; preserve historical classifications.
- Validate limits and provide per-sensor overrides with hardware-independent regression checks.


## 1.3.0 — 2026-09-12

- Standardize resource cards on horizontal current meters plus unobscured trends.
- Preserve historical zone colors, including interpolated threshold crossings, on timestamped two-minute charts with fixed scales.
- Leave gaps for missing/stale samples and changed measurement bases; never stretch partial history across the full window.
- Add hover/focus/tap/keyboard information controls and clarify GPU compute measurement scope.
- Prioritize RAM/VRAM in Overview and apply the same visual language to cooling and power.

## 1.2.0 — 2026-09-12

- Add matching RAM/VRAM capacity bars, percentages, threshold markers and pressure labels.
- Add APU/CPU/GPU/NPU/battery-discharge gauges with configurable, explicitly labeled watt reference bands.
- Distinguish high consumption/utilization from hardware danger. Thermal Danger requires a driver-reported critical threshold.
- Preserve missing/stale/zero readings and numeric values beyond the gauge scale.
- Test threshold boundaries, invalid configuration, saturated memory, missing limits and stale visual states.

## 1.1.0 — 2026-09-12

First public release.

- Discover refresh modes per active display, retaining current resolution and fractional rates.
- Expose refresh buttons in Overview and Power, highlight the active mode, and verify changes.
- Reject disconnected outputs, stale resolutions, unsupported modes and invalid identifiers before control commands.
- Keep charger nameplate ratings in optional local configuration; remove fixed hardware names from the UI.
- Add contributor/agent instructions, interface documentation, synthetic fixtures, regression/QML checks and CI package builds.

## 1.0.0 — 2026-09-12

Initial local widget with power/battery, CPU/GPU/NPU, memory, fans and temperature telemetry; power profiles and fixed internal 60/180 Hz controls.
