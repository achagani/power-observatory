# Contributing

Bug reports, new sensor backends, accessibility improvements and translations are welcome. Start with an issue for substantial architecture or dependency changes. Small fixes can go directly to a pull request.

## Local setup

```bash
git clone https://github.com/achagani/power-observatory.git
cd power-observatory
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements-dev.txt
python -m unittest discover -v
python tests/test_qml.py
python preview.py tests/fixtures/demo.json
python scripts/build.py
```

Python 3.10+ is supported. PySide6 is only required for development rendering and QML checks, not for the installed widget. Offscreen checks do not require Plasma or change power/display settings. `AGENTS.md` gives the same development contract to AI coding agents.

## Test the real widget

On a Plasma 6 session with `powerprofilesctl` and `kscreen-doctor` installed:

```bash
kpackagetool6 --type Plasma/Applet --install dist/Power-Observatory.plasmoid
# If already installed, use --upgrade instead of --install.
plasmawindowed local.power.observatory
```

Add **Power Observatory** through the desktop's Add Widgets menu. A fresh `plasmawindowed` process avoids QML caching during development. Re-adding a widget or logging out/in may be necessary to load new code on an existing desktop. Do not restart another person's Plasma shell without task authorization.

## A useful pull request

- Describe the concrete trigger and resulting behavior.
- Include fixture-based tests and document the hardware/driver assumptions.
- For a UI change, attach widget-only screenshots at 480 and 640 px width; redact identifying information.
- For new hardware, describe units, kernel paths/API revisions and missing-sensor behavior.
- Run all local checks above. CI builds an installable artifact and performs Python/QML checks.

Never attach unreviewed `/proc`, environment, full desktop or personal runtime dumps. Minimize sensor samples to the fields needed to reproduce the problem. Contributions are licensed under MIT.
