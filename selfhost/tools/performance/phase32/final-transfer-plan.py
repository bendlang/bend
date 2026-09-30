#!/usr/bin/env python3
"""Freeze each original selected program's maintained transfer protocol."""
from pathlib import Path
import hashlib
import json
import shutil
import sys

ROOT = Path(__file__).resolve().parents[4]
acquisition, out = (Path(x).resolve() for x in sys.argv[1:])
receipt = json.loads((acquisition / 'report.json').read_text())
config = json.loads((acquisition / 'timing-config.json').read_text())
assert receipt['complete'] and all(c['complete'] for c in receipt['cases'])
assert config['protocol'] == 'transfer'
expected = {'mandelbrot': ([2, 0], 887240761, 'bench'),
            'editdist': ([2, 0], 2065873279, 'bench'),
            'test-rle-roundtrip': ([], 11, 'main.out')}
assert [c['id'] for c in config['cases']] == list(expected)
out.mkdir(parents=True, exist_ok=False)


def ident(file):
    p = Path(file).resolve()
    raw = p.read_bytes()
    return dict(file=str(p), sha256=hashlib.sha256(raw).hexdigest(), bytes=len(raw))


inputs = [ident(p) for p in [Path(__file__), acquisition / 'report.json',
          acquisition / 'timing-config.json', ROOT / 'design/phase32/final-integration.md']]
for entry in config['inputs']:
    assert ident(entry['file']) == entry
inputs.extend(config['inputs'])
commands = []
for case in config['cases']:
    args, value, export = expected[case['id']]
    assert case['point'] == dict(args=args, expected=value, exportName=export)
    assert list(case['modules']) == ['typescript', 'baseline07', 'candidate']
    for file in case['modules'].values():
        inputs.append(ident(file))
    target = out / (case['id'] + '.json')
    target.write_text(json.dumps(dict(protocol='transfer', inputs=inputs, cases=[case]), indent=2) + '\n')
    commands.append(dict(case=case['id'], config=ident(target), cpu=3,
         outerTimeoutSeconds=600, executed=False,
         command=[sys.executable, str(ROOT / 'selfhost/tools/performance/phase30/prototype-time.py'),
                  str(target), str(out / (case['id'] + '-timing'))]))
(out / 'plan.json').write_text(json.dumps(dict(kind='phase32-final-original-three-timing-plan',
     complete=True, executed=False, inputs=inputs, commands=commands,
     scope='Same-window TypeScript/07/final; unchanged original inputs and maintained five-sample transfer. Root exclusive CPU3 grant required.'), indent=2) + '\n')
shutil.copyfile(Path(__file__), out / 'consumed-plan.py')
print(json.dumps(dict(complete=True, executed=False, cases=len(commands), out=str(out))))
