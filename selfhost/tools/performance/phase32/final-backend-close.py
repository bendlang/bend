#!/usr/bin/env python3
"""Audit 60 retained pilot rows plus 21 authorized native retry rows; run no tests."""
from pathlib import Path
import hashlib, json, shutil, sys

original_file, retry_plan_file, retry_dir, outer_dir, out = (Path(x).resolve() for x in sys.argv[1:])
out.mkdir(parents=True, exist_ok=False)


def ident(file):
    file = Path(file).resolve()
    digest = hashlib.sha256()
    with file.open('rb') as stream:
        for chunk in iter(lambda: stream.read(2**20), b''):
            digest.update(chunk)
    return dict(file=str(file), sha256=digest.hexdigest(), bytes=file.stat().st_size)


inputs = {}


def keep(file, digest=None):
    row = ident(file)
    if digest:
        assert row['sha256'] == digest, str(file)
    inputs[row['file']] = row
    return row


def read(file):
    keep(file)
    return json.loads(file.read_text())


parent = Path(__file__).resolve().parent.parent / 'phase31/final-backend-close.py'
parent_identity = keep(parent, 'd7fb7ab429c7fadb022cb9976e6bb86481a2de517f98d4496795901b0b8e3a54')
original = read(original_file)
retry_plan = read(retry_plan_file)
retry = read(retry_dir / 'report.json')
outer = read(outer_dir / 'run.json')
config = read(retry_dir / 'config.json')
assert original['complete'] and not original.get('error')
assert not original['agreementComplete'] and len(original['rows']) == 81
assert retry_plan['complete'] and not retry_plan['executed']
assert outer['complete'] and outer['returncode'] == 0 and 'stoppedFor' not in outer
assert outer['command'] == retry_plan['childCommand']
assert outer['rssLimitBytes'] == 3072 * 1024**2
assert outer['availableFloorBytes'] == 2048 * 1024**2
assert 1 <= outer['secondsLimit'] <= 480
keep(outer['producer']['file'], outer['producer']['sha256'])
keep(outer_dir / 'consumed-bounded-run.py', outer['producer']['sha256'])
assert retry['complete'] and retry['pass'] and not retry.get('error')
assert retry['changedInputs'] == [] and len(retry['rows']) == 21
assert config['jobs'] == 1 and 0 < config['heapMb'] <= 1024
assert 0 < config['rssLimitMb'] <= 1024 and config['stackKb'] == 4096
attempt = original['attempt']
keep(attempt['file'], attempt['sha256'])
assert any(i.get('file') == attempt['file'] and i.get('sha256') == attempt['sha256']
           for i in retry['inputs'])
assert any(i.get('file') == attempt['file'] and i.get('sha256') == attempt['sha256']
           for i in retry_plan['inputs'])

fields = ['referenceVerdict', 'candidateVerdict', 'reference', 'candidate',
          'exactAgreement', 'semanticAgreement']


def canonical(row):
    return json.dumps({key: row[key] for key in fields}, sort_keys=True, separators=(',', ':'))


expected = {(row['id'], row['lane']): row for row in retry_plan['expectedRows']}
assert len(retry_plan['expectedRows']) == len(expected) == 21
for row in retry['rows']:
    assert row['exactAgreement'] and row['semanticAgreement']
    assert canonical(row) == canonical(expected.pop((row['id'], row['lane'])))
assert not expected
retained = [row for row in original['rows'] if row['batch'] != 'pilot-native']
excluded = [row for row in original['rows'] if row['batch'] == 'pilot-native']
assert len(retained) == 60 and len(excluded) == 21
assert all(row['acceptedCampaignObservation'] for row in retained)
rejected = [row for row in excluded if not row['acceptedCampaignObservation']]
assert len(rejected) == 17
for row in rejected:
    assert row['lane'] == 'native'
    assert row['referenceVerdict'] == row['candidateVerdict'] == 'fail'
    for side in ['reference', 'candidate']:
        result = row[side]
        assert result['status'] == 'error' and result['phase'] == 'compile'
        assert result['diagnostic'] == 'spawnSync ' + retry['environment']['CC'] + ' EPERM'

for step in original['steps']:
    keep(step['receipt']['file'], step['receipt']['sha256'])
for directory in [*[Path(step['receipt']['file']).parent for step in original['steps']], retry_dir]:
    archive = read(directory / 'archive.json')
    assert archive['verifiedFiles'] > 0 and archive['verifiedFiles'] == len(archive['files'])
    keep(archive['archive']['file'], archive['archive']['sha256'])
for source in [outer, retry, original, retry_plan]:
    for item in source.get('inputs', []):
        keep(item['file'], item['sha256'])

rows = [{**row, 'acquisitionGroup': 'original-first-six-batches'} for row in retained]
rows += [{**row, 'batch': 'pilot-native', 'acquisitionGroup': 'approved-context-native21-retry',
          'acceptedCampaignObservation': True} for row in retry['rows']]
assert len(rows) == len({(row['id'], row['lane']) for row in rows}) == 81
counts = {verdict: sum(row['candidateVerdict'] == verdict for row in rows)
          for verdict in ['pass', 'not-applicable', 'fail']}
assert counts == {'pass': 69, 'not-applicable': 8, 'fail': 4}
keep(Path(__file__))
for item in inputs.values():
    assert ident(item['file']) == item
report = dict(kind='phase32-final03-backend-pilot-consolidation', complete=True, agreementComplete=True,
    attempt=attempt, inputs=list(inputs.values()), rows=rows, exactRows=81, counts=counts,
    parentProducer=parent_identity,
    producerAdaptation='Phase31 row, archive and input checks retained. Phase32 bounded supervisor '
        'fields replace legacy outer changedInputs/timeout; frozen plan inputs are still rehashed. '
        'Exact retry command, single-worker resource config and paired Clang EPERM cause are required.',
    retainedRows=60, retriedRows=21, failedDefaultCampaign=ident(original_file),
    retry=ident(retry_dir / 'report.json'), retryOuter=ident(outer_dir / 'run.json'),
    failedDefaultRows=excluded,
    resources=dict(jobs=config['jobs'], heapMb=config['heapMb'], rssLimitMb=config['rssLimitMb'],
        treeRssLimitBytes=outer['rssLimitBytes'], availableFloorBytes=outer['availableFloorBytes'],
        secondsLimit=outer['secondsLimit'], peakTreeRssBytes=outer['peakTreeRssBytes']),
    scope='60 accepted rows from the first six default-context batches plus 21 native rows from '
        'a separately authorized execution-context retry. The raw default campaign remains failed; '
        'this is not one successful 81-row execution or broad native conformance. Approval is an '
        'external execution fact, not established by this receipt or its provenance labels.')
(out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
shutil.copyfile(Path(__file__), out / 'consumed-close.py')
print(json.dumps(dict(complete=True, agreementComplete=True, exactRows=81, counts=counts)))
