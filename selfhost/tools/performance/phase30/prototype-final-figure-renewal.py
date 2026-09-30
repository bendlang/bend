#!/usr/bin/env python3
"""Retain prepared16 figure configuration, add the separate bitonic follow-up."""
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

old_path = RAW / 'final-figure-plan-16/config.json'
old = json.loads(old_path.read_text())
assert old['candidateLabel'] == 'Checked16'
new = json.loads(json.dumps(old))
new['candidateStatus'] = 'held candidate pending residual-dispatch investigation and native backend gates; not installed'
new['historicalReports'].append({'report': '../final-tree-bitonic-long-confirm-16/report.json',
                                 'label': 'Actual29/16 separate 15-second tree-bitonic follow-up'})
# Both configuration directories share one parent; relative paths are unchanged.
assert out.parent == old_path.parent.parent
save(out / 'config.json', new)
shutil.copyfile(old_path, out / 'original-config.json')
shutil.copyfile(__file__, out / 'consumed-prepare.py')
paths = [Path(__file__), old_path, old_path.parent / 'plan.json', out / 'config.json',
         HERE / 'inspect-final-figures.py', ROOT / 'design/phase30/final-evidence-figures.md',
         RAW / 'final-tree-bitonic-long-confirm-16/report.json']
save(out / 'plan.json', {'kind': 'phase30-final16-figure-renewal', 'complete': True,
                         'executed': False, 'inputs': [ident(p) for p in paths],
                         'changes': ['Explicit held/noninstalled status', 'Add separate tree-bitonic long window; no sample replacement or pooling']})
print(json.dumps({'complete': True, 'out': str(out)}))
