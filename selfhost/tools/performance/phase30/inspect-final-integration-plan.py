#!/usr/bin/env python3
"""Bind existing final gates/configs to one immutable image; execute no gates."""
from pathlib import Path
import hashlib, json, sys

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
NODE = Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
attempt, out = (Path(x).resolve() for x in sys.argv[1:])
manifest = json.loads((attempt / 'attempt.json').read_text())
assert manifest['config']['cpu'] == '4' and manifest['config']['strictExact']
out.mkdir(parents=True, exist_ok=False)

def identity(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
            'bytes': p.stat().st_size}

def save(p, value):
    p.write_text(json.dumps(value, indent=2) + '\n')

def command(kind, name, argv, cpu, note):
    return {'kind': kind, 'name': name, 'command': list(map(str, argv)),
            'cpu': cpu, 'note': note, 'executed': False}

inputs = [identity(p) for p in [Path(__file__), NODE, attempt / 'attempt.json',
    ROOT / 'design/phase30/final-integration.md']]
for key in ['api', 'runtime', 'base']:
    actual = identity(manifest[key]['file'])
    assert actual['sha256'] == manifest[key]['sha256'], key
    inputs.append(actual)
driver = Path(manifest['snapshot']['root']) / 'tools/typed-driver.mjs'
inputs.append(identity(driver))
bindings = {key: manifest[key]['file'] for key in ['api', 'runtime', 'base']}
bindings['driver'] = str(driver)
save(out / 'worker-admission-config.json', bindings)

parent_config = ROOT / 'selfhost/build/phase24/cost-config-02.json'
old = json.loads(parent_config.read_text())
source = Path(old['source'])
assert identity(source)['sha256'] == 'fac061286a2683914244178eb1f9b4dc2fbc2d393560739663e8bd08bbc12996'
baseline = ROOT / 'selfhost/build/phase29/attempt-04'
base_manifest = json.loads((baseline / 'attempt.json').read_text())
assert base_manifest['config']['upstream'] == manifest['config']['upstream']
inputs += [identity(parent_config), identity(source), identity(baseline / 'attempt.json')]
save(out / 'compiler-cost-config.json', {
    'source': str(source), 'cpu': '0',
    'variants': {
        'typescript': {'attempt': str(baseline), 'typescript': True},
        'phase29': {'attempt': str(baseline)},
        'candidate': {'attempt': str(attempt)},
    },
    'order': ['typescript', 'phase29', 'candidate', 'phase29', 'candidate',
              'typescript', 'candidate', 'typescript', 'phase29'],
})

launchers = out / 'launchers'
launchers.mkdir()
derivations = []
for name in ['integration-corpus.py', 'integration-acquire.py', 'prototype-inherited-controls.py']:
    parent = (ROOT / 'selfhost/build/phase30/integration-launchers-07' / name
              if name.startswith('integration-') else HERE / name)
    source = parent.read_text()
    changes = []
    for before, after in [
        ('ROOT=Path(__file__).resolve().parents[4];TOOLS=', 'ROOT=Path(' + repr(str(ROOT)) + ');TOOLS='),
        ("'4'", "'7'"), ('CPU4', 'CPU7'),
    ]:
        count = source.count(before)
        if count:
            source = source.replace(before, after)
            changes.append({'before': before, 'after': after, 'count': count})
    target = launchers / name
    target.write_text(source)
    (launchers / ('original-' + name)).write_bytes(parent.read_bytes())
    inputs.append(identity(parent))
    derivations.append({'parent': identity(parent), 'derived': identity(target), 'changes': changes})
save(launchers / 'derivation.json', {'kind': 'phase30-final-gate-cpu-binding',
    'complete': True, 'scope': 'Tests, expected results and timeouts unchanged; bind tool root and CPU7.',
    'derivations': derivations})
runs = []
def add(kind, name, args, cpu, note):
    runs.append(command(kind, name, args, cpu, note))

add('gate', 'selected-upstream',
    [sys.executable, HERE.parent / 'phase29/integration-upstream.py', attempt, out / 'upstream'],
    4, '15 exact upstream JS probes; preserve shared failures.')
for mode in ['primitive', 'worker', 'nested', 'primitive-guards']:
    add('gate', mode, [sys.executable, launchers / 'prototype-inherited-controls.py',
        attempt, mode, out / mode], 7, 'Maintained test/oracle unchanged; frozen CPU7 launcher.')
adapted = ROOT / 'selfhost/build/phase30/worker-admission-plan-07/controls.mjs'
inputs += [identity(adapted), identity(adapted.parent / 'plan.json')]
add('gate', 'worker-admission', ['taskset', '-c', '7', NODE, '--stack-size=4096',
    '--max-old-space-size=1024', adapted, out / 'worker-admission-config.json',
    out / 'worker-admission'], 7, 'Exact Phase30 admission amendment; rebind final image only. 120s outer limit.')
add('gate', 'corpus', [sys.executable, launchers / 'integration-corpus.py', attempt,
    ROOT / 'selfhost/build/phase25/corpus-01', out / 'corpus'], 7,
    '23 libraries,127 points; unchanged Phase25 references.')
add('gate', 'component-and-hvm', [sys.executable, launchers / 'integration-acquire.py',
    attempt, out / 'component', out / 'hvm'], 7,
    '22 component observations and exact whole HVM stdout. HVM references remain TS/Phase27.')
add('parent-acquisition', 'original-ten-acquisition', [sys.executable, HERE / 'acquire-transfer.py',
    attempt, out / 'original-ten'], 4,
    'All original source/point identities; candidate versus saved TS/Phase29. No timing claim.')
add('clean-timing', 'compiler-ordinary-check', [NODE,
    HERE.parent / 'phase23/check-matrix.mjs', out / 'compiler-cost-config.json',
    out / 'compiler-cost'], 0,
    'Separate exclusive window:3 rotating samples per image, same fac06128 source; process/request/RSS separately.')
for p in [HERE / 'prototype-integration-plan.py', HERE.parent / 'phase29/integration-upstream.py',
          HERE / 'prototype-inherited-controls.py', HERE / 'acquire-transfer.py',
          HERE.parent / 'phase23/check-matrix.mjs', HERE.parent / 'phase8/check-worker.mjs']:
    inputs.append(identity(p))
save(out / 'plan.json', {
    'kind': 'phase30-final-integration-plan', 'complete': True, 'executed': False,
    'attempt': str(attempt), 'inputs': inputs, 'commands': runs,
    'separateParentActions': [
        'Review focused final-artifact new-rule controls from each owner.',
        'After original acquisition, split unchanged transfer protocol into10 case configs and record1200s outer budgets.',
        'Run timings only in the granted exclusive window; audit every raw report.',
        'Install selected exact attempt, verify release, then run maintained42-step relocation smoke with selected API hash.',
        'Historical3026/196 frontend observations remain historical; retain shared failure statuses.',
    ],
})
(out / 'consumed-plan.py').write_bytes(Path(__file__).read_bytes())
print(json.dumps({'complete': True, 'executed': False, 'out': str(out), 'commands': len(runs)}))
