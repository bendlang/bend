#!/usr/bin/env python3
"""Audit retained exact executions without rewriting their mistaken #| oracle."""
import hashlib
import json
import traceback
from pathlib import Path

repo = Path(__file__).resolve().parents[4]
phase = repo/'selfhost/build/phase21'
out = phase/'group-range-program-audit-01'
out.mkdir()
report = {'kind': 'phase21-group-range-program-observation-audit', 'complete': False,
          'pass': False, 'inputs': [], 'rawVerdictsWaived': False,
          'scope': 'Twelve healthy exact paired observations, including nine successful actual executions. Original nine output-oracle failures remain false: the prospective #| comments omitted the Nat printer n suffix. No fixture edit or rerun.'}

def identity(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}

def read(p):
    report['inputs'].append(identity(p))
    return json.loads(Path(p).read_text())

try:
    report['inputs'].append(identity(__file__))
    raw = read(phase/'group-range-programs-01/report.json')
    assert not raw['complete'] and not raw['pass'] and 'paired.selectedComplete' in raw['error']
    for x in raw['inputs']:
        assert identity(x['file'])['sha256'] == x['sha256']
    report['api'] = raw['api']
    report['inputs'].append(identity(raw['api']['file']))
    execution = raw['execution']
    assert execution['exitCode'] == 1 and not execution['timedOut'] and not execution['overflow']
    assert execution['error'] is None and execution['signal'] is None
    paired = read(phase/'group-range-programs-01/selected/paired.json')
    assert len(paired['rows']) == 12 and paired['missing'] == [] and not paired['selectedComplete']
    for side in ['candidate', 'reference']:
        data = read(phase/f'group-range-programs-01/selected/{side}.json')
        assert len(data['results']) == 12 and not data['changedInputs']
        assert not data['identity']['changedArtifacts'] and not data['identity']['adapterChangedDuringRun']
        assert all(not w['errors'] and w['stats']['failures'] == w['stats']['timeouts'] == 0 for w in data['workers'])
        assert data['summary']['statuses'] == {'pass': 3, 'fail': 9}
    expected = {'ordinary': '41n\n', 'nested-typed': '42n\n', 'nested-value': '43n\n'}
    for row in paired['rows']:
        assert row['exactAgreement'] and row['semanticAgreement'] and row['candidate'] == row['reference']
        result = row['candidate']
        assert result['status'] == 'ok' and result['checked'] and result['typeAccepted'] and result['exitCode'] == 0
        assert result['diagnostic'] is None
        if row['lane'] == 'check':
            assert row['candidateVerdict'] == row['referenceVerdict'] == 'pass'
        else:
            assert row['lane'] in ['interpreter', 'js', 'native']
            assert row['candidateVerdict'] == row['referenceVerdict'] == 'fail'
            assert result['output'] == expected[row['id'].split('/')[-1]]
    report['rows'] = paired['rows']
    report['observations'] = 12
    report['executions'] = 9
    report['rawOutputOracleFailuresPerSide'] = 9
    for item in report['inputs']: assert identity(item['file']) == item
    report['complete'] = report['pass'] = True
except Exception:
    report['error'] = traceback.format_exc()
finally:
    (out/'report.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps({k:report[k] for k in ['complete','pass','error'] if k in report}))
if not report['pass']: raise SystemExit(1)
