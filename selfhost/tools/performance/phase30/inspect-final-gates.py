#!/usr/bin/env python3
"""Run the already frozen selected gates for one acquisition CPU, serially."""
from pathlib import Path
import hashlib, json, os, subprocess, sys, time

plan_file = Path(sys.argv[1]).resolve()
cpu = int(sys.argv[2])
plan = json.loads(plan_file.read_text())
assert plan['complete'] and not plan['executed'] and cpu in [4, 7]
out = plan_file.parent / ('gate-launch-cpu' + str(cpu))
out.mkdir(exist_ok=False)
root = Path(__file__).resolve().parents[4]
env = {k: v for k, v in os.environ.items()
       if not k.startswith('BEND_') and k not in ['NODE_OPTIONS', 'NODE_PATH']}

def identity(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
            'bytes': p.stat().st_size}

def save():
    (out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')

def verify():
    for entry in plan['inputs']:
        assert identity(entry['file']) == entry, entry['file']

verify()
report = {'kind': 'phase30-frozen-final-selected-gate-launch', 'complete': False,
          'pass': False, 'cpu': cpu, 'plan': identity(plan_file),
          'launcher': identity(Path(__file__)), 'steps': [],
          'scope': 'Acquisition/validation only. No comparative performance inference.'}
(out / 'consumed-launcher.py').write_bytes(Path(__file__).read_bytes())
save()
for selected in plan['commands']:
    if selected['kind'] != 'gate' or selected['cpu'] != cpu:
        continue
    name = selected['name']
    timeout = 120 if name == 'worker-admission' else 1200
    row = {'name': name, 'command': selected['command'], 'complete': False,
           'started': time.time(), 'outerTimeoutSeconds': timeout}
    report['steps'].append(row)
    save()
    start = time.monotonic()
    with (out / (name + '.stdout')).open('w') as stdout, (out / (name + '.stderr')).open('w') as stderr:
        try:
            result = subprocess.run(row['command'], cwd=root, env=env,
                                    stdout=stdout, stderr=stderr, timeout=timeout)
            row['exitCode'] = result.returncode
        except subprocess.TimeoutExpired:
            row['timeout'] = True
    row.update(wallSeconds=time.monotonic() - start, finished=time.time(),
               stdout=identity(out / (name + '.stdout')),
               stderr=identity(out / (name + '.stderr')))
    row['complete'] = row.get('exitCode') == 0 and not row.get('timeout', False)
    save()
    print(json.dumps({'name': name, 'complete': row['complete'], 'cpu': cpu}), flush=True)
verify()
report['complete'] = True
report['pass'] = bool(report['steps']) and all(x['complete'] for x in report['steps'])
save()
raise SystemExit(0 if report['pass'] else 1)
