#!/usr/bin/env python3
"""Freeze final Phase32 commands and narrow launcher derivations; execute none."""
from pathlib import Path
import hashlib
import json
import shutil
import sys

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
OLD = HERE.parent / 'phase30'
NODE = Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
attempt, out = (Path(x).resolve() for x in sys.argv[1:])
manifest = json.loads((attempt / 'attempt.json').read_text())
assert manifest['checked'] and manifest['config']['strictExact']
assert manifest['config']['cpu'] == '4'
assert manifest['config']['jobs'] == 1 and manifest['config']['heapMb'] <= 1024
out.mkdir(parents=True, exist_ok=False)
inputs, derivations, commands = {}, [], []


def ident(p):
    p = Path(p).resolve()
    raw = p.read_bytes()
    return dict(file=str(p), sha256=hashlib.sha256(raw).hexdigest(), bytes=len(raw))


def keep(p, digest=None):
    row = ident(p)
    if digest:
        assert row['sha256'] == digest, row['file']
    inputs[row['file']] = row
    return row


def save(p, data):
    p.write_text(json.dumps(data, indent=2) + '\n')


def derive(source, target, changes):
    text = source.read_text()
    rows = []
    for before, after, count in changes:
        assert text.count(before) == count, (source, before, text.count(before), count)
        text = text.replace(before, after)
        rows.append(dict(before=before, after=after, count=count))
    target.write_text(text)
    original = target.with_name('original-' + target.name)
    shutil.copyfile(source, original)
    derivations.append(dict(parent=keep(source), original=keep(original),
                            derived=keep(target), changes=rows))
    return target


def command(name, argv, cpu, limit, scope, environment=None):
    row = dict(name=name, command=list(map(str, argv)), cpu=cpu,
               outerTimeoutSeconds=limit, scope=scope, executed=False)
    if environment:
        row['environment'] = environment
    commands.append(row)


keep(Path(__file__))
keep(HERE.parent / 'phase31/final-integration-plan.py')
keep(ROOT / 'design/phase32/representation-and-reuse.md')
performance_baseline = ROOT / 'selfhost/build/phase31/attempt-07'
keep(performance_baseline / 'attempt.json')
keep(ROOT / 'design/phase32/final-integration.md')
keep(attempt / 'attempt.json')
for key in ['api', 'checkedApi', 'runtime', 'base', 'node']:
    keep(manifest[key]['file'], manifest[key]['sha256'])
baseline = ROOT / 'selfhost/build/phase30/attempt-17'  # Retained layout witness only
keep(baseline / 'attempt.json')
assert json.loads((performance_baseline / 'attempt.json').read_text())['base']['sha256'] == manifest['base']['sha256']
assert json.loads((baseline / 'attempt.json').read_text())['base']['sha256'] == manifest['base']['sha256']
tools = out / 'tools'
tools.mkdir()

# Original-program acquisition changes only selection, saved baseline role and CPU.
source = OLD / 'acquire-transfer.py'
acquire = derive(source, tools / 'acquire-original-three.py', [
    ('HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]',
     'HERE=Path(' + repr(str(OLD)) + ');ROOT=HERE.parents[3]', 1),
    ("selfhost/build/phase29/transfer-04/report.json", "selfhost/build/phase31/final-plan-07/original-three/report.json", 1),
    ("len(prior['cases'])==10", "len(prior['cases'])==3", 1),
    ("for case in prior['cases']:",
     "selected=[c for c in prior['cases'] if c['id'] in ['mandelbrot','editdist','test-rle-roundtrip']]\nassert len(selected)==3\nfor case in selected:", 1),
    ("modules={'typescript':case['modules']['upstream'],'phase29':case['modules']['candidate']}",
     "modules={'typescript':case['modules']['typescript'],'baseline07':case['modules']['candidate']}", 1),
    ("'cpu':4", "'cpu':7", 1),
    ("['taskset','-c','4'", "['taskset','-c','7'", 1),
    ('Baseline labels refer to Phase29, not Phase27.',
     'Baseline labels refer to immutable Phase31-07; three preselected original points.', 1),
])
command('acquire-original-three', [sys.executable, acquire, attempt, out / 'original-three'],
        7, 180, 'Checked original Mandelbrot/editdist/RLE output acquisition; no timing.')

