#!/usr/bin/env python3
"""Compare exact emitted program suffixes after verified frozen runtime prefixes."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('out', type=Path)
args = parser.parse_args()
inputs = []


def read(path, expected=None):
    path = Path(path).resolve()
    data = path.read_bytes()
    item = dict(file=str(path), bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
    if expected:
        assert item['sha256'] == expected['sha256'], path
    inputs.append(item)
    return data, item


runtimes = {}
for role, name in [('baseline', 'phase35/checked09'), ('candidate', 'phase36/checked03')]:
    raw, _ = read(ROOT/'selfhost/build'/name/'attempt.json')
    attempt = json.loads(raw)
    runtimes[role], _ = read(attempt['runtime']['file'], attempt['runtime'])
raw, timing = read(ROOT/'selfhost/build/phase36/full-confirm03/report.json')
run = json.loads(raw)
assert run['complete'] and run['pass'] and run['measuredCases'] == 15
rows = []
for case in run['cases']:
    suffixes, modules = {}, {}
    for role in ['baseline', 'candidate']:
        selected = next(row for row in case['samples'] if row['role'] == role)
        ref = selected['result']['module']
        module, modules[role] = read(ref.get('file', ref.get('path')), ref)
        assert module.startswith(runtimes[role]), (case['id'], role)
        suffixes[role] = module[len(runtimes[role]):]
    rows.append(dict(id=case['id'], programSuffixEqual=suffixes['baseline'] == suffixes['candidate'],
                     suffixes={role: dict(bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
                               for role, data in suffixes.items()}, modules=modules))
read(__file__)
result = dict(kind='phase36-frozen-runtime-prefix-comparison', complete=True, timing=timing,
              scope='Byte comparison of complete emitted suffixes, not an AST or dynamic cost claim. Runtime prefixes are verified against each frozen attempt.',
              rows=rows, inputs=inputs)
with args.out.open('x') as stream:
    json.dump(result, stream, indent=2)
    stream.write('\n')
print(json.dumps(dict(complete=True, identicalProgramSuffixes=sum(row['programSuffixEqual'] for row in rows),
                     changed=[row['id'] for row in rows if not row['programSuffixEqual']])))
