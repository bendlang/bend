#!/usr/bin/env python3
"""Prepare one identical complete-state adapter over supplied runtime variants."""
from pathlib import Path
import hashlib, importlib.util, json, shutil, sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
config_path, out = map(lambda x: Path(x).resolve(), sys.argv[1:])
config = json.loads(config_path.read_text())
out.mkdir(parents=True, exist_ok=False)
def ident(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}
def save(p, x):
    p.write_text(json.dumps(x, indent=2) + '\n')
def resolve(p):
    p = Path(p)
    return p.resolve() if p.is_absolute() else (config_path.parent / p).resolve()
oracle_tool = HERE / 'prototype-owned-derive.py'
spec = importlib.util.spec_from_file_location('retained_owned_row', oracle_tool)
oracle = importlib.util.module_from_spec(spec)
spec.loader.exec_module(oracle)
source = ROOT / 'selfhost/build/phase30/prototype-owned-source-01/row.bend'
paths = [Path(__file__), config_path, oracle_tool, HERE / 'inspect-terminal-region.py', source,
         ROOT / 'design/phase30/generic-runtime-row-diagnosis.md']
report = {'kind': 'phase30-runtime-row-adapters', 'complete': False, 'variants': {}, 'inputs': [], 'scope': 'Identical full four-array128-slot row.probe adapter; no source or runtime rewrite here.'}
save(out / 'derive.json', report)
for name, variant in config['variants'].items():
    assert name.replace('_', '').replace('-', '').isalnum()
    module = resolve(variant['module'])
    paths.append(module)
    if variant.get('receipt'):
        receipt_path = resolve(variant['receipt'])
        paths.append(receipt_path)
        receipt = json.loads(receipt_path.read_text())
        assert receipt['complete']
        assert receipt['input']['sha256'] == ident(source)['sha256']
        assert receipt['output']['sha256'] == ident(module)['sha256']
        if variant.get('typescript'):
            assert receipt['checked']
        else:
            assert receipt['observation']['checked']
            if variant.get('attempt'):
                assert Path(receipt['attempt']['file']).parent.name == variant['attempt']
    target = out / (name + '.mjs')
    target.write_text(oracle.wrap(module.read_text(), variant.get('typescript', False)))
    report['variants'][name] = ident(target)
for value in config.get('evidence', []):
    paths.append(resolve(value))
points = [{'args': [n, seed], 'expected': oracle.oracle(n, seed)}
          for n in [0, 1, 2, 7, 16, 32, 64] for seed in [0, 1, 17, 4294967295]]
save(out / 'points.json', points)
report.update(complete=True, inputs=[ident(p) for p in dict.fromkeys(paths)], points=ident(out / 'points.json'))
save(out / 'derive.json', report)
shutil.copyfile(__file__, out / 'consumed-plan.py')
print(json.dumps({'complete': True, 'variants': list(report['variants']), 'points': len(points)}))
