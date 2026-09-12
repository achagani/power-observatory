# Development instructions for coding agents

## Scope and architecture

Power Observatory is a native Plasma 6 widget, not a website. Keep the runtime dependency-free beyond Python 3, Plasma, powerprofilesctl and KScreen. Read `README.md`, `CONTRIBUTING.md` and `docs/architecture.md` before changing behavior.

- `package/contents/code/telemetry.py`: read-only collection, normalization, bounded control commands.
- `package/contents/ui/main.qml`: Plasma lifecycle, executable data source, polling/control serialization.
- `package/contents/ui/Dashboard.qml`: portable dashboard; emit control requests instead of executing them.
- `package/contents/ui/DisplayControl.qml`: discovered per-output refresh modes.
- `MetricTile.qml`, `TrendChart.qml`, `InfoButton.qml`: shared presentation and accessible explanations.
- `History.js`, `Metrics.js`: timestamped history, immutable historical policies and metric definitions.
- `docs/design-language.md`: mandatory visual conventions for UI changes.
- `test_telemetry.py`, `tests/`: mocked hardware tests and QML checks.
- `scripts/build.py`: deterministic distributable archive.

## Working agreement

1. Inspect the current implementation and relevant tests. Make the smallest coherent change.
2. Use local fixtures for development; do not query or modify a contributor's hardware just to run tests.
3. Add a regression test for behavior changes, especially units, sensor absence, hotplug and command validation.
4. Run `python3 -m unittest discover -v`, `python3 tests/test_qml.py` (requires PySide6), and `python3 scripts/build.py`.
5. Render changed UI with `python3 preview.py tests/fixtures/demo.json`; check narrow and normal widths, long labels, missing data and scrolling.
6. Summarize behavior, validation and remaining limits in the PR. Use `.github/pull_request_template.md`.

## Invariants

- Missing/unsupported is `null`/a dash, never a fabricated zero. Preserve valid zero readings.
- APU/chip power, battery flow, USB-C contract and wall draw are different quantities.
- Do not add advertised maximum voltage and current assumptions: UCSI *_now encodes the selected contract, not measured consumption.
- Firmware power state is not utilization. GPU reserved UMA and Linux RAM must not be double-counted.
- Only parse explicitly supported AMD ABI revisions, sizes and units; preserve sentinel handling.
- Display changes must target an enabled, connected output and an advertised mode at its current resolution, validated against a fresh KScreen query. Preserve fractional Hz; do not invent modelines.
- Controls require an explicit user action. Do not add automatic profile changes or privileged sysfs writes without a requested design change.
- Use subprocess argument lists with timeouts and strict validation; never interpolate user-controlled commands into a shell.
- Do not commit live samples, host paths, credentials, desktop screenshots, runtime caches or generated archives. Use synthetic fixtures and widget-only documentation images.
- Do not publish releases, push branches, install/reload the desktop widget or change real power/display settings unless the task authorizes that action. Ordinary local tests do not need confirmation.

## Platform and contribution discipline

AMD/ASUS is the tested hardware path, not a universal claim. Extend other vendors behind capability detection and fixture tests. Avoid mixing large formatting-only changes with features. Add dependencies only with a concrete rationale. Keep runtime overhead low: 2-second sensor reads and 10-second display/profile queries by default, no persistent daemon.

Independent subtasks may be delegated when the user requests parallel agent work. Otherwise work sequentially; do not have agents edit the same files concurrently.
