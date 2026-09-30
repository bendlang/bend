#!/usr/bin/env python3
"""Freeze actual compiler frame-reuse timing after its fresh semantic gates."""
from pathlib import Path
import hashlib, json, shutil, sys

source, oracle, boundaries, counts, out = map(lambda x: Path(x).resolve(), sys.argv[1:])
out.mkdir(parents=True, exist_ok=False)
ROOT = Path(__file__).resolve().parents[4]

def ident(p):
    p = Path(p).resolve(); raw = p.read_bytes()
    return {'file': str(p), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}

def save(p, x):
    p.write_text(json.dumps(x, indent=2) + '\n')

for p in [oracle, boundaries, counts]:
    d = json.loads(p.read_text()); assert d['complete'] and d['pass']
derived = json.loads((source / 'derive.json').read_text()); assert derived['complete']
runner = ROOT / 'selfhost/build/phase30/tree-compiler-plan-12/long-warmup-compare.py'
launcher = ROOT / 'selfhost/build/phase30/tree-compiler-plan-12/long-warmup-time.py'
inputs = [ident(p) for p in [Path(__file__), source / 'derive.json', oracle, boundaries, counts, runner, launcher,
          ROOT / 'design/phase30/actual-frame-reuse-validation.md', ROOT / 'design/phase30/tree-frame-long-warmup.md']]
modules = {'actual12': str(source / 'baseline.mjs'), 'actual13': str(source / 'reuse.mjs')}
inputs += [ident(p) for p in modules.values()]
case = {'id': 'actual-frame-original', 'point': {'args': [2, 0], 'expected': 887240761}, 'modules': modules}
tree = {}
for name, file in modules.items():
    target = out / (name + '-tree.mjs')
    text = Path(file).read_text(); assert text.count('export default ') == 1
    text = text.replace('export default ', 'const $Frame_exports = ', 1)
    text += '\nexport default {...$Frame_exports,treeBench:(depth,index)=>$Frame_exports.rcol(BigInt(depth),index,7n,1,3,7,17,31,63,127,255)};\n'
    target.write_text(text); tree[name] = str(target); inputs.append(ident(target))
cases = [case, {'id': 'actual-frame-depth5', 'point': {'exportName': 'treeBench', 'args': [5, 0], 'expected': 2725467472}, 'modules': tree}]
plan = {'kind': 'phase30-actual-frame-reuse-prospective-timing', 'complete': True, 'inputs': inputs,
        'scope': 'Actual checked12 versus checked13; only frame push/pop differs. Original source point and identical depth-five adapter. No diagnostic modules.',
        'longWarmupLauncher': str(launcher), 'cases': cases}
save(out / 'plan.json', plan); shutil.copyfile(Path(__file__), out / 'consumed-plan.py')
for protocol in ['screen', 'confirm']:
    save(out / (protocol + '.json'), {'protocol': protocol, 'inputs': [ident(out / 'plan.json'), *inputs], 'cases': cases})
save(out / 'long-warmup.json', {'protocol': 'long_warmup', 'inputs': [ident(out / 'plan.json'), *inputs], 'cases': [case]})
print(json.dumps({'complete': True, 'out': str(out)}))
