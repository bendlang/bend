#!/usr/bin/env python3
"""Compare mechanism ablations with the maintained unprofiled program worker."""
import argparse
import json
import os
from pathlib import Path
import shutil
import statistics
import sys
import time

ROOT = Path(__file__).resolve().parents[4]
PROGRAMS = ROOT / 'selfhost/tools/performance/programs'
sys.path.insert(0, str(PROGRAMS))
from support import ExecutionGuard, identity, save

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('config', type=Path)
p.add_argument('out', type=Path)
p.add_argument('--node', required=True)
p.add_argument('--cpu', type=int, default=3)
p.add_argument('--budget', type=int, choices=[20, 60, 300, 600], default=60)
a = p.parse_args()
begin = time.monotonic()
out = a.out.resolve()
out.mkdir(parents=True, exist_ok=False)
config = json.loads(a.config.read_text())
warm, target, rounds = (100, 50, 3) if a.budget == 20 else (350, 150, 3) if a.budget == 60 else (1000, 300, 5)
inputs = [identity(x) for x in [__file__, a.config, a.node, PROGRAMS/'execute.mjs', PROGRAMS/'support.py']]
inputs += [identity(x) for x in config.get('inputs', [])]
report = dict(complete=False, passed=False, scope='Supplemental mechanism experiment, not a compiler release or a replacement for the unchanged program catalog.',
              config=config, inputs=inputs, rounds=rounds, warmupMs=warm, targetMs=target, cases=[])
shutil.copyfile(__file__, out/'consumed-compare.py')
shutil.copyfile(PROGRAMS/'execute.mjs', out/'execute.mjs')
shutil.copyfile(PROGRAMS/'support.py', out/'support.py')
save(out/'report.json', report)
try:
    with ExecutionGuard(1536, 2048) as guard:
        for case in config['cases']:
            assert case['id'].replace('-', '').isalnum()
            directory = out/case['id']
            directory.mkdir()
            roles = list(case['modules'])
            assert roles and len(roles) == len(set(roles))
            modules = {}
            for role, source in case['modules'].items():
                assert role.replace('-', '').isalnum()
                source = Path(source).resolve()
                inputs.append(identity(source))
                destination = directory/(role+source.suffix)
                shutil.copyfile(source, destination)
                inputs.append(identity(destination))
                modules[role] = destination
            point = {**case['point'], 'warmupCalls':3, 'warmupMs':warm,
                     'calibrationMs':min(50, target/2), 'targetMs':target, 'maxRepetitions':1000000}
            save(directory/'point.json', point)
            inputs.append(identity(directory/'point.json'))
            row = dict(id=case['id'], point=point, samples=[], summary={})
            report['cases'].append(row)
            for rotation in range(rounds):
                for role in roles[rotation % len(roles):] + roles[:rotation % len(roles)]:
                    sample = directory/f'{rotation}-{role}.json'
                    command = ['taskset', '-c', str(a.cpu), a.node, '--stack-size=4096', '--max-old-space-size=1024',
                               str(out/'execute.mjs'), str(modules[role]), str(directory/'point.json'), str(sample)]
                    process = guard.run(command, directory/f'{rotation}-{role}-process', begin+a.budget)
                    result = json.loads(sample.read_text()) if sample.exists() else {}
                    row['samples'].append(dict(role=role, rotation=rotation, process=process, result=result))
                    save(out/'report.json', report)
                    assert process['complete'] and result.get('complete') and result.get('pass'), 'Failed or incomplete observation'
            for role in roles:
                values = [s['result']['msPerCall'] for s in row['samples'] if s['role'] == role]
                assert len(values) == rounds
                row['summary'][role] = dict(median=statistics.median(values), minimum=min(values), maximum=max(values), samples=values)
        for item in inputs:
            assert identity(item['path']) == item, 'Input changed: '+item['path']
        report.update(complete=True, passed=True)
except Exception as error:
    report['error'] = repr(error)
finally:
    report['wallSeconds'] = time.monotonic()-begin
    save(out/'report.json', report)
    lines = ['# Supplemental mechanism comparison', '', report['scope'], '',
             f"Complete: {report['complete']}; wall {report['wallSeconds']:.3f}s.", '',
             '| Case | Variant | Median ms | Minimum ms | Maximum ms |', '|---|---|---:|---:|---:|']
    for case in report['cases']:
        for role, s in case['summary'].items():
            lines.append(f"| {case['id']} | {role} | {s['median']:.6g} | {s['minimum']:.6g} | {s['maximum']:.6g} |")
    (out/'report.md').write_text('\n'.join(lines)+'\n')
print(json.dumps({k:report.get(k) for k in ['complete','passed','wallSeconds','error']}))
raise SystemExit(0 if report['passed'] else 1)
