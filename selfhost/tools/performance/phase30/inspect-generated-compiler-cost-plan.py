#!/usr/bin/env python3
"""Freeze a small genuine-parent/H request comparison; execute no compiler."""
from pathlib import Path
import hashlib
import json
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
source_plan, out = (Path(x).resolve() for x in sys.argv[1:])
p = json.loads(source_plan.read_text())
assert p['complete'] and p['kind'] == 'phase30-bounded-self-emission-plan'
execution_file = source_plan.parent / 'execution/report.json'
execution = json.loads(execution_file.read_text())
assert execution['complete'] and execution['pass']
oracle_file = source_plan.parent / 'execution/h-oracle/report.json'
oracle = json.loads(oracle_file.read_text())
assert oracle['complete'] and oracle['pass'] and oracle['sameB1Observations'] and oracle['smallOutputBytesEqual']


def identity(file):
    file = Path(file).resolve()
    raw = file.read_bytes()
    return {'file': str(file), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


inputs = {}


def retain(file, expected=None):
    item = identity(file)
    if expected is not None:
        assert item['sha256'] == expected['sha256'], str(file)
    inputs[item['file']] = item
    return item


for item in p['inputs']:
    retain(item['file'], item)
for file in [Path(__file__), source_plan, execution_file, oracle_file,
             HERE / 'inspect-generated-compiler-cost-worker.mjs',
             HERE / 'inspect-generated-compiler-cost-run.mjs',
             ROOT / 'design/phase30/warmed-generated-compiler-cost.md']:
    retain(file)
h = retain(execution['generatedCompiler']['file'], execution['generatedCompiler'])
retain(execution['emissionReceipt']['file'], execution['emissionReceipt'])
parent = retain(p['checkedParent']['file'], p['checkedParent'])
expected = retain(oracle['program']['file'], oracle['program'])
retain(oracle['cache']['after']['file'], oracle['cache']['after'])
out.mkdir(parents=True, exist_ok=False)
plan = {'kind': 'phase30-warmed-generated-compiler-cost-plan', 'complete': True, 'executed': False,
        'inputs': list(inputs.values()), 'node': p['node'], 'source': p['fixtures']['positive'],
        'compilerSource': p['source'], 'driver': p['driver'], 'base': p['base'], 'runtime': p['runtime'],
        'variants': {'checked_parent': parent, 'generated_h': h}, 'selectedB1': p['api'],
        'expected': expected, 'expectedResult': 8, 'abi': p['oracle']['requiredAbi'],
        'worker': identity(HERE / 'inspect-generated-compiler-cost-worker.mjs'),
        'order': [['checked_parent', 'generated_h'], ['generated_h', 'checked_parent'], ['checked_parent', 'generated_h']],
        'prepareCpu': '2', 'cpu': '0', 'timeoutMs': 90000,
        'nodeArgs': ['--stack-size=4096', '--max-old-space-size=8192'],
        'warmRequests': 1, 'timedRequests': 2,
        'scope': 'Warmed-once small checked-library request; same frozen driver, actual API-specific caches and real ABI conversion. Not steady state, fixed point or full compiler cost.',
        'runPolicy': 'Prepare only under root acquisition grant; measure only under root exclusive timing grant.'}
(out / 'plan.json').write_text(json.dumps(plan, indent=2) + '\n')
(out / 'consumed-plan.py').write_bytes(Path(__file__).read_bytes())
print(json.dumps({'complete': True, 'executed': False, 'out': str(out)}))
