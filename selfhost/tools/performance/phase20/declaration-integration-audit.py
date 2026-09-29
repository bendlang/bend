#!/usr/bin/env python3
"""Compare entire result vectors; known raw gate failures remain failures."""
import hashlib, json, sys
from pathlib import Path

repo = Path(__file__).resolve().parents[4]
phase = repo / 'selfhost/build/phase20'
out = Path(sys.argv[1]).resolve()
out.mkdir()
report = {'kind': 'phase20-declaration-integration-audit', 'complete': False,
          'pass': False, 'inputs': [], 'scope': 'Independent full-result regression audit; does not waive raw selected-test failures.'}

def identity(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}

def read(p):
    report['inputs'].append(identity(p))
    return json.loads(Path(p).read_text())

def rows(d, count):
    assert not d['changedInputs']
    if count == 2996:
        assert d['complete']
    # For targeted negatives, complete is coupled to strict verdicts; acquire
    # health independently without changing that original producer flag.
    assert len(d['results']) == count
    for w in d['workers']:
        assert not w['errors'] and w['stats']['failures'] == w['stats']['timeouts'] == 0
    result = {(r['id'], r['lane']): r['result'] for r in d['results']}
    assert len(result) == count
    return result

try:
    report['inputs'].append(identity(__file__))
    # Main corpus must preserve every prior complete result, not just its mismatch count.
    a = read(repo / 'selfhost/build/phase19/instance-frontend-01/candidate.json')
    b = read(phase / 'declaration-frontend-01/candidate.json')
    old, new = rows(a, 2996), rows(b, 2996)
    assert old.keys() == new.keys()
    changes = [{'id': k[0], 'lane': k[1], 'before': old[k], 'after': new[k]} for k in old if old[k] != new[k]]
    report['frontend'] = {'observations': 2996, 'changes': changes}
    assert changes == []
    f = read(phase / 'declaration-frontend-01/report.json')
    assert f['complete'] and f['pass'] and f['exact']['after'] == 2
    assert f['sincePrevious']['improved'] == 0 and f['sincePrevious']['lost'] == []
    api = f['api']['sha256']
    assert b['identity']['artifacts']['compiler']['sha256'] == api
    report['api'] = f['api']
    # Broader groups deliberately retain known negative contract failures.
    parent = repo / 'selfhost/build/phase19/instance-group196-01/selected'
    current = phase / 'declaration-group196-01/selected'
    ac, ar = read(parent / 'candidate.json'), read(parent / 'reference.json')
    bc, br = read(current / 'candidate.json'), read(current / 'reference.json')
    old, ref = rows(ac, 196), rows(ar, 196)
    new, nowref = rows(bc, 196), rows(br, 196)
    assert old.keys() == new.keys() == ref.keys() == nowref.keys()
    assert ref == nowref, 'Pinned reference changed'
    assert bc['identity']['artifacts']['compiler']['sha256'] == api
    # Equality below is the complete result, including all primitive axes and diagnostic.
    changed = [{'id': k[0], 'lane': k[1], 'before': old[k], 'after': new[k],
                'reference': ref[k], 'becameExact': new[k] == ref[k]} for k in old if old[k] != new[k]]
    lost = [list(k) for k in old if old[k] == ref[k] and new[k] != ref[k]]
    expected = {(f'group/{name}', lane) for name in ['nested-zero-head-match', 'zero-head-match',
                'zero-head-match-argument', 'zero-head-match-lambda'] for lane in ['parse', 'check']}
    report['groups'] = {'observations': 196, 'beforeExact': sum(old[k] == ref[k] for k in old),
        'afterExact': sum(new[k] == ref[k] for k in new), 'changed': changed, 'lost': lost,
        'remainingDifferences': [list(k) for k in new if new[k] != ref[k]],
        'oldSummary': ac['summary'], 'newSummary': bc['summary']}
    assert {(r['id'], r['lane']) for r in changed} == expected
    assert all(r['becameExact'] for r in changed) and not lost
    assert report['groups']['beforeExact'] == 128 and report['groups']['afterExact'] == 136
    raw = read(phase / 'declaration-group196-01/report.json')
    paired = read(current / 'paired.json')
    assert raw['api']['sha256'] == api
    assert raw['complete'] is False and raw['pass'] is False
    assert paired['selectedComplete'] is False and paired['missing'] == [] and len(paired['rows']) == 196
    report['groups']['rawGate'] = {'complete': raw['complete'], 'pass': raw['pass'], 'error': raw.get('error'),
        'selectedComplete': paired['selectedComplete'], 'attempts': paired['attempts']}
    for item in report['inputs']:
        assert identity(item['file']) == item
    report['complete'] = report['pass'] = True
except Exception as e:
    import traceback
    report['error'] = traceback.format_exc()
    raise
finally:
    (out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'complete': report['complete'], 'pass': report['pass'], 'error': report.get('error')}))
