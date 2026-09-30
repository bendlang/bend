#!/usr/bin/env python3
"""Bind retained independent scalar/tree controls to the guard-only derivative."""
from pathlib import Path
import hashlib, importlib.util, json, shutil, sys

HERE = Path(__file__).resolve().parent; ROOT = HERE.parents[3]
source, out = map(lambda x: Path(x).resolve(), sys.argv[1:]); out.mkdir(parents=True, exist_ok=False)
PARSER = HERE / 'inspect-terminal-region.py'
spec = importlib.util.spec_from_file_location('guard_controls_parser', PARSER)
parser = importlib.util.module_from_spec(spec); spec.loader.exec_module(parser)

def ident(p):
    p = Path(p).resolve(); raw = p.read_bytes()
    return {'file': str(p), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}

def save(p, x):
    p.write_text(json.dumps(x, indent=2) + '\n')

derived = json.loads((source / 'derive.json').read_text()); assert derived['complete']
original_controls = ROOT / 'selfhost/build/phase30/inspection-private-let-actual-14/controls.mjs'
inputs = [ident(p) for p in [Path(__file__), PARSER, source / 'derive.json', original_controls]]
for case in derived['cases'].values():
    for key in ['baseline', 'candidate']:
        assert ident(case[key]['file']) == case[key]; inputs.append(case[key])
helper = {key: derived['cases']['helper'][key]['file'] for key in ['baseline', 'candidate']}
save(out / 'helper-config.json', helper)
whole = out / 'whole'; whole.mkdir()
for key in ['baseline', 'candidate']:
    shutil.copyfile(derived['cases']['whole'][key]['file'], whole / (key + '.mjs'))
shutil.copyfile(original_controls, whole / 'controls.mjs')
text = (whole / 'candidate.mjs').read_text()
owner = next(line for line in text.splitlines() if line.startswith('G["rcol"]='))
fast_open = owner.index('/* private scalar tree */') - 1
fast_close = parser.close(owner, fast_open)
callback = 'function(a,$entered){'
callback_open = owner.rfind(callback, 0, fast_open) + len(callback) - 1
callback_close = parser.close(owner, callback_open)
sentinel = owner[:fast_open + 1] + 'return "fast";' + owner[fast_close:fast_close + 1] + 'return "generic";' + owner[callback_close:]
assert text.count(owner) == 1
(whole / 'candidate-depth-sentinel.mjs').write_text(text.replace(owner, sentinel))
save(whole / 'derive.json', {'kind': 'phase30-guard-whole-control-adapter', 'complete': True, 'inputs': inputs,
     'scope': 'Same actual14 baseline and disposable guard-allocation derivative. Original private-Let control actions/expected outputs unchanged; this does not relabel the derivative as compiler-produced output.'})
save(out / 'boundary-config.json', {'variants': {key: str(whole / (key + '.mjs')) for key in ['baseline', 'candidate']},
     'inputs': [str(whole / 'derive.json'), str(source / 'derive.json')]})
save(out / 'plan.json', {'kind': 'phase30-guard-controls-plan', 'complete': True, 'inputs': inputs,
     'outputs': [ident(p) for p in [out / 'helper-config.json', out / 'boundary-config.json', whole / 'derive.json', whole / 'controls.mjs', whole / 'candidate-depth-sentinel.mjs']]})
shutil.copyfile(Path(__file__), out / 'consumed-controls.py')
print(json.dumps({'complete': True, 'out': str(out)}))
