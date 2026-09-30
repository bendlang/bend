#!/usr/bin/env python3
"""Freeze a narrow Phase30 admission update to the inherited worker guard suite."""
from pathlib import Path
import hashlib, json, shutil, sys

root = Path(__file__).resolve().parents[4]
previous = root / 'selfhost/build/phase30/inherited-worker-guards-07'
out = Path(sys.argv[1]).resolve()
out.mkdir(parents=True, exist_ok=False)

def identity(path):
    path = Path(path).resolve()
    return {'file': str(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}

parent = previous / 'comparison.guards.mjs'
source = parent.read_text()
changes = [
    ("yes('erased-let',erased);yes('parallel-shadow-let',shadow);",
     "no('erased-let',erased);yes('parallel-shadow-let',shadow);"),
    ("assert.equal((emission.match(/\\/\\* private Nat loop \\*\\//g)||[]).length,2);",
     "assert.equal((emission.match(/\\/\\* private Nat loop \\*\\//g)||[]).length,1);"),
]
for before, after in changes:
    assert source.count(before) == 1, before
    source = source.replace(before, after)
derived = out / 'controls.mjs'
derived.write_text(source)
shutil.copyfile(previous / 'config.json', out / 'config.json')
shutil.copyfile(Path(__file__), out / 'consumed-derivation.py')
plan = {
    'kind': 'phase30-inherited-worker-admission-amendment',
    'scope': 'Synthetic KDefs. The closed scalar region deliberately rejects erased lets; '
             'the public generic fallback must retain erased-RHS suppression. '
             'Only this admission expectation and its resulting worker-marker count change. '
             'All 40 guard cases and both runtime/evaluation assertions are retained.',
    'timing': 'CPU4 acquisition only, no performance claim.',
    'preservedFailure': str(previous / 'report.json'),
    'inputs': [identity(parent), identity(previous / 'comparison.derivation.json'),
               identity(previous / 'config.json'), identity(Path(__file__)),
               identity(root / 'selfhost/build/phase30/attempt-07/snapshot/src/back/js/region.bend')],
    'changes': [{'before': before, 'after': after, 'count': 1} for before, after in changes],
    'derived': identity(derived),
    'config': identity(out / 'config.json'),
}
(out / 'plan.json').write_text(json.dumps(plan, indent=2) + '\n')
print(json.dumps({'complete': True, 'out': str(out)}))
