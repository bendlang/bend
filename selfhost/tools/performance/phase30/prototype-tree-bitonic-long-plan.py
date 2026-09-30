#!/usr/bin/env python3
"""Bind an unchanged original tree-bitonic point to the existing long runner."""
from pathlib import Path
import hashlib
import json
import shutil
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RAW = ROOT / 'selfhost/build/phase30'
out = Path(sys.argv[1]).resolve()
out.mkdir(parents=True, exist_ok=False)

def ident(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}

def save(p, value):
    p.write_text(json.dumps(value, indent=2) + '\n')

old_path = RAW / 'final-transfer-plan-16/tree-bitonic.json'
old = json.loads(old_path.read_text())
assert old['protocol'] == 'transfer' and len(old['cases']) == 1
case = old['cases'][0]
assert case['id'] == 'tree-bitonic'
assert case['point'] == {'args': [8, 0], 'expected': 971629740, 'exportName': 'bench'}
source = HERE.parent / 'phase28/corpus/tree-bitonic.bend'
paths = [Path(__file__), old_path, source,
         ROOT / 'design/phase30/final-tree-bitonic-long-warmup.md',
         RAW / 'tree-compiler-plan-12/long-warmup-time.py',
         RAW / 'tree-compiler-plan-12/long-warmup-compare.py',
         HERE.parent / 'phase29/execute.mjs',
         RAW / 'final-transfer-plan-16/tree-bitonic-timing/report.json',
         RAW / 'transfer-16/report.json']
for name, filename in case['modules'].items():
    module = Path(filename)
    receipt_path = Path(filename + '.json')
    receipt = json.loads(receipt_path.read_text())
    assert receipt['complete'] and (receipt.get('checked') or receipt.get('observation', {}).get('checked'))
    assert receipt['input']['sha256'] == ident(source)['sha256']
    assert receipt['output']['sha256'] == ident(module)['sha256']
    paths.extend([module, receipt_path])
    for key in ['api', 'runtime', 'base', 'driver', 'attempt']:
        if key in receipt:
            item = receipt[key]
            p = Path(item['file'])
            assert ident(p)['sha256'] == item['sha256']
            paths.append(p)
inputs = [ident(p) for p in dict.fromkeys(paths)]
long_case = {**case, 'id': 'final16-tree-bitonic-long-warmup'}
plan = {'kind': 'phase30-final16-tree-bitonic-long-warmup', 'complete': True,
        'executed': False, 'inputs': inputs, 'cases': [long_case],
        'scope': 'Separate 15-second-warmup diagnostic; unchanged original input and three checked modules; no rewritten output, no pooled samples.'}
save(out / 'plan.json', plan)
save(out / 'long-warmup.json', {'protocol': 'long_warmup', 'inputs': [ident(out / 'plan.json'), *inputs], 'cases': [long_case]})
shutil.copyfile(__file__, out / 'consumed-plan.py')
print(json.dumps({'complete': True, 'out': str(out), 'variants': list(case['modules']), 'executed': False}))
