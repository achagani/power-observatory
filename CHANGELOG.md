# Changelog

## 1.1.0 — 2026-09-12

First public release.

- Discover refresh modes per active display, retaining current resolution and fractional rates.
- Expose refresh buttons in Overview and Power, highlight the active mode, and verify changes.
- Reject disconnected outputs, stale resolutions, unsupported modes and invalid identifiers before control commands.
- Keep charger nameplate ratings in optional local configuration; remove fixed hardware names from the UI.
- Add contributor/agent instructions, interface documentation, synthetic fixtures, regression/QML checks and CI package builds.

## 1.0.0 — 2026-09-12

Initial local widget with power/battery, CPU/GPU/NPU, memory, fans and temperature telemetry; power profiles and fixed internal 60/180 Hz controls.
