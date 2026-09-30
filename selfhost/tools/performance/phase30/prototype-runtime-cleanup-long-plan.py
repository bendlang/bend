#!/usr/bin/env python3
"""Freeze one actual15/16/TS original Mandelbrot long-warmup comparison."""
from pathlib import Path
import hashlib, json, shutil, sys
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RAW = ROOT / 'selfhost/build/phase30'
out = Path(sys.argv[1]).resolve()
out.mkdir(parents=True, exist_ok=False)
def ident(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}
def save(p, x):
    p.write_text(json.dumps(x, indent=2) + '\n')
source = HERE.parent / 'phase28/corpus/mandelbrot.bend'
modules = {'repair15': RAW / 'runtime-actual-source-15-mandelbrot/candidate.mjs',
           'candidate16': RAW / 'runtime-actual-source-16-mandelbrot/candidate.mjs',
           'typescript': ROOT / 'selfhost/build/phase28/runtime-01/mandelbrot/upstream.mjs'}
paths = [Path(__file__), source, ROOT / 'design/phase30/final-runtime-cleanup-long-warmup.md',
         RAW / 'tree-compiler-plan-12/long-warmup-time.py', RAW / 'tree-compiler-plan-12/long-warmup-compare.py',
         HERE.parent / 'phase29/execute.mjs', RAW / 'private-let-compiler-long-confirm-14/report.json',
         RAW / 'transfer-16/report.json']
for name, module in modules.items():
    receipt_path = Path(str(module) + '.json')
    receipt = json.loads(receipt_path.read_text())
    assert receipt['complete'] and (receipt.get('checked') or receipt.get('observation', {}).get('checked'))
    assert receipt['input']['sha256'] == ident(source)['sha256']
    assert receipt['output']['sha256'] == ident(module)['sha256']
    paths.extend([module, receipt_path])
    if name != 'typescript':
        attempt = RAW / ('attempt-15' if name == 'repair15' else 'attempt-16')
        m = json.loads((attempt / 'attempt.json').read_text())
        assert receipt['attempt']['sha256'] == ident(attempt / 'attempt.json')['sha256']
        paths.append(attempt / 'attempt.json')
        for key in ['api', 'runtime', 'base', 'driver']:
            p = Path(receipt[key]['file'])
            assert ident(p)['sha256'] == receipt[key]['sha256']
            if key in m:
                assert m[key]['sha256'] == receipt[key]['sha256']
            paths.append(p)
transfer = json.loads((RAW / 'transfer-16/report.json').read_text())
assert transfer['complete']
case = next(c for c in transfer['cases'] if c['id'] == 'mandelbrot')
assert case['complete'] and case['point']['args'] == [2, 0] and case['point']['expected'] == 887240761
assert Path(case['modules']['candidate']).read_bytes() == modules['candidate16'].read_bytes()
paths.extend([Path(case['modules']['candidate']), Path(case['modules']['candidate'] + '.json')])
for name in ['runtime-actual-proof-15b', 'review-retire-structure-16b-mandelbrot', 'review-retire-callables-16-mandelbrot']:
    gate = RAW / name / 'report.json'
    d = json.loads(gate.read_text())
    assert d['complete'] and d['pass']
    paths.append(gate)
inputs = [ident(p) for p in dict.fromkeys(paths)]
plan = {'kind': 'phase30-final16-original-mandel-long-warmup', 'complete': True, 'executed': False,
        'inputs': inputs, 'scope': 'Separate settled-speed retention check: runtime15/source-cleaned16/TS, exact original bench2 point. Same existing15-second warmup protocol; no variant retuning.',
        'cases': [{'id': 'final-runtime-cleanup-original-mandelbrot', 'point': case['point'], 'modules': {k: str(v) for k, v in modules.items()}}]}
save(out / 'plan.json', plan)
save(out / 'long-warmup.json', {'protocol': 'long_warmup', 'inputs': [ident(out / 'plan.json'), *inputs], 'cases': plan['cases']})
shutil.copyfile(__file__, out / 'consumed-plan.py')
print(json.dumps({'complete': True, 'out': str(out), 'variants': list(modules)}))
