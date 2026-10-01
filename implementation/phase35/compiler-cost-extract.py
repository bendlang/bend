#!/usr/bin/env python3
"""Derive checked-library costs from closed receipts; execute no compiler/program."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import statistics
import tarfile

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT/'selfhost/build/phase35'


def identity(path):
    path = Path(path).resolve()
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(2**20), b''):
            h.update(chunk)
    return dict(file=str(path), sha256=h.hexdigest(), bytes=path.stat().st_size)


def read(path):
    return json.loads(Path(path).read_text())


def verify(entry):
    got = identity(entry['file'])
    assert got['sha256'] == entry['sha256'], entry['file']
    if 'bytes' in entry:
        assert got['bytes'] == entry['bytes'], entry['file']
    return got


def stats(values):
    return dict(median=statistics.median(values), min=min(values), max=max(values), samples=values)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    report_file = BASE/'compiler-cost-run09/report.json'
    report_identity = identity(report_file)
    report = read(report_file)
    assert report['complete'] and report['pass'] and len(report['rows']) == 36
    config_identity = verify(report['config'])
    config = read(config_identity['file'])
    assert config['samples'] == 3 and config['cpu'] == '3'
    worker = verify(config['worker'])
    assert worker['sha256'] == 'f0dea569bdb02df60ed1156b0cead389e197291f1c3a3c6775102c7a03790f42'
    timing_file = BASE/'combined-full-confirm-01/report.json'
    timing = read(timing_file)
    assert timing['complete']
    profile_summary = read(ROOT/'implementation/phase35/profile-evidence-summary.json')
    execution = {r['id']: r['summary'] for r in profile_summary['timing']}
    inputs = [identity(__file__), report_identity, config_identity, worker, identity(timing_file),
              identity(ROOT/'implementation/phase35/profile-evidence-summary.json')]
    derived, checked_outputs = {}, []
    for case in config['cases']:
        name = case['id']
        for role in ['baseline', 'candidate', 'typescript']:
            inputs.extend([verify(case['expected'][role]), verify(case['receipts'][role])])
            rows = [r for r in report['rows'] if r['source'] == name and r['variant'] == role]
            assert [r['sample'] for r in rows] == [0, 1, 2]
            for row in rows:
                obs = row['observation']
                assert row['execution']['complete'] and row['execution']['returncode'] == 0
                assert obs['complete'] and obs['pass'] and obs['observation']['checked']
                assert obs['output']['sha256'] == case['expected'][role]['sha256']
                checked_outputs.append(verify(obs['output']))
            for key in ['requestMs', 'hostImportMs', 'importAndRequestMs', 'maxRssKiB']:
                assert stats([r['observation'][key] for r in rows]) == report['statistics'][name][role][key]
            for key, field in [('processWallMs', 'wallSeconds'), ('peakTreeRssBytes', 'peakTreeRssBytes')]:
                scale = 1000 if key == 'processWallMs' else 1
                assert stats([r['execution'][field]*scale for r in rows]) == report['statistics'][name][role][key]
        roles = report['statistics'][name]
        b, c = roles['baseline']['requestMs'], roles['candidate']['requestMs']
        growth = c['median']/b['median']-1
        extra = c['median']-b['median']
        d = dict(requestChangePercent=growth*100, extraRequestMs=extra,
                 candidateOverTypeScript= c['median']/roles['typescript']['requestMs']['median'],
                 requestRangesDisjoint=c['min'] > b['max'],
                 outputGrowthPercent=100*(roles['candidate']['outputBytes']['median']/roles['baseline']['outputBytes']['median']-1),
                 firstToLastRequestDriftPercent={r: 100*(s['requestMs']['samples'][-1]/s['requestMs']['samples'][0]-1) for r,s in roles.items()},
                 preflightMs={r: stats([x['observation']['preflightMs'] for x in report['rows'] if x['source']==name and x['variant']==r]) for r in roles})
        if name in execution:
            sample = execution[name]['stats']
            saving = sample['baseline']['medianMs']-sample['candidate']['medianMs']
            d['illustrativeWarmExecutionAmortization'] = dict(savedMsPerFixedCall=saving,
                fractionalCalls=extra/saving, wholeCalls=math.ceil(extra/saving),
                scope='Arithmetic across separately measured request and warm execution medians; not measured end-to-end latency or a general workload prediction.')
        derived[name] = d

    reference_file = ROOT/'selfhost/tools/performance/programs/baseline/manifest.json'
    reference = read(reference_file)
    fresh_file = BASE/'compiler-cost-baseline-preparation09/manifest.json'
    fresh = read(fresh_file)
    inputs.extend([identity(reference_file), identity(fresh_file), identity(BASE/'compiler-cost-baseline-preparation09/preparation.json')])
    old_base = reference['roles']['baseline']['compiler']['base']
    new_base = config['variants']['baseline']['base']
    assert old_base['sha256'] == new_base['sha256']
    old_dir, new_dir = str(Path(old_base['file']).parent), str(Path(new_base['file']).parent)
    changes = []
    archive_file = reference_file.parent/reference['archive']['path']
    assert identity(archive_file)['sha256'] == reference['archive']['sha256']
    with tarfile.open(archive_file, 'r:gz') as archive:
        for case in config['cases']:
            previous = next(x for x in reference['cases'] if x['id'] == case['id'])['modules']['baseline']
            original = archive.extractfile(previous['path']).read()
            assert hashlib.sha256(original).hexdigest() == previous['sha256']
            current = Path(case['expected']['baseline']['file']).read_bytes()
            # Offline cause analysis only. The timed worker compares original
            # bytes to fresh independently checked bytes without normalization.
            assert original.replace(old_dir.encode(), new_dir.encode()) == current
            changes.append(dict(id=case['id'], oldModule=previous,
                freshModule=case['expected']['baseline'], occurrences=original.count(old_dir.encode()),
                onlyDifference='Base directory in emitted foreign-binding paths'))
    result = dict(kind='phase35-compiler-cost-derived-data', complete=True,
        scope='Read-only receipt/statistic/output verification. No compiler or generated-program execution; no release-closure assertion.',
        producer=identity(__file__), inputs=inputs, workerUnchangedFromPhase30=True,
        rows=36, wallSeconds=report['wallSeconds'], statistics=report['statistics'], derived=derived,
        checkedOutputIdentities=checked_outputs,
        baselineOverride=dict(reference=identity(reference_file), fresh=identity(fresh_file),
            archive=identity(archive_file), oldBase=old_base, normalAttemptBase=new_base,
            compilerApi=config['variants']['baseline']['api'], cases=changes, timingNormalization=False),
        plan={k: config[k] for k in ['cpu','samples','timeoutMs','heapMiB','rssMiB','availableMiB','order','scope']})
    assert identity(report_file) == report_identity
    args.out.write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(dict(complete=True, rows=36, out=str(args.out), derived=derived)))


if __name__ == '__main__':
    main()
