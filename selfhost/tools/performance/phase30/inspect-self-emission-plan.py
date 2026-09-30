#!/usr/bin/env python3
"""Freeze one B1->H acquisition plan; execute no compiler or generated program."""
from pathlib import Path
import argparse
import hashlib
import json
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
NODE_SHA = '41a74efb34cbde5c7632cdac0cf8bd1a14d0b8d73dc1e82755014d9a9ce70f5c'
POSITIVE = '''import Base

@unsafe
def count(+n: Nat, +value: U32) -> U32:
  match n:
    case 0n: value
    case 1n+p: count(p, U32.add(value, 3))

def main() -> U32:
  U32.add(count(3n, 4294967294), 1)
'''
NEGATIVE = '''import Base

def main() -> U32:
  True{}
'''


def identity(file):
    file = Path(file).resolve()
    raw = file.read_bytes()
    return {'file': str(file), 'canonicalPath': str(file),
            'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('attempt', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--cpu', default='2')
    parser.add_argument('--timeout-seconds', type=int, default=1200)
    parser.add_argument('--heap-mb', type=int, default=8192)
    parser.add_argument('--oracle-timeout-seconds', type=int, default=90)
    args = parser.parse_args()
    assert args.cpu.isdecimal()
    assert 0 < args.timeout_seconds <= 1200 and 0 < args.heap_mb <= 8192
    assert 0 < args.oracle_timeout_seconds <= 90
    attempt, out = args.attempt.resolve(), args.output.resolve()
    m = json.loads((attempt / 'attempt.json').read_text())
    assert m['kind'] == 'bend-development-attempt' and m['version'] == 1 and m['checked'] is True
    assert m['node']['version'] == 'v24.18.0' and m['node']['sha256'] == NODE_SHA
    inputs = {}

    def retain(file, expected=None):
        item = identity(file)
        if expected is not None:
            assert item['sha256'] == expected['sha256'], 'Changed input: ' + str(file)
            if 'canonicalPath' in expected:
                assert item['canonicalPath'] == expected['canonicalPath']
        old = inputs.get(item['file'])
        assert old is None or old == item
        inputs[item['file']] = item
        return item

    attempt_id = retain(attempt / 'attempt.json')
    for key in ['node', 'api', 'checkedApi', 'bootstrapReport', 'base', 'runtime']:
        retain(m[key]['file'], m[key])
    for item in m['artifacts']:
        retain(item['file'], item)
    for item in m['snapshot']['sources']:
        retain(item['frozen']['file'], item['frozen'])
    bootstrap = json.loads(Path(m['bootstrapReport']['file']).read_text())
    assert bootstrap['revision'] == '018751270e800bc222a93dad7f257083ee53a5f7'
    assert bootstrap['apiSha256'] == m['checkedApi']['sha256']
    assert bootstrap['baseSha256'] == m['base']['sha256']
    source = retain(bootstrap['source'], {'sha256': bootstrap['sourceSha256']})
    assert any(x['canonicalPath'] == source['canonicalPath'] and x['sha256'] == source['sha256']
               for x in m['artifacts']), 'Assembled source is not an attested artifact'
    driver = retain(Path(m['snapshot']['root']) / 'tools/typed-driver.mjs')
    emitter = retain(HERE.parent / 'phase26/emit.mjs')
    # The unchanged emitter imports this current workflow; its complete local
    # development module set is retained, while verifyAttempt checks its snapshot.
    for file in sorted((ROOT / 'selfhost/tools/development').glob('*.mjs')):
        retain(file)
    for file in [Path(__file__), ROOT / 'design/phase30/bounded-self-emission.md',
                 ROOT / 'implementation/phase30/self-emission-feasibility.md']:
        retain(file)
    out.mkdir(parents=True, exist_ok=False)
    fixtures = {}
    for name, source_text in [('positive', POSITIVE), ('negative', NEGATIVE)]:
        file = out / (name + '.bend')
        file.write_text(source_text)
        fixtures[name] = retain(file)
    node_args = ['--stack-size=4096', '--max-old-space-size=' + str(args.heap_mb)]
    plan = {'kind': 'phase30-bounded-self-emission-plan', 'complete': True, 'executed': False,
            'attempt': attempt_id, 'source': source, 'node': m['node'],
            'api': m['api'], 'checkedParent': m['checkedApi'], 'base': m['base'],
            'runtime': m['runtime'], 'driver': driver, 'emitter': emitter,
            'fixtures': fixtures, 'inputs': list(inputs.values()),
            'resources': {'cpu': args.cpu, 'nodeArgs': node_args,
                'emissionTimeoutSeconds': args.timeout_seconds,
                'oracleTimeoutSeconds': args.oracle_timeout_seconds,
                'programTimeoutSeconds': 10, 'minimumOsStackKiB': 8192},
            'emissionCommand': ['taskset', '-c', args.cpu, m['node']['file'], *node_args,
                emitter['file'], str(attempt), source['file'], str(out / 'stage2.mjs')],
            'emissionEnvironment': {'BEND_TYPED_TRACE': '1'},
            'output': str(out / 'stage2.mjs'),
            'oracle': {'positiveResult': 8, 'negativeStatus': 'error', 'negativePhase': 'check',
                'requiredAbi': {'compiler_load_abi': 2, 'compiler_term_abi': 1,
                                'compiler_span_abi': 3, 'compiler_check_result_abi': 2},
                'independentDerivation': '(4294967294 + 3*3 + 1) mod 2^32 = 8',
                'order': ['B1 positive/negative preflight', 'one B1->H emission',
                          'H syntax/ABI/Base preparation', 'H same positive/negative oracle']},
            'scope': 'One checked compiler-source emission and small H oracle; no H->H, fixed point, controlled speed ratio or installation.',
            'executionPolicy': 'Root grant required after final release/timing priorities. Parent launcher must enforce process-tree deadlines and save outer failure receipts.'}
    for item in inputs.values():
        assert identity(item['file']) == item, 'Input changed during planning'
    (out / 'plan.json').write_text(json.dumps(plan, indent=2) + '\n')
    (out / 'consumed-plan.py').write_bytes(Path(__file__).read_bytes())
    print(json.dumps({'complete': True, 'executed': False, 'out': str(out),
                      'source': source['sha256'], 'compiler': m['api']['sha256']}))


if __name__ == '__main__':
    main()
