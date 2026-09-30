#!/usr/bin/env python3
"""Run retained terminal-region controls on two actual checked emissions."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
NODE = Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
baseline, candidate, out = map(lambda p: Path(p).resolve(), sys.argv[1:])
out.mkdir(parents=True, exist_ok=False)


def identity(p):
    p = Path(p)
    raw = p.read_bytes()
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(raw).hexdigest(),
            'bytes': len(raw)}


def save(p, value):
    p.write_text(json.dumps(value, indent=2) + '\n')


inputs = [identity(Path(__file__)), identity(NODE)]
receipts = []
for label, module in [('baseline', baseline), ('candidate', candidate)]:
    receipt_file = Path(str(module) + '.json')
    receipt = json.loads(receipt_file.read_text())
    assert receipt['complete'] and receipt['observation']['checked']
    assert receipt['output']['sha256'] == identity(module)['sha256']
    inputs.extend([identity(module), identity(receipt_file)])
    receipts.append(receipt)
    (out / (label + '.mjs')).write_bytes(module.read_bytes())
assert receipts[0]['input']['sha256'] == receipts[1]['input']['sha256']
assert receipts[0]['base']['sha256'] == receipts[1]['base']['sha256']
assert '/* private scalar region */' in candidate.read_text()
save(out / 'derive.json', {
    'kind': 'phase30-actual-terminal-compiler-control-inputs',
    'complete': True, 'inputs': inputs,
    'scope': 'Unmodified checked emissions; only the test variant list changes.'})

environment = {k: v for k, v in os.environ.items()
               if not k.startswith('BEND_') and k not in ['NODE_OPTIONS', 'NODE_PATH']}
report = {'complete': False, 'pass': False, 'inputs': inputs, 'runs': []}
save(out / 'report.json', report)
for suffix in ['controls', 'counts']:
    source = HERE / ('inspect-terminal-region-' + suffix + '.mjs')
    original = source.read_text()
    marker = "const variants=['baseline','outer','acyclic','nested'];"
    assert original.count(marker) == 1
    derived = original.replace(marker, "const variants=['baseline','candidate'];")
    tool = out / ('actual-' + suffix + '.mjs')
    tool.write_text(derived)
    inputs.append(identity(source))
    command = ['taskset', '-c', '4', str(NODE), '--stack-size=4096',
               '--max-old-space-size=1024', str(tool), str(out), str(out / suffix)]
    row = {'command': command, 'originalTool': identity(source),
           'derivedTool': identity(tool), 'complete': False}
    report['runs'].append(row)
    with (out / (suffix + '.stdout')).open('w') as stdout, \
            (out / (suffix + '.stderr')).open('w') as stderr:
        try:
            row['exitCode'] = subprocess.run(command, cwd=ROOT, env=environment,
                                             stdout=stdout, stderr=stderr,
                                             timeout=180).returncode
        except subprocess.TimeoutExpired:
            row['timeout'] = True
    result_file = out / suffix / 'report.json'
    if result_file.exists():
        row['result'] = identity(result_file)
        result = json.loads(result_file.read_text())
        row['complete'] = row.get('exitCode') == 0 and result.get('pass', False)
    save(out / 'report.json', report)
assert all(identity(row['file']) == row for row in inputs)
report['complete'] = report['pass'] = all(row['complete'] for row in report['runs'])
save(out / 'report.json', report)
print(json.dumps({'complete': report['complete'], 'pass': report['pass'],
                  'out': str(out)}))
raise SystemExit(0 if report['pass'] else 1)
