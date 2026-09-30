#!/usr/bin/env python3
"""One root-granted B1->H emission with bounded preflight/cache/functional gates."""
from pathlib import Path
import hashlib
import json
import os
import resource
import signal
import subprocess
import sys
import time

plan_file = Path(sys.argv[1]).resolve()
plan = json.loads(plan_file.read_text())
assert plan['complete'] and not plan['executed'] and plan['kind'] == 'phase30-bounded-self-emission-plan'
out = plan_file.parent / 'execution'
out.mkdir(exist_ok=False)
root = Path(__file__).resolve().parents[4]
worker = Path(__file__).resolve().with_name('inspect-self-emission-oracle.mjs')


def identity(file):
    file = Path(file).resolve()
    data = file.read_bytes()
    return {'file': str(file), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}


def verify():
    for item in plan['inputs']:
        assert identity(item['file'])['sha256'] == item['sha256'], item['file']


report = {'kind': 'phase30-bounded-self-emission', 'complete': False, 'pass': False,
          'plan': identity(plan_file), 'producer': identity(Path(__file__)),
          'inputs': [identity(worker), identity(root / 'design/phase30/self-emission-schedule-amendment.md')],
          'steps': [], 'started': time.time(), 'resources': plan['resources'],
          'osStackLimitBytes': list(resource.getrlimit(resource.RLIMIT_STACK)),
          'scope': 'One B1->H acquisition and small functional gates. Concurrent correctness work; no controlled speed ratio, H->H, fixed point or installation.'}
(out / 'consumed-run.py').write_bytes(Path(__file__).read_bytes())


def save():
    (out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')


active = None
environment = {k: v for k, v in os.environ.items()
               if not k.startswith('BEND_') and k not in ['NODE_OPTIONS', 'NODE_PATH']}
environment.update(plan['emissionEnvironment'])
node = [plan['node']['file'], *plan['resources']['nodeArgs']]
prefix = ['taskset', '-c', plan['resources']['cpu']]


def launch(name, command, timeout, gate=None):
    global active
    verify()
    row = {'name': name, 'command': list(map(str, command)), 'timeoutSeconds': timeout,
           'started': time.time(), 'complete': False}
    report['steps'].append(row)
    save()
    start = time.monotonic()
    stdout_file, stderr_file = out / (name + '.stdout'), out / (name + '.stderr')
    with stdout_file.open('x') as stdout, stderr_file.open('x') as stderr:
        active = subprocess.Popen(row['command'], cwd=root, env=environment,
                                  stdout=stdout, stderr=stderr, start_new_session=True)
        while True:
            pid, status, usage = os.wait4(active.pid, os.WNOHANG)
            if pid:
                active.returncode = os.waitstatus_to_exitcode(status)
                row.update(exitCode=active.returncode, maxRssKiB=usage.ru_maxrss,
                           userSeconds=usage.ru_utime, systemSeconds=usage.ru_stime)
                break
            if time.monotonic() - start >= timeout:
                row['timeout'] = True
                os.killpg(active.pid, signal.SIGKILL)
                _, status, usage = os.wait4(active.pid, 0)
                active.returncode = os.waitstatus_to_exitcode(status)
                row.update(exitCode=active.returncode, maxRssKiB=usage.ru_maxrss,
                           userSeconds=usage.ru_utime, systemSeconds=usage.ru_stime)
                break
            time.sleep(0.2)
    row.update(wallSeconds=time.monotonic() - start, finished=time.time(),
               stdout=identity(stdout_file), stderr=identity(stderr_file))
    save()
    assert row['exitCode'] == 0 and not row.get('timeout'), 'Failed step: ' + name
    if gate is not None:
        data = json.loads(gate.read_text())
        assert data['complete'] and data['pass'], 'Functional gate did not pass: ' + name
        row['gate'] = identity(gate)
    verify()
    row['complete'] = True
    active = None
    save()
    print(json.dumps({'step': name, 'complete': True, 'wallSeconds': row['wallSeconds']}), flush=True)


save()
try:
    verify()
    limit = report['osStackLimitBytes'][0]
    assert limit == resource.RLIM_INFINITY or limit >= plan['resources']['minimumOsStackKiB'] * 1024
    assert not Path(plan['output']).exists() and not Path(plan['output'] + '.json').exists()
    preflight = out / 'preflight'
    launch('preflight', prefix + node + [worker, plan_file, plan['api']['file'], preflight, 'oracle'],
           plan['resources']['oracleTimeoutSeconds'], preflight / 'report.json')
    launch('emission', plan['emissionCommand'], plan['resources']['emissionTimeoutSeconds'])
    emitted = Path(plan['output'])
    receipt_file = Path(str(emitted) + '.json')
    receipt = json.loads(receipt_file.read_text())
    assert receipt['complete'] and receipt['observation']['status'] == 'ok' and receipt['observation']['checked']
    assert receipt['attempt']['sha256'] == plan['attempt']['sha256']
    assert receipt['input']['sha256'] == plan['source']['sha256'] and receipt['output']['sha256'] == identity(emitted)['sha256']
    report['generatedCompiler'], report['emissionReceipt'] = identity(emitted), identity(receipt_file)
    save()
    launch('syntax', prefix + node + ['--check', emitted], plan['resources']['oracleTimeoutSeconds'])
    base = out / 'h-base'
    launch('h-base', prefix + node + [worker, plan_file, emitted, base, 'base'],
           plan['resources']['oracleTimeoutSeconds'], base / 'report.json')
    oracle = out / 'h-oracle'
    launch('h-oracle', prefix + node + [worker, plan_file, emitted, oracle, 'oracle', preflight / 'report.json'],
           plan['resources']['oracleTimeoutSeconds'], oracle / 'report.json')
    verify()
    report['complete'] = True
    report['pass'] = True
except BaseException as error:
    report['error'] = repr(error)
finally:
    if active is not None:
        try:
            os.killpg(active.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        if active.returncode is None:
            try:
                _, status, _ = os.wait4(active.pid, 0)
                active.returncode = os.waitstatus_to_exitcode(status)
            except ChildProcessError:
                pass
    report['finished'] = time.time()
    report['wallSeconds'] = report['finished'] - report['started']
    save()
print(json.dumps({key: report.get(key) for key in ['complete', 'pass', 'wallSeconds', 'error']}))
raise SystemExit(0 if report['pass'] else 1)