# Cost worker is unchanged. Only baseline roles/path bindings differ in planner/runner.
cost_run = derive(OLD / 'library-cost-run.mjs', tools / 'library-cost-run.mjs', [
    ("from '../../development/process.mjs'", 'from ' + json.dumps(str(ROOT / 'selfhost/tools/development/process.mjs')), 1),
    ("['typescript','phase29','candidate']", "['typescript','phase31_07','candidate']", 1),
    ('--max-old-space-size=4096', '--max-old-space-size=1024', 1),
])
cost_plan = derive(OLD / 'library-cost-plan.mjs', tools / 'library-cost-plan.mjs', [
    ("path.resolve(import.meta.dirname,'../../../..')", json.dumps(str(ROOT)), 1),
    ("const attempts={typescript:path.join(root,'selfhost/build/phase29/attempt-04'),phase29:path.join(root,'selfhost/build/phase29/attempt-04'),candidate:finalAttempt};",
     "const attempts={typescript:path.join(root,'selfhost/build/phase29/attempt-04'),phase31_07:path.join(root,'selfhost/build/phase31/attempt-07'),candidate:finalAttempt};", 1),
    ('variants.phase29.base.sha256', 'variants.phase31_07.base.sha256', 1),
    ("phase29:path.join(root,'selfhost/build/phase29/transfer-04',name,'candidate.mjs')",
     "phase31_07:path.join(root,'selfhost/build/phase31/final-plan-07/original-three',name,'candidate.mjs')", 1),
    ("order:['typescript','phase29','candidate']", "order:['typescript','phase31_07','candidate']", 1),
    ("path.join(import.meta.dirname,'library-cost-worker.mjs')", json.dumps(str(OLD / 'library-cost-worker.mjs')), 2),
    ("path.join(import.meta.dirname,'library-cost-run.mjs')", json.dumps(str(cost_run)), 1),
])
keep(OLD / 'library-cost-worker.mjs')
command('prepare-compiler-cost', [NODE, '--max-old-space-size=1024', cost_plan, attempt, out / 'original-three', out / 'compiler-cost-plan'],
        None, 120, 'After original-three acquisition, freeze normal cost/cache/output identities; no timing.')
command('measure-compiler-cost', [NODE, '--max-old-space-size=1024', cost_run, out / 'compiler-cost-plan/config.json', out / 'compiler-cost'],
        0, 900, 'Exclusive grant: unchanged18 fresh library requests, three rotated samples,180s per child.')
command('prepare-original-timing', [sys.executable, HERE / 'final-transfer-plan.py',
        out / 'original-three', out / 'original-timing-plan'], None, 30,
        'Freeze separate original-case transfer configs after successful acquisition; executes no programs.')
keep(HERE / 'final-transfer-plan.py')

# Reuse maintained canary preparation and exact sources; no wrapped candidate shortcuts.
emissions = out / 'canary-source'
emissions.mkdir()
for name, source in [('scalar', HERE.parent / 'phase29/fixture-mandelbrot.bend'),
                     ('row', ROOT / 'selfhost/build/phase31/local-data-source-01/row.bend')]:
    keep(source)
    command('emit-canary-' + name, ['taskset', '-c', '7', NODE, '--stack-size=4096',
            '--max-old-space-size=1024', HERE.parent / 'phase26/emit.mjs', attempt,
            source, emissions / (name + '.mjs')], 7, 120,
            'Checked acquisition only; receipt binds final attempt and source.')
keep(HERE / 'canary-plan.py')
command('prepare-canaries', [sys.executable, HERE / 'canary-plan.py', emissions / 'scalar.mjs',
        emissions / 'row.mjs', out / 'canary-plan'], None, 30, 'Unchanged scalar0/8192 and row32 points.')
command('measure-canaries', [sys.executable, OLD / 'prototype-time.py', out / 'canary-plan/confirm.json',
        out / 'canary-confirm'], 3, 600, 'Exclusive grant: maintained five-sample confirm protocol.')

