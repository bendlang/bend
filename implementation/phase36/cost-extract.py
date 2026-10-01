#!/usr/bin/env python3
"""Extract the rejected cost-only experiment from completed immutable receipts."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ap = argparse.ArgumentParser(description=__doc__)
ap.add_argument('--out', type=Path, required=True)
args = ap.parse_args()
paths = {
    'cost': ROOT/'selfhost/build/phase36/cost-run01/report.json',
    'config': ROOT/'selfhost/build/phase36/cost-plan01/config.json',
    'controls': ROOT/'selfhost/build/phase36/cost-controls01/report.json',
    'baseline': ROOT/'selfhost/build/phase35/combined-full-01/manifest.json',
    'candidate': ROOT/'selfhost/build/phase36/cost-full01/manifest.json',
    'build': ROOT/'selfhost/build/phase36/checked01-outer/run.json',
    'focus': ROOT/'selfhost/build/phase36/checked01/validation-001/report.json',
}


def identity(file):
    data = file.read_bytes()
    return dict(path=str(file.relative_to(ROOT)), sha256=hashlib.sha256(data).hexdigest(), bytes=len(data))


data = {name: json.loads(file.read_text()) for name, file in paths.items()}
assert data['cost']['complete'] and data['cost']['pass'] and len(data['cost']['rows']) == 36
assert data['controls']['complete'] and data['controls']['pass'] and len(data['controls']['observations']) == 10
assert data['candidate']['complete'] and data['baseline']['complete']
baseline = {c['id']: c for c in data['baseline']['cases']}
equality = []
for candidate in data['candidate']['cases']:
    before = baseline[candidate['id']]
    assert before['sourceSha256'] == candidate['sourceSha256'] and before['point'] == candidate['point']
    refs = [before['modules']['candidate'], candidate['modules']['candidate']]
    for parent, ref in zip([paths['baseline'].parent, paths['candidate'].parent], refs):
        assert identity(parent/ref['path'])['sha256'] == ref['sha256']
    assert refs[0]['sha256'] == refs[1]['sha256'] and refs[0]['bytes'] == refs[1]['bytes']
    equality.append(dict(id=candidate['id'], sha256=refs[0]['sha256'], bytes=refs[0]['bytes']))
assert len(equality) == 15
cases = []
for name, roles in data['cost']['statistics'].items():
    b, c, ts = [roles[r]['requestMs'] for r in ['baseline', 'candidate', 'typescript']]
    overlap = max(b['min'], c['min']) <= min(b['max'], c['max'])
    cases.append(dict(id=name, baseline=b, candidate=c, typescript=ts,
                      candidateMedianChangePercent=100*(c['median']/b['median']-1), rangesOverlap=overlap,
                      fullStatistics=roles))
result = dict(kind='phase36-rejected-inline-preflight-extraction', complete=True, decision='reject',
              inputs=[identity(Path(__file__)), *[identity(p) for p in paths.values()]],
              scope='Read-only extraction; fresh-process normal checked requests, not generated-program timing.',
              wallSeconds=data['cost']['wallSeconds'], compilerIdentities=data['config']['variants'],
              rows=36, controls=data['controls']['observations'], cases=cases, exactCatalogOutputs=equality,
              build={k: data['build'][k] for k in ['complete', 'wallSeconds', 'peakTreeRssBytes']},
              rejection='Small scalar workload request savings do not justify added pass/definition and uncertain adverse pair effect.')
with args.out.open('x') as stream:
    json.dump(result, stream, indent=2)
    stream.write('\n')
print(json.dumps(dict(complete=True, decision='reject', rows=36, byteEqualCatalogPoints=15, output=str(args.out))))
