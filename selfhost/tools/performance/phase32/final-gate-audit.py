#!/usr/bin/env python3
"""Audit pre-install correctness receipts; never run gates or install a release."""
import argparse
import hashlib
import json
from pathlib import Path

ap = argparse.ArgumentParser()
ap.add_argument('plan_directory')
ap.add_argument('out')
ap.add_argument('--backend-report')
ap.add_argument('--owner-controls')
ap.add_argument('--require-closed', action='store_true')
args = ap.parse_args()
base, out = Path(args.plan_directory).resolve(), Path(args.out).resolve()
out.mkdir(parents=True, exist_ok=False)
inputs, gates = {}, []


def identity(file):
    file = Path(file).resolve()
    digest = hashlib.sha256()
    with file.open('rb') as stream:
        for chunk in iter(lambda: stream.read(2**20), b''):
            digest.update(chunk)
    row = dict(file=str(file), sha256=digest.hexdigest(), bytes=file.stat().st_size)
    inputs[str(file)] = row
    return row


def verify(entry):
    row = identity(entry['file'])
    assert row['sha256'] == entry['sha256'], entry['file']
    return row


def read(file):
    identity(file)
    return json.loads(Path(file).read_text())


plan = read(base / 'plan.json')
verify(plan['attempt'])
manifest = read(plan['attempt']['file'])
attempt = Path(plan['attempt']['file']).parent
api = manifest['api']['sha256']
identity(__file__)


def audit(name, file, callback):
    row = dict(name=name, expectedReport=str(file), accepted=False, status='not-recorded')
    gates.append(row)
    if not Path(file).exists():
        return
    try:
        data = read(file)
        row['report'] = identity(file)
        assert data['complete'], 'receipt incomplete'
        assert not data.get('error'), data.get('error')
        if 'pass' in data:
            assert data['pass'], 'receipt failed'
        for entry in data.get('inputs', []):
            if isinstance(entry, dict) and 'file' in entry and 'sha256' in entry:
                verify(entry)
        row.update(callback(data))
        row.update(accepted=True, status='passed')
    except Exception as error:
        row.update(status='incomplete-or-invalid', error=repr(error))


def focused(data):
    assert data['api']['sha256'] == api
    assert data['strictExact'] and data['selected']['selectedComplete']
    assert data['selected']['exactDifferences'] == 0
    assert data['selected']['candidate']['probes'] == 36
    return dict(probes=36, exactDifferences=0)


audit('checked-build-focused', attempt / 'validation-001/report.json', focused)


def frontend(data, expected):
    assert data['api']['sha256'] == api
    assert data['healthPass'] and data['exactAgreement']
    assert data['exact'] == data['expected'] == expected
    assert data['differences'] == data['extraFieldDifferences'] == 0
    verify(data['candidate'])
    candidate = read(data['candidate']['file'])
    assert candidate['identity']['artifacts']['compiler']['sha256'] == api
    assert len(candidate['workers']) == 1 and len(candidate['results']) == expected
    for worker in candidate['workers']:
        assert worker['errors'] == []
        assert worker['stats']['timeouts'] == worker['stats']['failures'] == 0
    config = read(Path(data['candidate']['file']).parent / 'target.json')
    assert config['jobs'] == 1 and config['heapMb'] <= 1024 and config['rssLimitMb'] <= 1024
    return dict(exact=expected, statuses=data['raw']['candidateSummary']['statuses'],
                candidateWorkers=1, heapMb=config['heapMb'], rssLimitMb=config['rssLimitMb'])


for name, expected in [('main', 3026), ('broader', 196)]:
    audit('frontend-' + name, base / ('frontend-' + name) / 'report.json',
          lambda data, expected=expected: frontend(data, expected))


