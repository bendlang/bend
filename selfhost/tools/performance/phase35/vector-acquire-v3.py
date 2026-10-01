#!/usr/bin/env python3
"""Serial checked alias/nested-vector cohorts; root owns all execution."""
import argparse
import json
import os
from pathlib import Path
import shutil
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PROGRAMS = HERE.parent / 'programs'
sys.path.insert(0, str(PROGRAMS))
from support import ExecutionGuard, identity, save


def file_identity(file):
    row = identity(file)
    row['file'] = row.pop('path')
    return row


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--attempt', type=Path, required=True)
    parser.add_argument('--baseline-attempt', type=Path, required=True,
                        help='Historical checked baseline; installed verification must not bypass edited-source checks')
    parser.add_argument('--upstream', type=Path, default=ROOT/'selfhost/.bootstrap/upstream-phase23')
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--cases', default='aliases,nested')
    parser.add_argument('--node', required=True)
    parser.add_argument('--cpu', type=int, default=3)
    parser.add_argument('--rss-mib', type=int, default=1536)
    parser.add_argument('--available-mib', type=int, default=2048)
    parser.add_argument('--timeout', type=int, default=180)
    args = parser.parse_args()
    cases = args.cases.split(',')
    assert cases and len(cases) == len(set(cases)) and all(c in ['aliases', 'nested'] for c in cases)
    assert args.cpu in os.sched_getaffinity(0)
    assert 1 <= args.timeout <= 1800
    node = Path(args.node).resolve()
    attempt = args.attempt.resolve()
    baseline_attempt = args.baseline_attempt.resolve()
    upstream = args.upstream.resolve()
    out = args.out.resolve()
    worker = PROGRAMS/'emit-worker.mjs'
    dependencies = [Path(__file__), PROGRAMS/'support.py', worker, PROGRAMS/'catalog.json', node,
        ROOT/'selfhost/tools/development/workflow.mjs', ROOT/'selfhost/tools/development/release.mjs',
        attempt/'attempt.json', baseline_attempt/'attempt.json', *[HERE/('vector-'+c+'.bend') for c in cases]]
    report = dict(kind='phase35-checked-private-vector-cohorts', complete=False,
        inputs=[file_identity(p) for p in dependencies], cases={}, cpu=args.cpu,
        protocol=dict(heapMiB=1024, rssMiB=args.rss_mib, availableMiB=args.available_mib,
                      secondsPerEmission=args.timeout, serial=True))
    report['pass'] = False
    with ExecutionGuard(rss_mib=args.rss_mib, available_mib=args.available_mib) as guard:
        out.mkdir(parents=True, exist_ok=False)
        (out/'consumed').mkdir()
        for p in dependencies:
            if p == node or p in [attempt/'attempt.json', baseline_attempt/'attempt.json']:
                continue
            shutil.copyfile(p, out/'consumed'/p.name)
        save(out/'derive.json', report)
        try:
            compilers = {}
            for case in cases:
                target = out/case
                target.mkdir()
                source = out/'consumed'/('vector-'+case+'.bend')
                source_hash = file_identity(source)['sha256']
                cohort = dict(complete=False, source=file_identity(source), variants={}, emissions={})
                save(target/'derive.json', cohort)
                report['cases'][case] = dict(cohort=str(target/'derive.json'), processes=[])
                for role, selection in [('baseline', str(baseline_attempt)), ('candidate', str(attempt)),
                                        ('typescript', 'upstream:'+str(upstream))]:
                    output = target/(role+'.mjs')
                    command = ['taskset', '-c', str(args.cpu), str(node), '--stack-size=4096',
                        '--max-old-space-size=1024', str(worker), selection, str(source), str(output)]
                    process = guard.run(command, target/('emit-'+role), time.monotonic()+args.timeout)
                    report['cases'][case]['processes'].append(dict(role=role, process=process))
                    save(out/'derive.json', report)
                    assert process['complete'], 'checked emission failed: '+case+'/'+role
                    emitted_path = Path(str(output)+'.json')
                    emitted = json.loads(emitted_path.read_text())
                    assert emitted['complete'] and emitted['observation']['checked']
                    assert emitted['input']['sha256'] == source_hash
                    assert emitted['output']['sha256'] == file_identity(output)['sha256']
                    if role in compilers:
                        assert compilers[role] == emitted['compiler'], 'compiler changed during acquisition'
                    else:
                        compilers[role] = emitted['compiler']
                    cohort['variants'][role] = file_identity(output)
                    cohort['emissions'][role] = file_identity(emitted_path)
                    save(target/'derive.json', cohort)
                    print(json.dumps(dict(case=case, role=role, complete=True)), flush=True)
                cohort['complete'] = True
                cohort['compilers'] = compilers
                save(target/'derive.json', cohort)
                report['cases'][case]['manifest'] = file_identity(target/'derive.json')
            for item in report['inputs']:
                assert file_identity(item['file']) == item, 'input changed: '+item['file']
            for p in dependencies:
                if p != node and p not in [attempt/'attempt.json', baseline_attempt/'attempt.json']:
                    assert file_identity(p)['sha256'] == file_identity(out/'consumed'/p.name)['sha256']
            report['compilers'] = compilers
            report['complete'] = report['pass'] = True
        except Exception as error:
            report['error'] = repr(error)
            raise
        finally:
            save(out/'derive.json', report)
    print(json.dumps(dict(complete=True, cohorts=[str(out/c) for c in cases])))


if __name__ == '__main__':
    main()
