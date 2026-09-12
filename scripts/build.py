#!/usr/bin/env python3
"""Build a repeatable Plasma package without caches or machine-local artifacts."""
from pathlib import Path
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]

def build():
    package = ROOT / 'package'
    metadata = json.loads((package / 'metadata.json').read_text())
    assert metadata['KPlugin']['Id'] == 'local.power.observatory'
    target = ROOT / 'dist' / 'Power-Observatory.plasmoid'
    target.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
        entries = [(p, p.relative_to(package).as_posix()) for p in package.rglob('*')
                   if p.is_file() and '__pycache__' not in p.parts and p.suffix != '.pyc']
        entries.append((ROOT / 'LICENSE', 'LICENSE'))
        for path, name in sorted(entries, key=lambda item: item[1]):
            info = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes())
    print(target)
    return target

if __name__ == '__main__':
    build()