def backend(data):
    assert data['agreementComplete'] and data['exactRows'] == 81
    assert (data.get('attempt', {}).get('sha256') == plan['attempt']['sha256'] or
            any(x.get('sha256') == plan['attempt']['sha256'] for x in data['inputs']))
    assert len(data['rows']) == 81
    expected = read(base / 'backend/historical-rows.json')
    by_key = {(r['id'], r['lane']): r for r in expected}
    assert len(by_key) == 81
    fields = ['referenceVerdict', 'candidateVerdict', 'reference', 'candidate',
              'exactAgreement', 'semanticAgreement']
    for row in data['rows']:
        before = by_key.pop((row['id'], row['lane']))
        assert row['acceptedCampaignObservation']
        assert all(row[field] == before[field] for field in fields)
    assert not by_key
    counts = {name: sum(r['candidateVerdict'] == name for r in data['rows'])
              for name in ['pass', 'not-applicable', 'fail']}
    assert counts == {'pass': 69, 'not-applicable': 8, 'fail': 4}
    return dict(exact=81, counts=counts, explicitOverride=bool(args.backend_report),
                scope=data.get('scope'), retainedRows=data.get('retainedRows'),
                retriedRows=data.get('retriedRows'))


audit('backend-pilot', Path(args.backend_report).resolve() if args.backend_report else
      base / 'backend/pilot/report.json', backend)


def inherited(data, name):
    assert any(x.get('file') == str(attempt / 'attempt.json') and
               x.get('sha256') == plan['attempt']['sha256'] for x in data['inputs'])
    obs = data['observation']
    assert obs['complete'] and obs['pass']
    assert not obs.get('changedInputs')
    key, expected = {'primitive': ('totalScalarChecks', 56205), 'worker': ('scalarChecks', 3759),
                     'nested': ('checks', 144), 'primitive-guards': ('guards', 1129)}[name]
    count = len(obs[key]) if isinstance(obs[key], list) else obs[key]
    assert count == expected
    return {key: count, 'observations': len(obs['observations']) if 'observations' in obs else None}


for name in ['primitive', 'worker', 'nested', 'primitive-guards']:
    audit(name, base / name / 'report.json', lambda data, name=name: inherited(data, name))


def upstream(data):
    assert data['api']['sha256'] == api and data['strictExact']
    assert data['selected']['selectedComplete'] and data['selected']['exactDifferences'] == 0
    assert data['selected']['candidate']['probes'] == 15
    return dict(probes=15, exactDifferences=0)


audit('upstream-selected', base / 'upstream/report.json', upstream)


def corpus(data):
    assert len(data['cases']) == 23 and data['observations'] == 127
    for case in data['cases']:
        assert case['emission']['complete'] and case['execution']['complete']
        emission = case['emission']['result']
        assert emission['complete'] and emission['observation']['checked']
        assert emission['attempt']['sha256'] == plan['attempt']['sha256']
        assert case['execution']['result']['complete']
    return dict(libraries=23, points=127)


audit('corpus', base / 'corpus/report.json', corpus)


def worker_admission(data):
    assert any(x.get('sha256') == api for x in data['inputs'])
    assert len(data['guards']) == 40 and len(data['observations']) == 2
    assert not data.get('changedInputs')
    return dict(guards=40, executionWitnesses=2)


audit('worker-admission', base / 'additional/worker-admission/report.json', worker_admission)


def component(data):
    assert data['attempt']['sha256'] == plan['attempt']['sha256']
    assert data['emission']['complete'] and data['check']['complete']
    result = data['check']['result']
    assert len(result['results']) == 1 and result['results'][0]['pass']
    assert len(result['results'][0]['observations']) == 22
    return dict(observations=22)


audit('component', base / 'additional/component/report.json', component)


def hvm(data):
    assert data['attempt']['sha256'] == plan['attempt']['sha256']
    assert data['emission']['complete'] and data['execution']['complete']
    assert data['exactStdout'] and data['emptyStderr']
    assert data['actualStdout'] == data['expectedStdout']
    assert len(data['actualStdout'].encode()) == 42
    return dict(exactStdout=True, emptyStderr=True, stdoutBytes=42)


audit('hvm', base / 'additional/hvm/report.json', hvm)


