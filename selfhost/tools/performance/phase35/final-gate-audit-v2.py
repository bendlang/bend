#!/usr/bin/env python3
"""Audit Phase35 receipts; resolve only the pinned portable reference via frozen provenance."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import tarfile

ap = argparse.ArgumentParser()
ap.add_argument('plan_directory')
ap.add_argument('out')
ap.add_argument('--frontend-broader-report',
                help='Audit a separately preserved broader retry; all normal checks still apply.')
ap.add_argument('--backend-report')
ap.add_argument('--owner-controls')
ap.add_argument('--require-closed', action='store_true')
ap.add_argument('--post-install', action='store_true', help='Also require installed API and all 42 CLI checks.')
args = ap.parse_args()
base, out = Path(args.plan_directory).resolve(), Path(args.out).resolve()
out.mkdir(parents=True, exist_ok=False)
inputs, gates = {}, []
historical_resolutions = {}


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
    row = identity(entry.get('file', entry.get('path')))
    assert row['sha256'] == entry['sha256'], entry.get('file', entry.get('path'))
    return row


def read(file):
    identity(file)
    return json.loads(Path(file).read_text())


plan = read(base / 'plan.json')
assert plan['kind'] == 'phase35-final-integration-plan' and plan['complete'] and not plan['executed']
for entry in plan['inputs']:
    verify(entry)
verify(plan['layout'])
parent = Path(__file__).resolve().parent.parent / 'phase32/final-gate-audit.py'
assert identity(parent)['sha256'] == 'cc6da4e7c08acaa898304786e92b40a783b87842a9bf662ee65a4d4000d00ae3'
verify(plan['attempt'])
manifest = read(plan['attempt']['file'])
attempt = Path(plan['attempt']['file']).parent
api = manifest['api']['sha256']
identity(__file__)
original_audit = Path(__file__).with_name('final-gate-audit.py')
assert identity(original_audit)['sha256'] == '33f425d903d12bbd80f788e02c5cf84cd24559ea65e7eb403f77553fc1a3b87c'


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


def frontend(data, expected, name):
    assert data['scope'] == name
    assert data['api']['sha256'] == api
    assert any(x.get('file') == str(attempt / 'attempt.json') and
               x.get('sha256') == plan['attempt']['sha256'] for x in data['inputs'])
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
                candidateWorkers=1, heapMb=config['heapMb'], rssLimitMb=config['rssLimitMb'],
                explicitOverride=name == 'broader' and bool(args.frontend_broader_report))


for name, expected in [('main', 3026), ('broader', 196)]:
    report = (Path(args.frontend_broader_report).resolve()
              if name == 'broader' and args.frontend_broader_report
              else base / ('frontend-' + name) / 'report.json')
    audit('frontend-' + name, report,
          lambda data, expected=expected, name=name: frontend(data, expected, name))


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


def preserved_reference(file, bundle):
    """Resolve one exact frozen bundle, never arbitrary old-path mismatches.

    Absolute compiler locations in this archived installed-release declaration
    describe acquisition provenance. Verify their exact old bytes in the checked
    Phase32 snapshot; every live candidate edge keeps ordinary strict verification.
    """
    root = Path(__file__).resolve().parents[4]
    programs = root/'selfhost/tools/performance/programs'
    reference = programs/'baseline/manifest.json'
    if file != reference:
        return False
    assert identity(file)['sha256'] == 'e5f0af8ae01dbb38de2b4358fb7b19fb038a11e01b70702484f08660eefc4a08'
    if str(file) in historical_resolutions:
        return True
    catalog_file = programs/'catalog.json'
    assert identity(catalog_file)['sha256'] == '32833e4c2372983361b2c9f34a0967cfe38ce0e1052ac9abaab41def3179cfde'
    for name, expected in [
        ('run.py', '825f16ea085b2000595371a0b69bfc7c76b0630ae11079ae02480d7dac746a2e'),
        ('support.py', '36e000b43f92809e2de0bcdb462e6e42005fad7341f6ec2122734311073d1cef'),
        ('freeze-reference.py', 'f230fffbd70ea26e020b88520c94dceee71833b5054c72b5f753dca648f6e760')]:
        assert identity(programs/name)['sha256'] == expected
    # The maintained reader checks every selected source/point, role, module
    # hash, archive path/kind/size and expansion bound. Select the entire catalog.
    sys.path.insert(0, str(programs))
    from run import load_bundle
    catalog = read(catalog_file)
    loaded_inputs = []
    load_bundle(file, catalog, bundle['catalogSha256'], catalog['cases'],
                ['baseline', 'typescript'], loaded_inputs)
    for entry in loaded_inputs:
        verify(entry)
    assert bundle['archive']['sha256'] == '13df6cfedbdada8b40c3738a37993a50296cc2eca381e37b6a2d05ecd3845bca'
    provenance_file = reference.parent/bundle['provenance']['path']
    assert bundle['provenance']['sha256'] == 'b39ffab3fb0e790034905e1d43da9d88bc861f0012bc6335c7a7a8ef4421d499'
    assert identity(provenance_file)['sha256'] == bundle['provenance']['sha256']
    provenance = read(provenance_file)
    assert provenance['complete'] and provenance['kind'] == 'bend-program-frozen-reference-provenance'
    assert provenance['producer']['sha256'] == 'f230fffbd70ea26e020b88520c94dceee71833b5054c72b5f753dca648f6e760'
    assert provenance['adapterProducer']['sha256'] == 'a4fe845741f7ab99c5c18431e8c0fbb4f9e8ccddf605f303a8ef865335a79325'
    archived_expected = {
        'provenance.json': bundle['provenance']['sha256'],
        'consumed/freeze-reference.py': provenance['producer']['sha256'],
        'baseline/consumed/prepare.py': provenance['adapterProducer']['sha256'],
        'typescript/consumed/prepare.py': provenance['adapterProducer']['sha256'],
        **{role+'/preparation.json': entry['sha256'] for role, entry in provenance['preparations'].items()}}
    archived_seen = set()
    with tarfile.open(reference.parent/bundle['archive']['path'], 'r:gz') as archive:
        for member in archive:
            if member.name in archived_expected:
                assert member.isfile() and member.name not in archived_seen
                digest = hashlib.sha256()
                with archive.extractfile(member) as stream:
                    for chunk in iter(lambda: stream.read(2**20), b''):
                        digest.update(chunk)
                assert digest.hexdigest() == archived_expected[member.name], member.name
                archived_seen.add(member.name)
    assert archived_seen == set(archived_expected)

    historical_file = root/'selfhost/build/phase32/attempt-03/attempt.json'
    assert identity(historical_file)['sha256'] == '9bf0c842144cc1a1eac7993e88dcf13f31d7d854c3c977cbd4d89f435163e644'
    historical = read(historical_file)
    assert historical['checked'] and historical['config']['strictExact']
    old = bundle['roles']['baseline']['compiler']
    assert old['kind'] == 'installed-checked-release'
    assert old['api']['sha256'] == historical['api']['sha256'] == '8be506d811f627fe6346a5eaba07050c36db70e2704608adcfd781b85a3a7f92'
    assert old['upstreamCommit'] == catalog['upstreamCommit'] == '018751270e800bc222a93dad7f257083ee53a5f7'
    assert Path(historical['config']['upstream']) == root/'selfhost/.bootstrap/upstream-phase23'
    snapshots = historical['snapshot']['sources']
    for entry in snapshots:
        assert entry['original']['sha256'] == entry['frozen']['sha256']
        verify(entry['frozen'])
    for key in ['api', 'checkedApi', 'runtime', 'base', 'bootstrapReport', 'derivationReport']:
        verify(historical[key])
    bootstrap = read(historical['bootstrapReport']['file'])
    assert bootstrap['sourceSha256'] == old['sourceSha256'] == 'e3cc44245444ac2509431d44c8909692c9223cd977968ffb087771c1ae2859ae'
    source = next(entry for entry in historical['artifacts']
                  if entry['file'].endswith('/compiler.bend') and entry['sha256'] == old['sourceSha256'])
    verify(source)
    bindings = []
    for key in ['api', 'runtime', 'base', 'driver']:
        declared = old[key]
        if key == 'driver':
            match = [entry for entry in snapshots if entry['original']['file'] == declared['file']
                     and entry['original']['sha256'] == declared['sha256']]
            assert len(match) == 1
            frozen = match[0]['frozen']
        else:
            frozen = historical[key]
        assert frozen['sha256'] == declared['sha256']
        if key == 'runtime':
            assert any(entry['original']['file'] == declared['file'] and
                       entry['original']['sha256'] == declared['sha256'] and
                       entry['frozen']['file'] == frozen['file'] for entry in snapshots)
        bindings.append(dict(component=key, historicalDeclaration=declared, verifiedFrozen=verify(frozen)))
    # These pinned upstream sources remain real inputs, not historical aliases.
    for entry in bundle['roles']['typescript']['compiler']['sources']:
        verify(entry)
    historical_resolutions[str(file)] = dict(reference=identity(file), archive=identity(reference.parent/bundle['archive']['path']),
        provenance=identity(provenance_file), historicalAttempt=identity(historical_file),
        frozenSourceCount=len(snapshots), archivedProducerAndReceiptHashes=archived_expected,
        bindings=bindings, scope='Only this exact reference declaration resolves historical compiler paths. No final candidate edge is remapped.')
    return True


def owner_group(child_file):
    # Follow only identity-bearing edges recorded by the tested report and its
    # acquisition/cohort receipts. An unrelated final API file in an external
    # owner manifest does not bind an earlier report to the selected compiler.
    visited, queue, checked_outputs = set(), [Path(child_file)], []
    bound_api, bound_attempt = False, False
    while queue:
        file = queue.pop().resolve()
        if file in visited:
            continue
        visited.add(file)
        assert len(visited) <= 4096, 'owner provenance graph unexpectedly large'
        doc = read(file)
        if preserved_reference(file, doc):
            continue
        if isinstance(doc, dict) and doc.get('complete') and doc.get('observation', {}).get('checked'):
            compiler = doc.get('compiler', doc)
            if compiler.get('api', {}).get('sha256') == api:
                assert doc['attempt']['sha256'] == plan['attempt']['sha256']
                verify(doc['output'])
                checked_outputs.append(doc['output'])
        def edges(value):
            nonlocal bound_api, bound_attempt
            if isinstance(value, dict):
                if isinstance(value.get('file', value.get('path')), str) and value.get('sha256') and Path(value.get('file', value.get('path'))).is_absolute():
                    row = verify(value)
                    bound_api = bound_api or row['sha256'] == api
                    bound_attempt = bound_attempt or (row['file'] == str(attempt/'attempt.json') and row['sha256'] == plan['attempt']['sha256'])
                    if Path(row['file']).suffix == '.json' and Path(row['file']).name != 'attempt.json' and Path(row['file']) not in visited:
                        queue.append(Path(row['file']))
                for item in value.values():
                    edges(item)
            elif isinstance(value, list):
                for item in value:
                    edges(item)
        edges(doc)
    assert bound_api and bound_attempt, 'owner report does not reach selected checked API and attempt'
    return dict(provenanceReports=len(visited), checkedFinalOutputs=len(checked_outputs))


def local(data):
    assert data['attempt']['sha256'] == plan['attempt']['sha256']
    assert data['api']['sha256'] == api
    required = plan['ownerGates']
    assert len(required) == len(set(required))
    assert sorted(row['name'] for row in data['cases']) == sorted(required)
    observations = []
    for row in data['cases']:
        assert row['returncode'] == 0
        reports = row.get('reports', [row.get('report')])
        assert reports and all(reports)
        accepted = []
        for report in reports:
            verify(report)
            child = read(report['file'])
            assert child['complete'] and child['pass'] and not child.get('error')
            assert not child.get('changedInputs')
            accepted.append(owner_group(report['file']))
        observations.append(dict(name=row['name'], reports=accepted))
    return dict(groups=len(required), groupsPassed=required, finalImageProvenance=observations)


owner = Path(args.owner_controls).resolve() if args.owner_controls else base/'owner/report.json'
audit('phase35-owner-controls', owner, local)


def cli(data):
    assert data['expectedApi'] == api and data['steps'] == 42 and data['cpu'] == 3
    verify(data['checks'])
    checks = read(data['checks']['file'])
    assert checks['pass'] and checks['apiSha256'] == api and len(checks['steps']) == 42
    assert checks['actualCpu'] == '3' and checks['cpu'] == 3
    assert all(s['pass'] and not s.get('error') and not s.get('signal') and
               not s.get('timedOut') and not s.get('overflow') for s in checks['steps'])
    installed = Path(manifest['config']['project'])/'dist/typed-api.mjs'
    assert identity(installed)['sha256'] == api
    return dict(checks=42, installedApi=api)


if args.post_install:
    audit('installed-ordinary-relocated-cli', base/'release-smoke/launcher.json', cli)

# Production-source equality is independent of the scoped execution gates.
canonical = dict(accepted=False, changes=[])
try:
    assert manifest['checked'] and manifest['config']['strictExact']
    assert str(manifest['config']['cpu']) == '3'
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
result = dict(kind='phase35-final-gate-closure', complete=closed, **{'pass': closed},
    attempt=plan['attempt'], api=manifest['api'], gates=gates, canonicalSource=canonical,
    inputs=list(inputs.values()), postInstallChecked=args.post_install, parentAssertionProducer=identity(parent),
    originalPhase35Audit=identity(original_audit), historicalReferenceResolutions=list(historical_resolutions.values()),
    postInstallRequired=['release-install', 'release-verify', '42 ordinary/relocated CLI checks'],
    separateRequiredDecisions=['measurement completeness and regression admission', 'independent release review'],
    scope='Fresh correctness receipts plus exact canonical-source identity. Counts overlap; '
          'shared historical failures remain failures. This audit executes nothing and '
          'does not establish performance admission, installation, a fixed point or GPU conformance.')
(out / 'gates.json').write_text(json.dumps(result, indent=2) + '\n')
lines = ['# Phase35 final gate closure', '',
         'Correctness closure: ' + ('PASS.' if closed else 'INCOMPLETE; see outstanding receipts below.'), '',
         '| Gate | Status | Observed scope |', '|---|---|---|']
for gate in gates:
    observed = {key: value for key, value in gate.items() if key in [
        'probes', 'exact', 'statuses', 'counts', 'totalScalarChecks', 'scalarChecks',
        'checks', 'guards', 'observations', 'libraries', 'points', 'executionWitnesses',
        'stdoutBytes', 'groups', 'candidateWorkers', 'heapMb', 'rssLimitMb']}
    lines.append(f'| {gate["name"]} | {gate["status"]} | {json.dumps(observed, separators=(",", ":")) if observed else "Unrun or incomplete"} |')
lines += ['', 'Canonical source: ' + ('matches the checked attempt.' if canonical['accepted'] else 'not admitted.'), '',
          'A broader-report override selects a separately preserved retry receipt; it does not '
          'relax scope, checked-attempt identity, exact agreement, worker health or memory checks. ', '',
          'Fresh frontend/backend workers are serial with 1024 MiB V8 heap allowances and 4 MiB stacks. '
          'Heap limits are not RSS limits; root supervises process-tree memory separately. '
          'Retained reference acquisitions keep their original resource provenance.', '',
          'Installation, installed verification and 42 CLI checks remain separate post-install actions. '
          'Measurement/regression admission and independent release review remain separate decisions. '
          'All missing/invalid reports and exact errors are retained in gates.json.', '']
(out / 'gates.md').write_text('\n'.join(lines))
print(json.dumps(dict(complete=closed, accepted=sum(g['accepted'] for g in gates), total=len(gates),
                     outstanding=[g for g in gates if not g['accepted']], canonicalSource=canonical)))
if args.require_closed and not closed:
    raise SystemExit(1)
