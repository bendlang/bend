#!/usr/bin/env python3
"""Audit every matched-confirmation result and retain comparison arithmetic."""
import argparse
import hashlib
import json
import statistics
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('report')
parser.add_argument('out')
args = parser.parse_args()
report_path = Path(args.report).resolve()
report = json.loads(report_path.read_text())
assert report['complete'] and report['pass']
plan_path = Path(report['plan'])
assert hashlib.sha256(plan_path.read_bytes()).hexdigest() == report['planSha256']
plan = json.loads(plan_path.read_text())
expected_labels = {
    f'{trial:02}-{workload}-{role}'
    for trial, roles in enumerate(plan['order'])
    for workload in plan['workloads'] for role in roles
}
assert len(report['jobs']) == len(expected_labels)
assert {job['label'] for job in report['jobs']} == expected_labels
rows = {}
inputs = []
for job in report['jobs']:
    assert job['returncode'] == 0
    file = Path(job['result'])
    raw = file.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == job['sha256']
    result = json.loads(raw)
    assert result['complete'] and result['pass']
    assert result['artifact'] == plan['variants'][result['role']]
    assert len(result['observations']) == plan['samples']
    rows.setdefault(result['workload'], {}).setdefault(result['role'], []).append(result)
    inputs.append(dict(file=str(file), sha256=job['sha256'], bytes=len(raw)))

summary = {}
for workload, roles in rows.items():
    assert len({r['expectedHash'] for rs in roles.values() for r in rs}) == 1
    summary[workload] = {}
    for role, results in roles.items():
        assert len(results) == len(plan['order'])
        times = [o['msPerBatch'] for r in results for o in r['observations']]
        drifts = [o['halfDriftPercent'] for r in results for o in r['observations']]
        temporal = []
        for result in results:
            samples = [o['msPerBatch'] for o in result['observations']]
            temporal.append(100 * (statistics.median(samples[-2:]) /
                                   statistics.median(samples[:2]) - 1))
        summary[workload][role] = dict(
            samples=len(times), medianMs=statistics.median(times),
            rangeMs=[min(times), max(times)], halfDriftPercent=[min(drifts), max(drifts)],
            withinProcessLastTwoOverFirstTwoPercent=temporal,
            peakRssKiB=max(r['resourceUsage']['maxRSS'] for r in results),
        )
    comparisons = {}
    for old, new, label in [
        ('baseline', 'captured', 'bindingOnly'),
        ('captured', 'fields', 'projectionOnly'),
        ('fields', 'combined', 'directCallsAfterFields'),
        ('baseline', 'combined', 'combinedVsBaseline'),
    ]:
        old_row = summary[workload][old]
        new_row = summary[workload][new]
        comparisons[label] = dict(
            numerator=old, denominator=new,
            speedup=old_row['medianMs'] / new_row['medianMs'],
            timeSavedPercent=100 * (1 - new_row['medianMs'] / old_row['medianMs']),
            newRangeEntirelyFaster=new_row['rangeMs'][1] < old_row['rangeMs'][0],
            rangesOverlap=(max(old_row['rangeMs'][0], new_row['rangeMs'][0]) <=
                           min(old_row['rangeMs'][1], new_row['rangeMs'][1])),
        )
    summary[workload]['comparisons'] = comparisons


def identity(p):
    p = Path(p).resolve()
    raw = p.read_bytes()
    return dict(file=str(p), sha256=hashlib.sha256(raw).hexdigest(), bytes=len(raw))


output = dict(
    kind='phase32-checker-matched-confirmation-summary', complete=True,
    **{'pass': True}, inputs=[identity(report_path), identity(plan_path),
                             identity(__file__), *inputs],
    jobs=len(report['jobs']), seconds=report['seconds'], workloads=summary,
    scope='Arithmetic over every completed frozen-plan sample. Range overlap and '
          'drift are descriptive, not significance tests or convergence proofs. '
          'Private helper observations do not establish public or request performance.',
)
with Path(args.out).open('x') as stream:
    stream.write(json.dumps(output, indent=2) + '\n')
print(json.dumps({'jobs': output['jobs'], 'seconds': output['seconds'],
                  'comparisons': {w: v['comparisons'] for w, v in summary.items()}}, indent=2))