def local(data):
    assert [r['name'] for r in data['cases']] == ['pair', 'fold', 'order', 'scope', 'vectors', 'types']
    for row in data['cases']:
        assert row['returncode'] == 0
        verify(row['report'])
        child = read(row['report']['file'])
        assert child['complete'] and child['pass']
        for entry in child['inputs']:
            verify(entry)
        if row['name'] == 'types':
            assert any(x.get('sha256') == api for x in child['inputs'])
            assert any(x.get('sha256') == plan['attempt']['sha256'] for x in child['inputs'])
    return dict(groups=6, groupsPassed=[r['name'] for r in data['cases']])


owner = Path(args.owner_controls).resolve() if args.owner_controls else base.parent / 'local-checked-controls-03/report.json'
audit('local-owner-controls', owner, local)

# Production-source equality is independent of the scoped execution gates.
canonical = dict(accepted=False, changes=[])
try:
    assert manifest['checked'] and manifest['config']['strictExact']
    assert manifest['config']['jobs'] == 1 and manifest['config']['heapMb'] <= 1024
    for key in ['api', 'checkedApi', 'runtime', 'base', 'bootstrapReport']:
        verify(manifest[key])
    for entry in manifest['snapshot']['sources']:
        verify(entry['frozen'])
        original = identity(entry['original']['file'])
        if original['sha256'] != entry['original']['sha256']:
            canonical['changes'].append(original)
    assert not canonical['changes'], 'canonical source differs from checked attempt'
    canonical.update(accepted=True, snapshotSources=len(manifest['snapshot']['sources']))
except Exception as error:
    canonical['error'] = repr(error)
closed = canonical['accepted'] and all(g['accepted'] for g in gates)
result = dict(kind='phase32-preinstall-gate-closure', complete=closed, **{'pass': closed},
    attempt=plan['attempt'], api=manifest['api'], gates=gates, canonicalSource=canonical,
    inputs=list(inputs.values()), postInstallRequired=['release-install', 'release-verify', '42 ordinary/relocated CLI checks'],
    separateRequiredDecisions=['measurement completeness and regression admission', 'independent release review'],
    scope='Fresh correctness receipts plus exact canonical-source identity. Counts overlap; '
          'shared historical failures remain failures. This audit executes nothing and '
          'does not establish performance admission, installation, a fixed point or GPU conformance.')
(out / 'gates.json').write_text(json.dumps(result, indent=2) + '\n')
lines = ['# Phase32 pre-install gate closure', '',
         'Correctness closure: ' + ('PASS.' if closed else 'INCOMPLETE; see outstanding receipts below.'), '',
         '| Gate | Status | Observed scope |', '|---|---|---|']
for gate in gates:
    observed = {key: value for key, value in gate.items() if key in [
        'probes', 'exact', 'statuses', 'counts', 'totalScalarChecks', 'scalarChecks',
        'checks', 'guards', 'observations', 'libraries', 'points', 'executionWitnesses',
        'stdoutBytes', 'groups', 'candidateWorkers', 'heapMb', 'rssLimitMb']}
    lines.append(f'| {gate["name"]} | {gate["status"]} | {json.dumps(observed, separators=(",", ":")) if observed else "Unrun or incomplete"} |')
lines += ['', 'Canonical source: ' + ('matches the checked attempt.' if canonical['accepted'] else 'not admitted.'), '',
          'Fresh frontend/backend workers are serial with1024MiB V8 heap allowances and4MiB stacks. '
          'Heap limits are not RSS limits; root supervises process-tree memory separately. '
          'Retained reference acquisitions keep their original resource provenance.', '',
          'Installation, installed verification and42CLI checks remain separate post-install actions. '
          'Measurement/regression admission and independent release review remain separate decisions. '
          'All missing/invalid reports and exact errors are retained in gates.json.', '']
(out / 'gates.md').write_text('\n'.join(lines))
print(json.dumps(dict(complete=closed, accepted=sum(g['accepted'] for g in gates), total=len(gates),
                     outstanding=[g for g in gates if not g['accepted']], canonicalSource=canonical)))
if args.require_closed and not closed:
    raise SystemExit(1)
