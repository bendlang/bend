#!/usr/bin/env python3
"""Close frozen public cohorts without changing their original oracle statuses."""
from pathlib import Path
import hashlib
import json
import sys

R = Path.cwd()
serial = sys.argv[1]
out = R / f'implementation/phase22/context-controls-production-{serial}.json'
assert not out.exists(), out

def ident(p):
    p = Path(p).resolve()
    data = p.read_bytes()
    return {'file': str(p), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}

inputs = [ident(__file__)]
consumed = {}
parts = {}
api = None
for category, launcher in [
    ('parseCheck', f'context-controls-production-sweep-{serial}'),
    ('execution', f'context-controls-execution-sweep-{serial}'),
]:
    path = R / 'selfhost/build/phase22' / launcher / 'report.json'
    launch = json.loads(path.read_text())
    assert launch['complete'] and launch['pass'], path
    inputs.append(ident(path))
    parts[category] = []
    for job in launch['jobs']:
        assert job['exitCode'] == 0
        q = Path(job['report']['file'])
        assert ident(q)['sha256'] == job['report']['sha256']
        report = json.loads(q.read_text())
        paired_path = q.parent / 'selected/paired.json'
        paired = json.loads(paired_path.read_text())
        assert report['complete'] and report['pass']
        assert not paired['missing'] and not paired.get('error')
        assert all(row['exactAgreement'] for row in paired['rows'])
        assert not report['comparison']['lostExact']
        assert not report['comparison']['newPrimitiveMismatch']
        if api is None:
            api = report['api']
        assert report['api'] == api
        prior_path = Path(report['comparison']['prior']['file'])
        assert ident(prior_path)['sha256'] == report['comparison']['prior']['sha256']
        prior_paired_path = prior_path.parent / 'selected/paired.json'
        prior = json.loads(prior_paired_path.read_text())
        assert len(prior['rows']) == len(paired['rows'])
        parts[category].append({
            'name': job['name'], 'report': ident(q),
            'observations': len(paired['rows']),
            'baselineExact': sum(row['exactAgreement'] for row in prior['rows']),
            'candidateExact': len(paired['rows']),
            'gainedExact': report['comparison']['gainedExact'],
            'lostExact': report['comparison']['lostExact'],
            'rawSelectedComplete': report['selected']['selectedComplete'],
            'rawReferenceStatuses': report['selected']['reference']['statuses'],
            'rawCandidateStatuses': report['selected']['candidate']['statuses'],
        })
        inputs += [ident(q), ident(paired_path), ident(prior_path), ident(prior_paired_path)]
        for record in [*report['inputs'], report['api'], report['attempt'], report['cache']]:
            previous = consumed.setdefault(record['file'], record)
            assert previous['sha256'] == record['sha256'], record['file']

for record in consumed.values():
    assert ident(record['file'])['sha256'] == record['sha256'], record['file']

totals = {category: {
    'observations': sum(p['observations'] for p in rows),
    'baselineExact': sum(p['baselineExact'] for p in rows),
    'candidateExact': sum(p['candidateExact'] for p in rows),
} for category, rows in parts.items()}
assert totals['parseCheck']['observations'] == 154
assert totals['execution']['observations'] == 36
report = {
    'kind': 'phase22-public-context-controls-closure', 'complete': True, 'pass': True,
    'passMeaning': 'These frozen paired cohorts exactly match the pin; this does not select or promote the candidate.',
    'api': api, 'totals': totals, 'parts': parts,
    'overlap': 'The 36 execution observations cover nine programs in check/interpreter/JavaScript/native lanes. Their nine check observations also appear in parseCheck; do not count 190 distinct observations.',
    'rawOracleStatus': 'Prospective fixture assumptions disproved by the pin remain unchanged. Main and feature raw suite failures are retained even though actual paired behavior now agrees exactly.',
    'scope': 'Original60, do20, feature40, alias4, group4 and finalization26; ordinary24 and feature12 execution. Separate materialization16/do-header4/header-demand2 and private beta controls are not included.',
    'programBehavior': 'Parallel RHSs see the outer scope, nested lambda capture and erased/marked locals retain behavior, group/type annotations execute, do notation returns105n, rewrite shadowing returns7, written Array.set returns9 and wildcard array update returns34.',
    'identityAudit': {'pass': True, 'uniqueConsumedInputs': len(consumed)},
    'inputs': inputs,
}
out.write_text(json.dumps(report, indent=2) + '\n')
out.with_suffix('.md').write_text(f'''# Phase22 public control closure {serial}

The same checked image matches all **154 frozen parse/check observations**, up from {totals['parseCheck']['baselineExact']} on the installed Phase21 parent. It also matches all **36 execution observations** (nine programs across check, interpreter, JavaScript and native), up from {totals['execution']['baselineExact']}. There are no lost exact matches or primitive regressions in these cohorts.

The programs exercise simultaneous parallel RHS visibility, nested closure capture, erased/marked locals, grouped annotations, do notation, rewrite shadowing and array updates. The nine check observations overlap the parse/check cohorts; the totals are not 190 distinct observations.

The original prospective fixture assumptions and raw suite failure statuses remain preserved. Agreement here means exact actual pin behavior. Separate materialization and direct worker controls remain outside this report; this closure does not select or promote the image.

The JSON binds every original report and baseline, the exact API, and a closing audit of {len(consumed)} unique consumed identities. API SHA-256: `{api['sha256']}`.
''')
print(json.dumps({'complete': True, 'pass': True, 'totals': totals, 'report': ident(out)}))
