#!/usr/bin/env python3
"""Freeze guard-allocation screen and distinct warmed follow-ups after gates."""
from pathlib import Path
import hashlib, json, shutil, sys

ROOT = Path(__file__).resolve().parents[4]; BUILD = ROOT / 'selfhost/build/phase30'
source, out = map(lambda x: Path(x).resolve(), sys.argv[1:]); out.mkdir(parents=True, exist_ok=False)

def ident(p):
    p = Path(p).resolve(); raw = p.read_bytes()
    return {'file': str(p), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}

def save(p, x):
    p.write_text(json.dumps(x, indent=2) + '\n')

gates = [BUILD / name / 'report.json' for name in [
    'guard-core-baseline-02', 'guard-core-candidate-02', 'guard-helper-controls-02',
    'guard-entry-controls-02', 'guard-whole-controls-02', 'guard-whole-boundaries-02', 'review-guard-reflection-01']]
for file in gates:
    d = json.loads(file.read_text()); assert d['complete'] and d['pass'], str(file)
derived = json.loads((source / 'derive.json').read_text()); assert derived['complete']
runner = BUILD / 'tree-compiler-plan-12/long-warmup-compare.py'
launcher = BUILD / 'tree-compiler-plan-12/long-warmup-time.py'
inputs = [ident(p) for p in [Path(__file__), source / 'derive.json', ROOT / 'design/phase30/scalar-guard-fixed-lists.md',
          BUILD / 'guard-controls-plan-02/plan.json', runner, launcher, *gates]]
cases = []
for name, args, expected in [('helper', [128, 524800], 128), ('whole', [2, 0], 887240761)]:
    modules = {}
    for side in ['baseline', 'candidate']:
        item = derived['cases'][name][side]; assert ident(item['file']) == item
        inputs.append(item); modules[side] = item['file']
    cases.append({'id': 'guard-fixed-lists-' + name, 'point': {'args': args, 'expected': expected}, 'modules': modules})
plan = {'kind': 'phase30-complete-guard-allocation-prospective-timing', 'complete': True, 'inputs': inputs,
        'scope': 'Actual14 outputs versus guard-only temporary-allocation derivative. All predicates and metadata read order retained under the existing standard-intrinsic scope; no result cache. Diagnostic modules excluded.',
        'decision': 'At least5% stable helper time saving or3% whole saving, with no confirmed regression above3% on the other; no causal split between list hoisting and explicit checks.',
        'wholeLongLauncher': str(launcher), 'cases': cases}
save(out / 'plan.json', plan); shutil.copyfile(Path(__file__), out / 'consumed-plan.py')
for filename, protocol, selected in [('screen.json', 'screen', cases), ('confirm-helper.json', 'confirm', cases[:1]),
                                     ('long-whole.json', 'long_warmup', cases[1:])]:
    save(out / filename, {'protocol': protocol, 'inputs': [ident(out / 'plan.json'), *inputs], 'cases': selected})
print(json.dumps({'complete': True, 'out': str(out)}))