# The retained frontend gate supports an exact prospective manifest descriptor.
old_tools = ROOT / 'selfhost/build/phase30/frontend-layout-tools16'
old_derive = json.loads((old_tools / 'derive.json').read_text())
gate = tools / 'frontend-gate.mjs'
keep(old_tools / 'gate.mjs', old_derive['output']['sha256'])
derive(old_tools / 'gate.mjs', gate, [
    ('jobs:4', 'jobs:1', 1),
    ('rssLimitMb:4096,heapMb:4096', 'rssLimitMb:1024,heapMb:1024', 1),
    ("'--jobs','4'", "'--jobs','1'", 1),
    ("'--rss-limit-mb','4096'", "'--rss-limit-mb','1024'", 1),
    ("'--heap-mb','4096'", "'--heap-mb','1024'", 1),
    ('--max-old-space-size=4096', '--max-old-space-size=1024', 1),
    ('assert.equal(r.workers.length,4)', 'assert.equal(r.workers.length,r===a?4:1)', 1),
])
keep(gate)
keep(old_tools / 'derive.json')
old_layout = json.loads((old_tools / 'migration.json').read_text())
keep(old_tools / 'migration.json', old_derive['migration']['sha256'])
before = ROOT / 'selfhost/build/phase23/frontend-main-01/selected/harness/src/compiler.json'
prior = baseline / 'snapshot/src/compiler.json'
after = Path(manifest['snapshot']['root']) / 'src/compiler.json'
a, b, c = (json.loads(p.read_text()) for p in [before, prior, after])
non = lambda x: {k: v for k, v in x.items() if k != 'modules'}
assert non(a) == non(b) == non(c) == old_layout['expectedNonModules']
assert len(a['modules']) == 60 and len(b['modules']) == 65 and len(c['modules']) == 66
assert a['modules'] == old_layout['before']['modules'] and b['modules'] == old_layout['after']['modules']
assert [x for x in c['modules'] if x not in b['modules']] == ['src/back/js/local.bend']
assert [x for x in c['modules'] if x != 'src/back/js/local.bend'] == b['modules']
assert len(set(c['modules'])) == 66
layout = dict(kind='explicit-compiler-module-layout-migration', expectedNonModules=non(a),
              before=dict(sha256=keep(before)['sha256'], modules=a['modules']),
              after=dict(sha256=keep(after)['sha256'], modules=c['modules']))
save(out / 'frontend-layout.json', layout)
keep(prior)
save(out / 'frontend-layout-audit.json', dict(complete=True, before=keep(before),
     phase30_17=keep(prior), after=keep(after), retainedMigration=keep(old_tools / 'migration.json'),
     addedSince17=['src/back/js/local.bend'], removedSince17=[], priorOrderPreserved=True,
     historicalStrictFailure=keep(ROOT / 'selfhost/build/phase30/frontend-renewal-plan-16/main/report.json')))
selection = ROOT / 'selfhost/build/phase22/context-group196-05/selection.json'
for scope in ['main', 'broader']:
    reference = ROOT / ('selfhost/build/phase23/frontend-' + scope + '-01')
    keep(reference / 'report.json')
    command('frontend-' + scope, [NODE, '--stack-size=4096', '--max-old-space-size=1024',
            gate, attempt, out / ('frontend-' + scope), scope, reference,
            selection if scope == 'broader' else '', out / 'frontend-layout.json'],
            '4', 1800, 'Fresh candidate, attested old reference; exact paths/fields and explicit66-module layout.',
            {'PHASE23_FRONTEND_CPU': '4'})
keep(selection)

