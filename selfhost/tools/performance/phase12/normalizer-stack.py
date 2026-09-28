#!/usr/bin/env python3
"""Fresh-process resource-boundary replay; no source or compiler transformation."""
import hashlib
import json
import os
import pathlib
import subprocess
import time

ROOT = pathlib.Path(__file__).resolve().parents[3]
BUILD = ROOT / 'build'
OUT = BUILD / 'phase12/normalizer-stack-01'
NODE = pathlib.Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
UPSTREAM = ROOT / '.bootstrap/upstream-phase8'
FIXTURE = UPSTREAM / 'tests/check/string_literal_long.bend'
VARIANTS = {
    'baseline': BUILD / 'phase11/integrated-01',
    'seed': BUILD / 'phase12/normalizer-seed-checked-01',
}

def identity(file):
    file = file.resolve()
    return {'file': str(file), 'sha256': hashlib.sha256(file.read_bytes()).hexdigest()}

def write(file, value):
    file.write_text(json.dumps(value, indent=2) + '\n')

OUT.mkdir(parents=True, exist_ok=False)
inputs = [identity(pathlib.Path(__file__)), identity(NODE), identity(FIXTURE),
          identity(UPSTREAM / 'bend2/base.bend')]
for attempt in VARIANTS.values():
    inputs.extend(identity(attempt / name) for name in [
        'attempt.json', 'api.mjs.bootstrap.json', 'equality/api.mjs',
        'snapshot/src/runtime.mjs', 'snapshot/tools/typed-driver.mjs',
        'snapshot/tools/conformance/run.mjs',
        'snapshot/tools/conformance/adapters/typed.mjs'])
    inputs.extend(identity(p) for p in (attempt / 'snapshot/build/typed/cache').glob('*.json'))
modules = json.loads((VARIANTS['baseline'] / 'snapshot/src/compiler.json').read_text())['modules']
source_differences = []
for module in modules:
    before = identity(VARIANTS['baseline'] / 'snapshot' / module)
    after = identity(VARIANTS['seed'] / 'snapshot' / module)
    inputs.extend([before, after])
    if before['sha256'] != after['sha256']:
        source_differences.append(module)
assert source_differences == ['src/core/normalize.bend'], source_differences
original = (VARIANTS['baseline'] / 'snapshot/src/core/normalize.bend').read_text()
candidate = (VARIANTS['seed'] / 'snapshot/src/core/normalize.bend').read_text()
assert candidate == original.replace('norm_eval(book, t, Nil{}, 0, atom("Absent"))', 'norm_eval(book, t, Nil{}, 0, t)')
order = ['baseline', 'seed', 'seed', 'baseline']
plan = {'kind': 'phase12-seed-long-string-stack-replay', 'complete': False,
        'scope': 'Four fresh isolated check workers. Same 4096 KiB stack / 4096 MiB heap. '
                 'Retain complete observations/errors. Not timing or a semantic-equivalence theorem.',
        'cpu': 2, 'order': order, 'inputs': inputs,
        'baselineSeedSourceDifferences': source_differences}
write(OUT / 'plan.json', plan)
rows = []
for index, variant in enumerate(order):
    attempt = VARIANTS[variant]
    directory = OUT / f'{index:02}-{variant}'
    directory.mkdir()
    output = directory / 'observations.json'
    cmd = ['taskset', '-c', '2', str(NODE),
           str(attempt / 'snapshot/tools/conformance/run.mjs'),
           '--upstream', str(UPSTREAM),
           '--adapter', str(attempt / 'snapshot/tools/conformance/adapters/typed.mjs'),
           '--output', str(output), '--jobs', '1', '--timeout', '30000',
           '--worker-mode', 'isolated', '--lanes', 'check',
           '--filter', '^check/string_literal_long\\.bend$',
           '--stack-kb', '4096', '--heap-mb', '4096',
           '--retain', 'all', '--selected-exit', '1']
    env = {k: v for k, v in os.environ.items() if not k.startswith('BEND_') and k != 'NODE_OPTIONS'}
    env.update(BEND_TYPED_API=str(attempt / 'equality/api.mjs'),
               BEND_TYPED_RUNTIME=str(attempt / 'snapshot/src/runtime.mjs'),
               BEND_BASE=str(UPSTREAM / 'bend2/base.bend'), BEND_UPSTREAM=str(UPSTREAM),
               BEND_TYPED_TRACE='1')
    write(directory / 'command.json', {'argv': cmd, 'cwd': str(ROOT),
          'environment': {k: v for k, v in env.items() if k.startswith('BEND_')}})
    started = time.monotonic()
    with (directory / 'stdout').open('wb') as stdout, (directory / 'stderr').open('wb') as stderr:
        child = subprocess.run(cmd, cwd=ROOT, env=env, stdout=stdout, stderr=stderr, timeout=45)
    result = json.loads(output.read_text())
    # Harness complete/selectedComplete include success, so expected baseline
    # rejection is false. A retained observation with unchanged inputs is done.
    assert len(result['results']) == 1 and result['changedInputs'] == []
    row = {'index': index, 'variant': variant, 'exitCode': child.returncode,
           'wallSeconds': time.monotonic() - started,
           'artifact': identity(output), 'observation': result['results'][0]}
    rows.append(row)
    write(OUT / 'progress.json', rows)
    print(json.dumps({'variant': variant, 'index': index, 'observation': row['observation']}), flush=True)
verified = all(identity(pathlib.Path(i['file'])) == i for i in inputs)
write(OUT / 'report.json', {**plan, 'complete': True, 'inputsVerified': verified, 'rows': rows})
assert verified
