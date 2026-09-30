#!/usr/bin/env python3
"""Freeze and journal the final serial batch without changing its child protocols."""
from pathlib import Path
import datetime, hashlib, json, os, shutil, statistics, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[4]
RAW = ROOT / 'selfhost/build/phase30'
TOOLS = ROOT / 'selfhost/tools/performance'
NODE = Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')

def ident(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}

def save(p, value):
    Path(p).write_text(json.dumps(value, indent=2) + '\n')

def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()

def summarize(report):
    result = {'complete': report.get('complete'), 'cases': []}
    for case in report.get('cases', []):
        sides = {}
        for name, side in case.get('sides', {}).items():
            drift = []
            for sample in case.get('samples', []):
                if sample.get('variant') != name:
                    continue
                halves = sample.get('result', {}).get('halves', [])
                if len(halves) == 2 and all(h['calls'] > 0 and h['ms'] > 0 for h in halves):
                    drift.append(100 * ((halves[1]['ms'] / halves[1]['calls']) / (halves[0]['ms'] / halves[0]['calls']) - 1))
            sides[name] = {**{k: side[k] for k in ['medianMs', 'minMs', 'maxMs']}, 'halfDriftPercent': drift}
        result['cases'].append({'id': case['id'], 'complete': case.get('complete'), 'sides': sides})
    if 'statistics' in report:
        result['statistics'] = report['statistics']
    if report.get('kind') == 'phase23-cross-revision-check-matrix':
        result['requestMediansMs'] = {name: statistics.median(r['observation']['requestMs'] for r in report['rows'] if r['variant'] == name) for name in report['variants']}
        result['processMediansMs'] = {name: statistics.median(r['execution']['wallMs'] for r in report['rows'] if r['variant'] == name) for name in report['variants']}
    return result

def prepare(out):
    out.mkdir(parents=True, exist_ok=False)
    transfer = RAW / 'final-transfer-plan-14/plan.json'
    integration = RAW / 'final-integration-plan-14/plan.json'
    jobs = []
    for entry in json.loads(transfer.read_text())['commands']:
        jobs.append({'id': entry['case'], 'command': entry['command'], 'output': entry['command'][-1], 'cpu': 3, 'kind': 'original-program', 'config': entry['config']['file']})
    compiler = next(c for c in json.loads(integration.read_text())['commands'] if c['name'] == 'compiler-ordinary-check')
    jobs.append({'id': 'compiler-cost', 'command': compiler['command'], 'output': compiler['command'][-1], 'cpu': 0, 'kind': 'compiler-check', 'config': compiler['command'][-2]})
    lib_config = RAW / 'library-cost-plan-14/config.json'
    lib_out = RAW / 'library-cost-14'
    jobs.append({'id': 'library-cost-14', 'command': [str(NODE), str(TOOLS / 'phase30/library-cost-run.mjs'), str(lib_config), str(lib_out)], 'output': str(lib_out), 'cpu': 0, 'kind': 'checked-library', 'config': str(lib_config)})
    scaling_config = RAW / 'scalar-scaling-plan-14/confirm.json'
    scaling_out = RAW / 'scalar-scaling-confirm-14'
    jobs.append({'id': 'scalar-scaling-confirm-14', 'command': [sys.executable, str(TOOLS / 'phase30/prototype-time.py'), str(scaling_config), str(scaling_out)], 'output': str(scaling_out), 'cpu': 3, 'kind': 'helper-scaling', 'config': str(scaling_config)})
    inputs = {str(p.resolve()): ident(p) for p in [Path(__file__), transfer, integration, ROOT / 'design/phase30/final-timing-batch.md']}
    for job in jobs:
        assert not Path(job['output']).exists(), job['output']
        for p in [Path(job['command'][0]), Path(job['command'][1]), Path(job['config'])]:
            inputs[str(p.resolve())] = ident(p)
        config = json.loads(Path(job['config']).read_text())
        for item in config.get('inputs', []):
            actual = ident(item['file'])
            assert actual['sha256'] == item['sha256'], item['file']
            inputs[actual['file']] = actual
    plan = {'kind': 'phase30-final-clean-batch-plan', 'complete': True, 'executed': False, 'created': utc(), 'inputs': list(inputs.values()), 'jobs': jobs, 'scope': 'Exclusive serial existing protocols; no extra confirmation, retuning or retries.'}
    save(out / 'plan.json', plan)
    shutil.copyfile(__file__, out / 'consumed-launcher.py')
    print(json.dumps({'plan': str(out / 'plan.json'), 'jobs': len(jobs), 'inputs': len(inputs)}), flush=True)

def run(plan_path, out):
    plan = json.loads(plan_path.read_text())
    assert plan['complete'] and len(plan['jobs']) == 13
    out.mkdir(parents=True, exist_ok=False)
    receipt = {'kind': 'phase30-final-clean-batch', 'complete': False, 'started': utc(), 'plan': ident(plan_path), 'launcher': ident(Path(__file__)), 'pid': os.getpid(), 'jobs': []}
    save(out / 'report.json', receipt)
    begin = time.monotonic()
    for job in plan['jobs']:
        for item in plan['inputs']:
            assert ident(item['file']) == item, item['file']
        assert not Path(job['output']).exists(), job['output']
        row = {**job, 'started': utc(), 'complete': False}
        receipt['jobs'].append(row)
        save(out / 'report.json', receipt)
        print(json.dumps({'event': 'start', 'job': job['id'], 'utc': row['started']}), flush=True)
        start = time.monotonic()
        stdout, stderr = out / (job['id'] + '.stdout'), out / (job['id'] + '.stderr')
        with stdout.open('w') as so, stderr.open('w') as se:
            child = subprocess.Popen(job['command'], cwd=ROOT, stdout=so, stderr=se)
            row['pid'] = child.pid
            save(out / 'report.json', receipt)
            row['exitCode'] = child.wait()
        row.update(finished=utc(), wallSeconds=time.monotonic() - start, stdout=ident(stdout), stderr=ident(stderr))
        report_path = Path(job['output']) / 'report.json'
        if report_path.exists():
            child_report = json.loads(report_path.read_text())
            row.update(report=ident(report_path), summary=summarize(child_report))
            row['complete'] = row['exitCode'] == 0 and child_report.get('complete', False) and child_report.get('allCasesMeasured', True) and child_report.get('pass', True)
        save(out / 'report.json', receipt)
        print(json.dumps({'event': 'finish', 'job': job['id'], 'complete': row['complete'], 'wallSeconds': row['wallSeconds'], 'summary': row.get('summary')}), flush=True)
        if not row['complete']:
            raise SystemExit(1)
    for item in plan['inputs']:
        assert ident(item['file']) == item, item['file']
    receipt.update(complete=True, finished=utc(), wallSeconds=time.monotonic() - begin)
    save(out / 'report.json', receipt)
    print(json.dumps({'event': 'batch-complete', 'jobs': len(receipt['jobs']), 'wallSeconds': receipt['wallSeconds']}), flush=True)

if sys.argv[1] == 'prepare':
    prepare(Path(sys.argv[2]).resolve())
elif sys.argv[1] == 'run':
    run(Path(sys.argv[2]).resolve(), Path(sys.argv[3]).resolve())
else:
    raise SystemExit('expected prepare OUT or run PLAN OUT')
