#!/usr/bin/env python3
"""One serial, supervised final-API owner gate for recursive private folds."""
import argparse
import json
from pathlib import Path
import shutil
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PROGRAMS = HERE.parent/'programs'
sys.path.insert(0, str(PROGRAMS))
from support import ExecutionGuard, identity, save


def ident(file):
    row = identity(file)
    row['file'] = row.pop('path')
    return row


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('attempt', type=Path)
    parser.add_argument('out', type=Path)
    parser.add_argument('--baseline', type=Path, default=ROOT/'selfhost/build/phase32/attempt-03')
    parser.add_argument('--upstream', type=Path, default=ROOT/'selfhost/.bootstrap/upstream-phase23')
    args = parser.parse_args()
    attempt, out = args.attempt.resolve(), args.out.resolve()
    manifest = json.loads((attempt/'attempt.json').read_text())
    assert manifest['checked'] and manifest['config']['strictExact']
    node = Path(manifest['node']['file'])
    assert ident(node)['sha256'] == manifest['node']['sha256']
    inputs = [Path(__file__), HERE/'fold-recursive.bend', HERE/'fold-controls.mjs', HERE/'fold-guards.mjs',
              PROGRAMS/'emit-worker.mjs', PROGRAMS/'support.py', PROGRAMS/'catalog.json',
              ROOT/'selfhost/tools/development/workflow.mjs', ROOT/'selfhost/tools/development/release.mjs',
              attempt/'attempt.json', args.baseline/'attempt.json', Path(manifest['api']['file']), node]
    report = dict(kind='phase35-final-recursive-fold-owner', complete=False, owner='recursive-folds',
                  inputs=[ident(p) for p in inputs], processes=[], reports=[], api=manifest['api'],
                  protocol=dict(cpu=3, heapMiB=1024, treeRssMiB=2048, availableMiB=2048, serial=True))
    report['pass'] = False
    with ExecutionGuard(rss_mib=2048, available_mib=2048) as guard:
        out.mkdir(parents=True, exist_ok=False)
        (out/'consumed').mkdir()
        for source in inputs:
            if source in [node, attempt/'attempt.json', args.baseline/'attempt.json', Path(manifest['api']['file'])]:
                continue
            shutil.copyfile(source, out/'consumed'/source.name)
        save(out/'report.json', report)
        try:
            cohort = out/'cohort'
            cohort.mkdir()
            source = out/'consumed/fold-recursive.bend'
            derived = dict(complete=False, source=ident(source), variants={}, emissions={})
            for role, selection in [('baseline', str(args.baseline.resolve())), ('candidate', str(attempt)),
                                    ('typescript', 'upstream:'+str(args.upstream.resolve()))]:
                module = cohort/(role+'.mjs')
                command = ['taskset', '-c', '3', str(node), '--stack-size=4096', '--max-old-space-size=1024',
                           str(PROGRAMS/'emit-worker.mjs'), selection, str(source), str(module)]
                process = guard.run(command, cohort/('emit-'+role), time.monotonic()+180)
                report['processes'].append(process)
                save(out/'report.json', report)
                assert process['complete'], 'checked emission failed: '+role
                emitted = json.loads(Path(str(module)+'.json').read_text())
                assert emitted['complete'] and emitted['observation']['checked']
                assert emitted['input']['sha256'] == ident(source)['sha256']
                assert emitted['output']['sha256'] == ident(module)['sha256']
                if role == 'candidate':
                    assert emitted['compiler']['api']['sha256'] == manifest['api']['sha256']
                derived['variants'][role] = ident(module)
                derived['emissions'][role] = ident(str(module)+'.json')
                save(cohort/'derive.json', derived)
            derived['complete'] = True
            save(cohort/'derive.json', derived)
            save(out/'config.json', dict(api=manifest['api']['file']))
            for name, arg in [('fold-controls', cohort), ('fold-guards', out/'config.json')]:
                target = out/name
                command = ['taskset', '-c', '3', str(node), '--stack-size=4096', '--max-old-space-size=1024',
                           str(HERE/(name+'.mjs')), str(arg), str(target)]
                process = guard.run(command, out/('run-'+name), time.monotonic()+120)
                report['processes'].append(process)
                save(out/'report.json', report)
                assert process['complete'], 'controls failed: '+name
                receipt = json.loads((target/'report.json').read_text())
                assert receipt['complete'] and receipt['pass']
                report['reports'].append(ident(target/'report.json'))
            for row in report['inputs']:
                assert ident(row['file']) == row, 'input changed during gate: '+row['file']
            report['complete'] = report['pass'] = True
        except Exception as error:
            report['error'] = repr(error)
            raise
        finally:
            save(out/'report.json', report)
    print(json.dumps(dict(complete=True, passed=True, report=str(out/'report.json'))))


if __name__ == '__main__':
    main()
