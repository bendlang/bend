#!/usr/bin/env python3
"""Reuse27 audited rows, acquire54 unchanged runtime-dependent pilot rows."""
from pathlib import Path
import hashlib, json, os, signal, subprocess, sys, time

old_plan_file, attempt, audit_file, out = (Path(x).resolve() for x in sys.argv[1:])
root = Path(__file__).resolve().parents[4]
p = json.loads(old_plan_file.read_text())
audit = json.loads(audit_file.read_text())
assert p['campaign'] == 'pilot' and p['expectedRows'] == 81
assert attempt.name == 'attempt-17' and audit['complete'] and audit['pass']
out.mkdir(exist_ok=False)
inputs = {}

def ident(file):
    file = Path(file).resolve()
    data = file.read_bytes()
    return {'file': str(file), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}

def retain(file, expected=None):
    x = ident(file)
    if expected is not None:
        assert x['sha256'] == expected, str(file)
    inputs[x['file']] = x
    return x

def verify():
    for x in inputs.values():
        assert ident(x['file']) == x, x['file']

for file in [old_plan_file, audit_file, Path(__file__), root / 'design/phase30/registration-flag-backend-renewal.md', attempt / 'attempt.json']:
    retain(file)
for x in p['inputs'] + audit['inputs']:
    retain(x['file'], x['sha256'])
m = json.loads((attempt / 'attempt.json').read_text())
for key in ['api', 'checkedApi', 'base', 'runtime', 'node']:
    retain(m[key]['file'], m[key]['sha256'])
assert audit['runtimeAfter']['sha256'] == m['runtime']['sha256']
assert audit['unchanged']['api'] == m['api']['sha256']
selected = [x for x in audit['reusedReceipts'] if x['kind'] == 'backend-native-check']
assert len(selected) == 1
reused = selected[0]['selected']['rows']
assert len(reused) == 27 and all(x['lane'] in ['check', 'native'] for x in reused)
historical = {}
for index in range(1, 8):
    file = root / f'selfhost/build/phase24/backend-candidate-pilot-{index:02d}/report.json'
    retain(file)
    d = json.loads(file.read_text())
    assert d['complete'] and not d.get('error')
    for row in d['rows']:
        key = (row['id'], row['lane'])
        assert key not in historical
        historical[key] = row
assert len(historical) == 81
keys = ['referenceVerdict', 'candidateVerdict', 'reference', 'candidate', 'exactAgreement', 'semanticAgreement']
same = lambda x: json.dumps(x, sort_keys=True, separators=(',', ':'))

def compare(rows):
    seen = set()
    for row in rows:
        key = (row['id'], row['lane'])
        assert key not in seen
        seen.add(key)
        ref = historical[key]
        assert row['exactAgreement'] and row['semanticAgreement']
        assert same({k: row[k] for k in keys}) == same({k: ref[k] for k in keys}), key
    return seen

compare(reused)
batches = []
for index in [1, 2, 4, 5]:
    old = p['batches'][index]
    command = list(old['command'])
    assert command[-2] == old['output']
    destination = out / f'batch-{index}'
    command[-2], command[-1] = str(destination), str(attempt)
    assert all(case['lanes'] in [['interpreter'], ['js']] for case in old['cases'])
    batches.append({'index': index, 'name': old['name'], 'cases': old['cases'], 'command': command, 'output': str(destination)})
assert sum(len(x['cases']) for x in batches) == 54
plan = {'kind': 'phase30-registration-flag-backend-renewal-plan', 'complete': True, 'executed': False,
        'inputs': list(inputs.values()), 'audit': ident(audit_file), 'attempt': ident(attempt / 'attempt.json'),
        'reusedRows': 27, 'freshRows': 54, 'batches': batches, 'outerTimeoutSeconds': 450,
        'terminationGraceSeconds': 3, 'expectedCounts': {'pass': 69, 'not-applicable': 8, 'fail': 4}}
