#!/usr/bin/env python3
"""Freeze uninstrumented private-Let timings only after complete controls."""
from pathlib import Path
import hashlib
import json
import shutil
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
whole, helper, controls, out = (Path(x).resolve() for x in sys.argv[1:])


def identity(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}


def save(p, value):
    p.write_text(json.dumps(value, indent=2) + '\n')


control = json.loads((controls / 'report.json').read_text())
assert control['complete'] and control['pass']
assert all(row['complete'] for row in control['steps'])
inputs = [identity(p) for p in [Path(__file__), ROOT / 'design/phase30/private-let-statements.md',
                               HERE.parent / 'phase29/compare.py', HERE / 'prototype-time.py', controls / 'report.json']]
for row in control['inputs']:
    assert identity(row['file']) == row
    inputs.append(row)
for step in control['steps']:
    assert identity(step['result']['file']) == step['result']
    inputs.append(step['result'])
reports = {}
for name, directory in [('whole', whole), ('helper', helper)]:
    report = json.loads((directory / 'derive.json').read_text())
    assert report['complete'] and report['reconstructedOriginal']
    for row in report['inputs']:
        assert identity(row['file']) == row
    for row in report['outputs'].values():
        assert identity(row['file']) == row
        inputs.append(row)
    inputs.append(identity(directory / 'derive.json'))
    reports[name] = report
assert reports['whole']['helpersChanged'] > 0
oracle = json.loads((controls / 'whole-oracle/report.json').read_text())
assert oracle['complete'] and oracle['pass']
expected = next(row['expected'] for row in oracle['oracle'] if row.get('depth') == 5
                and row['index'] == 0 and row['total'] == {'$bigint': '7'}
                and row['colors'] == [1, 3, 7, 17, 31, 63, 127, 255])
out.mkdir(parents=True, exist_ok=False)
marker = 'export default Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));'
wrapper = '''const $let30Exports=Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));
export default {...$let30Exports,treeBench:(depth,index)=>$let30Exports.rcol(BigInt(depth),index,7n,1,3,7,17,31,63,127,255)};'''
trees = {}
for side in ['baseline', 'candidate']:
    source = (whole / (side + '.mjs')).read_text()
    assert source.count(marker) == 1 and '$let30Exports' not in source
    target = out / (side + '-tree.mjs')
    target.write_text(source.replace(marker, wrapper))
    assert target.read_text().replace(wrapper, marker) == source
    trees[side] = str(target)
    inputs.append(identity(target))
cases = [
    {'id': 'private-let-original-mandelbrot', 'point': {'args': [2, 0], 'expected': 887240761},
     'modules': {side: str(whole / (side + '.mjs')) for side in ['baseline', 'candidate']}},
    {'id': 'private-let-depth5', 'point': {'exportName': 'treeBench', 'args': [5, 0], 'expected': expected}, 'modules': trees},
]
if reports['helper']['helpersChanged']:
    cases.append({'id': 'private-let-scalar-helper', 'point': {'args': [128, 524800], 'expected': 128},
                  'modules': {side: str(helper / (side + '.mjs')) for side in ['baseline', 'candidate']}})
plan = {'kind': 'phase30-private-let-statement-timing', 'complete': True, 'inputs': inputs, 'cases': cases,
        'scope': 'Only private scalar top-level Let-IIFE lowering. Original actual12 runtime/guards/arithmetic; no instrumentation.',
        'helperChanged': bool(reports['helper']['helpersChanged'])}
save(out / 'plan.json', plan)
for protocol in ['screen', 'confirm']:
    save(out / (protocol + '.json'), {'protocol': protocol, 'inputs': [identity(out / 'plan.json'), *inputs], 'cases': cases})
shutil.copyfile(Path(__file__), out / 'consumed-plan.py')
print(json.dumps({'complete': True, 'out': str(out), 'cases': len(cases)}))
