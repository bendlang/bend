#!/usr/bin/env python3
"""Read frozen Phase35 diagnostics; extract bounded summaries, run no programs."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ap = argparse.ArgumentParser(description=__doc__)
ap.add_argument('--profiles', type=Path, default=ROOT/'selfhost/build/phase35/combined-profiles-01')
ap.add_argument('--timing', type=Path, default=ROOT/'selfhost/build/phase35/combined-full-confirm-01/report.json')
ap.add_argument('--out', type=Path, required=True)
args = ap.parse_args()


def identity(file):
    digest = hashlib.sha256()
    with file.open('rb') as stream:
        for block in iter(lambda: stream.read(1024*1024), b''):
            digest.update(block)
    return dict(file=str(file.resolve()), sha256=digest.hexdigest(), bytes=file.stat().st_size)


def frame_key(frame):
    return tuple(frame.get(k, fallback) for k, fallback in
                 [('functionName', ''), ('url', ''), ('lineNumber', -1), ('columnNumber', -1)])


def ancestry(profile, summary):
    """Union ancestry per sample; recursive frames never multiply a sample."""
    mapped = {frame_key(f['frame']): set(f.get('generatedSource', {}).get('bendNames', []))
              for f in summary['frames']}
    nodes = {n['id']: n for n in profile['nodes']}
    parents = {}
    for node in profile['nodes']:
        for child in node.get('children', []):
            assert child not in parents, 'CPU profile must be a tree'
            parents[child] = node['id']
    memo = {}

    def marks(node_id):
        if node_id in memo:
            return memo[node_id]
        frame = nodes[node_id]['callFrame']
        names = mapped.get(frame_key(frame), set())
        value = marks(parents[node_id]) if node_id in parents else 0
        if names & {'gen', 'gen.leaf', 'node'}:
            value |= 1
        if names & {'eval', 'esize'}:
            value |= 2
        if frame.get('functionName') in ['regionHostGuard', 'scalarGuard', 'localGuard']:
            value |= 4
        memo[node_id] = value
        return value

    assert len(profile['samples']) == len(profile['timeDeltas'])
    weights, total = [0, 0, 0], 0
    for node_id, weight in zip(profile['samples'], profile['timeDeltas']):
        value = marks(node_id)
        total += weight
        for bit in range(3):
            if value & (1 << bit):
                weights[bit] += weight
    assert total == summary['totalWeight']
    return dict(totalMicroseconds=total, groups={name: dict(microseconds=weight, percent=100*weight/total)
                for name, weight in zip(['producer', 'evalAndSize', 'guards'], weights)},
                interpretation='Each sample is counted once within a group if any ancestor matches; groups may overlap and are not additive.')


base = args.profiles.resolve()
report_file, analysis_file = base/'report.json', base/'analysis/report.json'
report, analysis, timing = (json.loads(p.read_text()) for p in [report_file, analysis_file, args.timing])
assert report['complete'] and report['pass'] and report['completedProfiles'] == 24
assert analysis['complete'] and timing['complete'] and timing['pass']
result = dict(kind='phase35-final-profile-extraction', complete=False,
              scope='Read-only existing profiles/static analysis; clean execution medians come from a separate final confirmation.',
              inputs=[identity(p) for p in [Path(__file__), report_file, analysis_file, args.timing]],
              diagnosticWallSeconds=report['wallSeconds'], plan=report['plan'], entries=[], profiles=[], timing=[])
for entry in analysis['entries']:
    file = base/'modules'/entry['id']/(entry['role']+'.mjs')
    assert identity(file)['sha256'] == entry['sha256']
    targets = {row['name'] for row in entry['callTargets']}
    helpers = [f for f in entry['functions'] if f['kind'] == 'FunctionDeclaration' and f['name'].startswith('$R_')]
    uncalled = [f for f in helpers if f['name'] not in targets]
    result['entries'].append(dict(id=entry['id'], role=entry['role'], module=identity(file),
        sourceSha256=entry['sourceSha256'], programBytes=entry['sections']['program']['bytes'],
        programMetrics=entry['sections']['program']['metrics'], privateDeclarations=len(helpers),
        privateDeclarationsWithoutDirectCallNames=[dict(name=f['name'], bytes=f['bytes'], bendNames=f['bendNames'],
            line=f['line'], column=f['column']) for f in uncalled],
        privateBytesWithoutDirectCallNames=sum(f['bytes'] for f in uncalled),
        pruningCaveat='No direct-call site under these spellings anywhere in the module; not yet a lexical-reference or removability proof.'))
for row in report['profiles']:
    data, summary = row['result'], row['result']['summary']
    assert row['complete'] and data['complete'] and data['pass'] and data['diagnosticOnly']
    profile_file = base/'profiles'/row['id']/(row['role']+'-'+row['kind'])/('profile.'+('cpuprofile' if row['kind']=='cpu' else 'heapprofile'))
    assert identity(profile_file)['sha256'] == data['profile']['sha256']
    compact = dict(id=row['id'], role=row['role'], kind=row['kind'], profile=identity(profile_file),
        repetitions=data['repetitions'], samples=summary['sampleCount'], unit=summary['unit'], totalWeight=summary['totalWeight'],
        categories=summary['categories'], topOwners=summary['ownersBySelf'][:12], warnings=summary['warnings'],
        peakTreeRssBytes=row['process']['peakTreeRssBytes'], sampling=data['sampling'])
    if row['kind'] == 'allocation':
        compact['estimatedBytesPerCall'] = summary['estimatedBytesPerCall']
        compact['accounting'] = {k: summary['accounting'][k] for k in ['weightSource', 'sampleEstimatedBytes',
            'headSelfSizeBytes', 'sampleMinusHeadBytes', 'unattributedSamples', 'unattributedEstimatedBytes']}
    elif row['id'] in ['symreg', 'raytrace']:
        compact['ancestryUnion'] = ancestry(json.loads(profile_file.read_text()), summary)
    result['profiles'].append(compact)
for row in timing['cases']:
    if row['id'] in ['local-pair', 'local-fold', 'symreg', 'raytrace']:
        assert row['summary']['complete']
        result['timing'].append(dict(id=row['id'], summary=row['summary']))
result['complete'] = True
with args.out.open('x') as stream:
    json.dump(result, stream, indent=2)
    stream.write('\n')
print(json.dumps(dict(complete=True, profiles=len(result['profiles']), entries=len(result['entries']), output=str(args.out))))