# Pilot admission compares whole recorded outcomes, including eight established N/A.
old_backend = ROOT / 'selfhost/build/phase30/backend-renewal-plan-16/pilot.json'
history = ROOT / 'selfhost/build/phase30/backend-pilot-renewed-17/report.json'
p, h = json.loads(old_backend.read_text()), json.loads(history.read_text())
assert h['complete'] and h['agreementComplete'] and h['exactRows'] == 81
assert h['counts'] == {'pass': 69, 'not-applicable': 8, 'fail': 4}
assert len({(r['id'], r['lane']) for r in h['rows']}) == 81
backend = out / 'backend'
backend.mkdir()
fields = ['referenceVerdict', 'candidateVerdict', 'reference', 'candidate', 'exactAgreement', 'semanticAgreement']
historical_rows = [{k: r[k] for k in ['id', 'lane', *fields]} for r in h['rows']]
save(backend / 'historical-rows.json', historical_rows)
runner = derive(OLD / 'review-backend-renewal-run.py', tools / 'backend-run.py', [
    ('root=Path(__file__).resolve().parents[4]', 'root=Path(' + repr(str(ROOT)) + ')', 1),
    ("assert p['terminationGraceSeconds']==3", "assert p['terminationGraceSeconds']==3\nexpectedRows=json.loads(Path(p['historicalRows']['file']).read_text())\nexpectedByKey={(r['id'],r['lane']):r for r in expectedRows}\nassert len(expectedRows)==len(expectedByKey)==81\nobservedFields=" + repr(fields), 1),
    ("valid=row['exactAgreement'] and ((row['referenceVerdict']==row['candidateVerdict']=='fail' and row['reference']['phase']==row['candidate']['phase']=='check' and row['reference']['checked'] and row['candidate']['checked']) if shared else row['referenceVerdict']==row['candidateVerdict']=='pass')",
     "expectedRow=expectedByKey[(row['id'],row['lane'])]\n   valid=row['exactAgreement'] and row['semanticAgreement'] and all(row[k]==expectedRow[k] for k in observedFields)", 1),
])
backend_inputs = [keep(old_backend), keep(history), keep(backend / 'historical-rows.json'), keep(runner),
                  keep(attempt / 'attempt.json')]
# Only resource/path changes to the maintained paired census; fixture selection
# and exact historical admission remain unchanged. Reference/candidate acquisition
# in target.mjs already runs serially, and now each side uses one worker.
census = derive(HERE.parent / 'phase24/backend-census.py', tools / 'backend-census.py', [
    ('ROOT = Path(__file__).resolve().parents[4]', 'ROOT = Path(' + repr(str(ROOT)) + ')', 1),
    ("'jobs':4", "'jobs':1", 2),
    ("'heapMb':4096", "'heapMb':1024", 2),
    ("'rssLimitMb':4096", "'rssLimitMb':1024", 1),
    ("'3-6'", "'3'", 3),
    ("str(NODE),'--input-type=module'", "str(NODE),'--max-old-space-size=1024','--input-type=module'", 1),
    ("str(NODE),str(host/'tools/conformance/target.mjs')", "str(NODE),'--max-old-space-size=1024',str(host/'tools/conformance/target.mjs')", 1),
    ("env.update(frozen['environment']);env.update(", "env['NODE_OPTIONS']='--max-old-space-size=1024'\n    env.update(frozen['environment']);env.update(", 1),
])
backend_inputs.append(keep(census))
for entry in p['inputs']:
    backend_inputs.append(keep(entry['file'], entry['sha256']))
for entry in manifest['snapshot']['sources']:
    backend_inputs.append(keep(entry['frozen']['file'], entry['frozen']['sha256']))
for k in ['api', 'checkedApi', 'runtime', 'base', 'node', 'bootstrapReport']:
    backend_inputs.append(keep(manifest[k]['file'], manifest[k]['sha256']))
batches = []
for old in p['batches']:
    row = dict(old)
    row['output'] = str(backend / 'pilot' / old['name'])
    row['command'] = [*old['command'][:-2], row['output'], str(attempt)]
    row['command'][1] = str(census)
    batches.append(row)
assert {(c['id'], c['lanes'][0]) for b in batches for c in b['cases']} == {(r['id'], r['lane']) for r in historical_rows}
new_backend = {**p, 'attempt': keep(attempt / 'attempt.json'), 'inputs': backend_inputs,
               'cpu': '3', 'jobs': 1,
               'batches': batches, 'historicalRows': keep(backend / 'historical-rows.json'),
               'expectedCounts': h['counts'], 'policy': 'Fresh81 exact historical outcomes:69pass/8N/A/4sharedfail; no relabeling.'}
save(backend / 'pilot.json', new_backend)
command('backend-pilot', [sys.executable, runner, backend / 'pilot.json'], '3', 900,
        'Fresh81 rows with unchanged census selection/environment and exact historical-observation admission.')