(out / 'plan.json').write_text(json.dumps(plan, indent=2) + '\n')
(out / 'consumed-runner.py').write_bytes(Path(__file__).read_bytes())
report = {'kind': 'phase30-registration-flag-backend-renewal', 'complete': False,
          'agreementComplete': False, 'plan': ident(out / 'plan.json'), 'inputs': list(inputs.values()),
          'reusedRows': reused, 'rows': list(reused), 'freshRows': [], 'steps': [], 'incompleteBatchRows': [],
          'neverStarted': [case for batch in batches for case in batch['cases']],
          'scope': 'Fresh17 interpreter/JS54 plus explicitly reused16 native/check27; complete historical observations, not81 new executions or full backend conformance.'}

def save():
    (out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')

def stop(process):
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    try:
        process.wait(timeout=3)
    except subprocess.TimeoutExpired:
        pass
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    process.wait()

process = None
start = time.monotonic()
save()
try:
    verify()
    env = {k: v for k, v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS', 'NODE_PATH']}
    for batch in batches:
        remaining = 450 - (time.monotonic() - start)
        assert remaining > 0, 'Overall deadline reached before next batch'
        report['incompleteBatchRows'] = batch['cases']
        report['neverStarted'] = report['neverStarted'][len(batch['cases']):]
        step = {'name': batch['name'], 'command': batch['command'], 'complete': False}
        report['steps'].append(step)
        save()
        stdout, stderr = out / (batch['name'] + '.stdout'), out / (batch['name'] + '.stderr')
        with stdout.open('x') as a, stderr.open('x') as b:
            process = subprocess.Popen(batch['command'], cwd=root, env=env, stdout=a, stderr=b, start_new_session=True)
            try:
                code = process.wait(timeout=max(.1, remaining))
            except subprocess.TimeoutExpired:
                step['timeout'] = True
                stop(process)
                code = process.returncode
        step.update(exitCode=code, stdout=ident(stdout), stderr=ident(stderr))
        receipt = Path(batch['output']) / 'report.json'
        if receipt.exists():
            d = json.loads(receipt.read_text())
            step['receipt'] = retain(receipt)
            fresh = d.get('rows', [])
            report['freshRows'].extend(fresh)
            report['rows'].extend(fresh)
            observed = {(row['id'], row['lane']) for row in fresh}
            report['incompleteBatchRows'] = [case for case in batch['cases'] if (case['id'], case['lanes'][0]) not in observed]
        save()
        assert code == 0 and not step.get('timeout') and receipt.exists()
        assert d['complete'] and not d.get('error') and d['changedInputs'] == []
        archive_file = receipt.parent / 'archive.json'
        archive = json.loads(archive_file.read_text())
        assert archive['verifiedFiles'] > 0 and archive['verifiedFiles'] == len(archive['files'])
        retain(archive_file)
        retain(archive['archive']['file'], archive['archive']['sha256'])
        assert observed == {(case['id'], case['lanes'][0]) for case in batch['cases']}
        assert len(fresh) == len(batch['cases'])
        compare(report['rows'])
        step['complete'] = True
        process = None
        save()
    assert len(report['freshRows']) == 54 and compare(report['rows']) == set(historical)
    assert not report['incompleteBatchRows'] and not report['neverStarted']
    report['counts'] = {v: sum(row['referenceVerdict'] == v for row in report['rows']) for v in ['pass', 'not-applicable', 'fail']}
    assert report['counts'] == plan['expectedCounts']
    verify()
    report['inputs'] = list(inputs.values())
    report['exactRows'] = 81
    report['complete'] = report['agreementComplete'] = True
except BaseException as error:
    report['error'] = repr(error)
finally:
    if process is not None:
        stop(process)
    report['wallSeconds'] = time.monotonic() - start
    save()
print(json.dumps({k: report.get(k) for k in ['complete', 'agreementComplete', 'exactRows', 'counts', 'error', 'wallSeconds']}))
raise SystemExit(0 if report['agreementComplete'] else 1)
