#!/usr/bin/env python3
"""Renew checked-source tree controls with one new image and retained references."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
previous, attempt, out = (Path(x).resolve() for x in sys.argv[1:])
NODE = Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
CONTROL = HERE / 'inspect-source-tree-controls.mjs'
EMITTER = HERE.parent / 'phase26/emit.mjs'


def identity(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}


def save(p, value):
    p.write_text(json.dumps(value, indent=2) + '\n')


old = json.loads((previous / 'report.json').read_text())
assert old['complete'] and old['pass']
prior_plan = json.loads((previous / 'plan.json').read_text())
assert prior_plan['complete']
source = Path(prior_plan['source']['file'])
assert identity(source) == prior_plan['source']
inputs = [identity(p) for p in [Path(__file__), NODE, CONTROL, EMITTER, previous / 'report.json',
                               previous / 'plan.json', source, attempt / 'attempt.json',
                               ROOT / 'design/phase30/source-scalar-tree-controls.md']]
out.mkdir(parents=True, exist_ok=False)
for side in ['typescript', 'previous']:
    module = previous / (side + '.mjs')
    receipt = Path(str(module) + '.json')
    observed = json.loads(receipt.read_text())
    assert observed['complete'] and (observed.get('checked') or observed.get('observation', {}).get('checked'))
    assert observed['input']['sha256'] == identity(source)['sha256']
    assert observed['output']['sha256'] == identity(module)['sha256']
    if side == 'previous':
        assert Path(observed['attempt']['file']).parent.name == 'attempt-11'
        assert identity(observed['attempt']['file'])['sha256'] == observed['attempt']['sha256']
        inputs.append(identity(observed['attempt']['file']))
    inputs += [identity(module), identity(receipt)]
    shutil.copyfile(module, out / (side + '.mjs'))
    shutil.copyfile(receipt, out / (side + '.mjs.json'))
control = CONTROL.read_text()
old_scope = 'actual11/12 ordered live-owner fallback'
assert control.count(old_scope) == 1
control = control.replace(old_scope, 'retained pre-tree11 versus selected final-image ordered live-owner fallback')
target = out / 'controls.mjs'
target.write_text(control)
inputs.append(identity(target))
save(out / 'plan.json', {'kind': 'phase30-checked-source-tree-final-rebinding', 'complete': True,
                       'inputs': inputs, 'source': identity(source), 'candidate': str(attempt),
                       'referenceAcquisition': str(previous), 'cpu': 7, 'timeoutSeconds': 120,
                       'controlDerivation': 'Only descriptive scope string changed; assertions and oracles unchanged.'})
shutil.copyfile(source, out / 'source.bend')
shutil.copyfile(Path(__file__), out / 'consumed-rebind.py')
report = {'kind': 'phase30-checked-source-tree-final-renewal', 'complete': False, 'pass': False,
          'inputs': inputs, 'steps': [], 'retainedReferences': ['typescript', 'previous']}
env = {k: v for k, v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS', 'NODE_PATH']}


def child(name, arguments):
    command = ['taskset', '-c', '7', str(NODE), '--stack-size=4096', '--max-old-space-size=1024', *map(str, arguments)]
    row = {'name': name, 'command': command, 'complete': False}
    report['steps'].append(row)
    save(out / 'report.json', report)
    start = time.monotonic()
    with (out / (name + '.stdout')).open('w') as stdout, (out / (name + '.stderr')).open('w') as stderr:
        try:
            row['exitCode'] = subprocess.run(command, cwd=ROOT, env=env, stdout=stdout, stderr=stderr, timeout=120).returncode
        except subprocess.TimeoutExpired:
            row['timeout'] = True
    row['wallSeconds'] = time.monotonic() - start
    row['stdout'], row['stderr'] = identity(out / (name + '.stdout')), identity(out / (name + '.stderr'))
    row['complete'] = row.get('exitCode') == 0 and not row.get('timeout')
    save(out / 'report.json', report)
    assert row['complete'], name


try:
    child('candidate', [EMITTER, attempt, source, out / 'candidate.mjs'])
    child('controls', [target, out, out / 'controls'])
    results = json.loads((out / 'controls/report.json').read_text())
    assert results['complete'] and results['pass']
    assert all(identity(row['file']) == row for row in inputs)
    report.update({'complete': True, 'pass': True, 'controls': identity(out / 'controls/report.json')})
except Exception as error:
    report['error'] = repr(error)
    raise
finally:
    save(out / 'report.json', report)
print(json.dumps({'complete': True, 'pass': True, 'out': str(out)}))