# Inherited gates, release ownership and publication remain explicit commands.
frozen = ROOT / 'selfhost/build/phase30/final-integration-plan-17/launchers'
for mode in ['primitive', 'worker', 'nested', 'primitive-guards']:
    command('inherited-' + mode, [sys.executable, frozen / 'prototype-inherited-controls.py',
            attempt, mode, out / mode], 7, 300, 'Maintained assertions and independent references unchanged.')
command('upstream-selected', [sys.executable, HERE.parent / 'phase29/integration-upstream.py',
        attempt, out / 'upstream'], 4, 180, '15 exact JS probes; acquisition after CPU4 grant.')
command('corpus', [sys.executable, frozen / 'integration-corpus.py', attempt,
        ROOT / 'selfhost/build/phase25/corpus-01', out / 'corpus'], 7, 300, '23 libraries/127 points.')
keep(HERE / 'final-additional-plan.py')
command('prepare-additional-controls', [sys.executable, HERE / 'final-additional-plan.py',
        attempt, out / 'additional'], None, 30,
        'Freeze retained worker40+2, compiler component22 and complete HVM controls; no execution.')
command('release-install', [NODE, '--max-old-space-size=1024', ROOT / 'selfhost/tools/development/release.mjs', '--install-attempt', attempt],
        None, 180, 'Root-owned mutation after final admission and canonical snapshot identity check.')
command('release-verify', [NODE, '--max-old-space-size=1024', ROOT / 'selfhost/tools/development/release.mjs', '--verify'],
        None, 120, 'Root-owned installed release verification.')
smoke_worker = derive(HERE.parent / 'phase23/history-release-smoke.mjs', tools / 'release-smoke.mjs', [
    ('--max-old-space-size=4096', '--max-old-space-size=1024', 1),
])
smoke_launcher = derive(HERE.parent / 'phase23/history-release-smoke-launch.mjs', tools / 'release-smoke-launch.mjs', [
    ("from '../../development/workflow.mjs'", 'from ' + json.dumps(str(ROOT / 'selfhost/tools/development/workflow.mjs')), 1),
    ("from '../../development/process.mjs'", 'from ' + json.dumps(str(ROOT / 'selfhost/tools/development/process.mjs')), 1),
    ("path.join(import.meta.dirname,'history-release-smoke.mjs')", json.dumps(str(smoke_worker)), 1),
    ('--max-old-space-size=4096', '--max-old-space-size=1024', 1),
])
command('release-smoke', [NODE, '--max-old-space-size=1024', smoke_launcher,
        ROOT / 'selfhost', out / 'release-smoke', manifest['api']['sha256']], 1, 1200,
        'Root-owned42 ordinary/relocated CLI checks; pinned Clang16 and180s child limits;1024MiB child heaps.')
for p in [OLD / 'prototype-time.py', OLD / 'run.py', HERE.parent / 'phase29/compare.py',
          HERE.parent / 'phase29/execute.mjs', HERE.parent / 'phase26/emit.mjs',
          frozen / 'prototype-inherited-controls.py', frozen / 'integration-corpus.py',
          HERE.parent / 'phase29/integration-upstream.py',
          ROOT / 'selfhost/tools/development/release.mjs',
          HERE.parent / 'phase23/history-release-smoke-launch.mjs']:
    keep(p)
for row in inputs.values():
    assert ident(row['file']) == row
save(out / 'derivations.json', dict(complete=True, derivations=derivations))
save(out / 'plan.json', dict(kind='phase32-final-integration-plan', complete=True, executed=False,
     attempt=keep(attempt / 'attempt.json'), inputs=list(inputs.values()), commands=commands,
     ownerGates='Final-artifact local/private/native controls are separate mandatory owner receipts.',
     cpuPolicy='No acquisition until root grant; all gate workers serial with at most1024MiB Node heaps; root supervises process-tree RSS and host headroom. Timing never overlaps any producer.',
     limitations='Original three-case subset, historical H only, optional811JS deferred; no complete backend or fixed-point claim.'))
shutil.copyfile(Path(__file__), out / 'consumed-plan.py')
print(json.dumps(dict(complete=True, executed=False, out=str(out), commands=len(commands))))
