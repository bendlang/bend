#!/usr/bin/env python3
"""Audit the complete five-role checked-output ladder without executing programs."""
import argparse
import hashlib
import json
import statistics
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('report')
parser.add_argument('out')
args = parser.parse_args()
report_file = Path(args.report).resolve()
report = json.loads(report_file.read_text())
assert report['complete'] and report['allCasesMeasured']
roles = ['baseline', 'statements', 'read_fusion', 'record_vectors', 'typescript']
assert [c['id'] for c in report['cases']] == ['local-pair', 'local-fold']
samples = report['protocol']['samples']
assert samples in [3, 5]
known_inputs = {x['file']: x for x in report['inputs']}
contexts = set()
inputs = []
cases = {}


def identity(file):
    file = Path(file).resolve()
    raw = file.read_bytes()
    return dict(file=str(file), sha256=hashlib.sha256(raw).hexdigest(), bytes=len(raw))


def median_range(values):
    return dict(median=statistics.median(values), min=min(values), max=max(values),
                samples=values)


for case in report['cases']:
    assert case['complete'] and case['status'] == 'measured'
    assert list(case['sides']) == roles
    assert len(case['samples']) == len(roles) * samples
    assert {(s['variant'], s['repetition']) for s in case['samples']} == {
        (role, trial) for role in roles for trial in range(samples)}
    for role in roles:
        assert case['checks'][role]['complete'] and case['calibration'][role]['complete']
    rows = {}
    for role in roles:
        selected = [s for s in case['samples'] if s['variant'] == role]
        times, half_drifts, cold, rss, imports, details = [], [], [], [], [], []
        for sample in selected:
            result = sample['result']
            assert sample['complete'] and sample['exitCode'] == 0 and result['complete']
            assert result['mode'] == 'time'
            assert result['config']['args'] == case['point']['args']
            assert result['firstResult'] == result['config']['expected'] == case['point']['expected']
            assert result['checksum'] == (case['point']['expected'] * result['repetitions']) % 2**32
            assert result['warmup'] >= report['protocol']['warmupCalls']
            assert result['warmupMs'] >= report['protocol']['warmupMs']
            assert result['affinity'].split(':')[1].strip() == '3'
            contexts.add((result['node'], tuple(result['args']), result['toolSha256']))
            artifact = identity(result['module']['file'])
            assert artifact['sha256'] == result['module']['sha256']
            assert artifact['sha256'] == known_inputs[artifact['file']]['sha256']
            inputs.append(artifact)
            raw_dir = report_file.parent / case['id'] / f"{sample['repetition']}-{role}"
            stdout = raw_dir / 'stdout.log'
            assert json.loads(stdout.read_text().strip().splitlines()[-1]) == result
            inputs.extend(identity(raw_dir / name) for name in ['stdout.log', 'stderr.log', 'launch.json'])
            halves = result['halves']
            assert sum(h['calls'] for h in halves) == result['repetitions']
            drift = None
            if len(halves) == 2:
                assert all(h['calls'] > 0 for h in halves)
                drift = 100 * ((halves[1]['ms'] / halves[1]['calls']) /
                               (halves[0]['ms'] / halves[0]['calls']) - 1)
                half_drifts.append(drift)
            times.append(result['executionMs'] / result['repetitions'])
            cold.append(result['firstCallMs'])
            rss.append(result['peakRssKiB'])
            imports.append(result['importMs'])
            details.append(dict(trial=sample['repetition'], repetitions=result['repetitions'],
                                warmCalls=result['warmup'], warmMs=result['warmupMs'],
                                halves=halves, halfDriftPercent=drift))
        prior = case['sides'][role]
        assert times == prior['samplesMs']
        assert statistics.median(times) == prior['medianMs']
        assert [min(times), max(times)] == [prior['minMs'], prior['maxMs']]
        rows[role] = dict(timeMs=median_range(times), firstCallMs=median_range(cold),
                          importMs=median_range(imports), peakRssKiB=max(rss),
                          processPeakRssKiB=rss, halfDriftPercent=(median_range(half_drifts)
                          if half_drifts else None), observations=details)
    comparisons = {}
    for before, after, label in [
        ('baseline', 'statements', 'statementBindings'),
        ('statements', 'read_fusion', 'arrayReadTupleFusion'),
        ('read_fusion', 'record_vectors', 'privateRecordVectorsAndDirectSigma'),
        ('baseline', 'record_vectors', 'combinedVsBaseline'),
    ]:
        old, new = rows[before]['timeMs'], rows[after]['timeMs']
        comparisons[label] = dict(before=before, after=after,
            speedup=old['median'] / new['median'],
            timeSavedPercent=100 * (1 - new['median'] / old['median']),
            newRangeEntirelyFaster=new['max'] < old['min'],
            rangesOverlap=max(old['min'], new['min']) <= min(old['max'], new['max']))
    for role in roles:
        rows[role]['sameWindowTimesTypeScript'] = (rows[role]['timeMs']['median'] /
                                                 rows['typescript']['timeMs']['median'])
    cases[case['id']] = dict(point=case['point'], variants=rows, comparisons=comparisons)
assert len(contexts) == 1
node, flags, execute_hash = next(iter(contexts))
output = dict(kind='phase32-checked-local-ladder-summary', complete=True, **{'pass': True},
    inputs=[identity(report_file), identity(__file__),
            *{x['file']: x for x in inputs}.values()], protocol=report['protocol'],
    timedProcesses=sum(len(c['samples']) for c in report['cases']),
    wallSeconds=report['wallSeconds'], node=node, nodeArgs=flags,
    executionToolSha256=execute_hash, cases=cases,
    scope='Complete pair/fold points, all frozen-role samples and child stdout audited. '
          'record_vectors combines private record storage with direct private Sigma '
          'construction; its fold gain cannot be assigned to record storage alone. '
          'Half drift and full ranges are descriptive, not convergence or statistical '
          'significance proofs. No compiler-request or original-four-pair timing claim.')
with Path(args.out).open('x') as stream:
    stream.write(json.dumps(output, indent=2) + '\n')
print(json.dumps(dict(complete=True, timedProcesses=output['timedProcesses'],
    cases={key: dict(comparisons=value['comparisons'], medians={role:
           row['timeMs']['median'] for role, row in value['variants'].items()})
           for key, value in cases.items()}), indent=2))
