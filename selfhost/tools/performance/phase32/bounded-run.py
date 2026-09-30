#!/usr/bin/env python3
"""Serialize experiment processes and stop their tree before memory exhaustion."""
import argparse, fcntl, hashlib, json, os, signal, subprocess, time
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('--seconds', type=int, default=180)
p.add_argument('--rss-mib', type=int, default=2048)
p.add_argument('--available-mib', type=int, default=2048)
p.add_argument('out')
p.add_argument('command', nargs=argparse.REMAINDER)
a = p.parse_args()
assert 1 <= a.seconds <= 3600 and 128 <= a.rss_mib <= 4096
assert a.available_mib >= 1024 and a.command
out = Path(a.out).resolve(); out.mkdir(parents=True, exist_ok=False)
root = Path(__file__).resolve().parents[4]
lock = (root / 'selfhost/build/phase32/execution.lock').open('a')
fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
command = a.command[1:] if a.command[0] == '--' else a.command
def identity(path):
    path = Path(path).resolve()
    return dict(file=str(path), bytes=path.stat().st_size,
                sha256=hashlib.sha256(path.read_bytes()).hexdigest())
def available():
    return int(next(l.split()[1] for l in Path('/proc/meminfo').read_text().splitlines()
                    if l.startswith('MemAvailable:'))) * 1024
def stat(pid):
    try:
        text = Path(f'/proc/{pid}/stat').read_text()
        fields = text[text.rfind(')')+2:].split()
        return fields[19], int(fields[21]) * os.sysconf('SC_PAGE_SIZE')
    except (FileNotFoundError, ProcessLookupError):
        return None
seen = {}
def tree(pid):
    current = stat(pid)
    if current is None: return 0
    seen[pid] = current[0]
    total = current[1]
    try:
        for child in Path(f'/proc/{pid}/task/{pid}/children').read_text().split():
            total += tree(int(child))
    except (FileNotFoundError, ProcessLookupError): pass
    return total
def stop():
    for pid, ticks in reversed(list(seen.items())):
        current = stat(pid)
        if current is None or current[0] != ticks: continue
        try: os.killpg(pid, signal.SIGKILL)
        except (ProcessLookupError, PermissionError): pass
        try: os.kill(pid, signal.SIGKILL)
        except ProcessLookupError: pass
report = dict(complete=False, command=command, cwd=str(Path.cwd()),
              producer=identity(__file__), secondsLimit=a.seconds,
              rssLimitBytes=a.rss_mib*1024**2, availableFloorBytes=a.available_mib*1024**2,
              started=time.time(), peakTreeRssBytes=0, minimumAvailableBytes=available(),
              scope='Supervised acquisition; RSS sums may double-count shared pages. No throughput claim.')
def save():
    temp = out / 'run.tmp'
    temp.write_text(json.dumps(report, indent=2)+'\n'); temp.replace(out/'run.json')
save(); (out/'consumed-bounded-run.py').write_bytes(Path(__file__).read_bytes())
assert available() >= report['availableFloorBytes'], 'Insufficient memory headroom before launch'
env = {k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
begin = time.monotonic()
with (out/'stdout.log').open('w') as stdout, (out/'stderr.log').open('w') as stderr:
    child = subprocess.Popen(command, stdout=stdout, stderr=stderr, env=env, start_new_session=True)
    try:
        while child.poll() is None:
            rss = tree(child.pid); free = available()
            report['peakTreeRssBytes'] = max(report['peakTreeRssBytes'], rss)
            report['minimumAvailableBytes'] = min(report['minimumAvailableBytes'], free)
            reason = ('tree-rss-limit' if rss > report['rssLimitBytes'] else
                      'host-headroom' if free < report['availableFloorBytes'] else
                      'deadline' if time.monotonic()-begin > a.seconds else None)
            if reason:
                report['stoppedFor'] = reason; stop(); break
            time.sleep(0.1)
        report['returncode'] = child.wait(timeout=5)
    finally:
        stop()
report.update(wallSeconds=time.monotonic()-begin, finished=time.time(),
              stdout=identity(out/'stdout.log'), stderr=identity(out/'stderr.log'))
report['complete'] = report['returncode'] == 0 and 'stoppedFor' not in report
save()
print(json.dumps({k:report[k] for k in ['complete','returncode','wallSeconds','peakTreeRssBytes','minimumAvailableBytes']}))
raise SystemExit(0 if report['complete'] else 1)
