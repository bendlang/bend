#!/usr/bin/env python3
"""Split the original-ten transfer config; freeze a longer outer launcher only."""
from pathlib import Path
import hashlib, json, sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
acquisition, out = (Path(x).resolve() for x in sys.argv[1:])
source_config = acquisition / 'timing-config.json'
original = json.loads(source_config.read_text())
receipt = json.loads((acquisition / 'report.json').read_text())
assert receipt['complete'] and len(receipt['cases']) == 10
assert original['protocol'] == 'transfer' and len(original['cases']) == 10
assert all(x['complete'] for x in receipt['cases'])
assert len({x['id'] for x in original['cases']}) == 10
out.mkdir(parents=True, exist_ok=False)

def identity(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
            'bytes': p.stat().st_size}

def save(p, value):
    p.write_text(json.dumps(value, indent=2) + '\n')

for entry in original['inputs']:
    assert identity(entry['file']) == entry, entry['file']
parent = HERE / 'prototype-time.py'
text = parent.read_text()
changes = [
    ('HERE=Path(__file__).resolve().parent', 'HERE=Path(' + repr(str(HERE)) + ')'),
    ('timeout=600', 'timeout=1200'),
]
for before, after in changes:
    assert text.count(before) == 1
    text = text.replace(before, after)
launcher = out / 'time-original.py'
launcher.write_text(text)
(out / 'original-launcher.py').write_bytes(parent.read_bytes())
derivation = {'kind': 'phase30-original-transfer-outer-budget', 'complete': True,
    'parent': identity(parent), 'derived': identity(launcher),
    'changes': [{'before': a, 'after': b, 'count': 1} for a, b in changes],
    'scope': 'Only bound original tool root and prospective1200s outer timeout. Maintained compare/execute, per-child120s and full transfer protocol unchanged.'}
save(out / 'launcher-derivation.json', derivation)
inputs = [identity(x) for x in [Path(__file__), source_config, acquisition / 'report.json',
    launcher, out / 'launcher-derivation.json', ROOT / 'design/phase30/final-integration.md']]
commands = []
for case in original['cases']:
    assert set(case['modules']) == {'typescript', 'phase29', 'candidate'}
    config = out / (case['id'] + '.json')
    save(config, {'protocol': 'transfer', 'inputs': [*original['inputs'], *inputs], 'cases': [case]})
    commands.append({'case': case['id'], 'command': [sys.executable, str(launcher),
        str(config), str(out / (case['id'] + '-timing'))], 'config': identity(config),
        'outerTimeoutSeconds': 1200, 'executed': False})
save(out / 'plan.json', {'kind': 'phase30-final-original-ten-measurement-plan',
    'complete': True, 'executed': False, 'inputs': inputs, 'commands': commands,
    'scope': 'All ten original points. Same-window pinned TypeScript/Phase29/candidate, unchanged five-sample transfer protocol on CPU3. Separate exclusive timing grant required.'})
(out / 'consumed-plan.py').write_bytes(Path(__file__).read_bytes())
print(json.dumps({'complete': True, 'executed': False, 'cases': len(commands), 'out': str(out)}))
