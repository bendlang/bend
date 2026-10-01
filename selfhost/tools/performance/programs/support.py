"""Small Linux process supervisor shared by preparation and timing."""
import fcntl
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import time

ROOT = Path(__file__).resolve().parents[4]


def identity(file):
    file = Path(file).resolve()
    digest = hashlib.sha256()
    with file.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return dict(path=str(file), sha256=digest.hexdigest(), bytes=file.stat().st_size)


def save(file, value):
    file = Path(file)
    temporary = file.with_name(file.name + '.tmp')
    temporary.write_text(json.dumps(value, indent=2) + '\n')
    temporary.replace(file)


def available_bytes():
    return int(next(line.split()[1] for line in Path('/proc/meminfo').read_text().splitlines()
                    if line.startswith('MemAvailable:'))) * 1024


def process_stat(pid):
    try:
        raw = Path(f'/proc/{pid}/stat').read_text()
        fields = raw[raw.rfind(')') + 2:].split()
        return fields[19], int(fields[21]) * os.sysconf('SC_PAGE_SIZE')
    except (FileNotFoundError, ProcessLookupError):
        return None


class ExecutionGuard:
    """One lock, serial children, conservative RSS sums and bounded cleanup.

    Polling is not a hard kernel memory ceiling. CPU/heap flags belong to the
    explicit child command. SIGINT/SIGTERM stop the current job and preserve its
    receipt; callers must inspect interrupted before launching another job.
    """
    def __init__(self, rss_mib=1024, available_mib=2048, lock_path=None):
        self.rss_limit = rss_mib * 1024**2
        self.available_floor = available_mib * 1024**2
        self.lock_path = Path(lock_path or ROOT / 'selfhost/build/phase32/execution.lock')
        self.interrupted = None
        self.active = None
        self.seen = {}

    def __enter__(self):
        self.lock_path.parent.mkdir(parents=True, exist_ok=True)
        self.lock = self.lock_path.open('a')
        try:
            fcntl.flock(self.lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            self.lock.close()
            raise RuntimeError('Another compiler/benchmark job holds the execution lock')
        self.handlers = {sig: signal.signal(sig, self._signal)
                         for sig in (signal.SIGINT, signal.SIGTERM)}
        return self

    def _signal(self, sig, _frame):
        self.interrupted = sig

    def _tree(self, pid):
        stat = process_stat(pid)
        if stat is None:
            return 0
        self.seen[pid] = stat[0]
        total = stat[1]
        try:
            children = Path(f'/proc/{pid}/task/{pid}/children').read_text().split()
            total += sum(self._tree(int(child)) for child in children)
        except (FileNotFoundError, ProcessLookupError):
            pass
        return total

    def _stop(self):
        # The leader owns a new session. Kill its original process group even
        # if it already exited, so ordinary surviving grandchildren cannot leak.
        if self.active is not None:
            stat = process_stat(self.active.pid)
            if stat is None or stat[0] == self.seen.get(self.active.pid):
                try:
                    os.killpg(self.active.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
        for pid, start in reversed(list(self.seen.items())):
            stat = process_stat(pid)
            if stat is not None and stat[0] == start:
                try:
                    os.killpg(pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                try:
                    os.kill(pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass

    def run(self, command, directory, deadline, env=None):
        directory = Path(directory)
        directory.mkdir(parents=True, exist_ok=False)
        begin = time.monotonic()
        report = dict(complete=False, command=list(map(str, command)), started=time.time(),
                      rssLimitBytes=self.rss_limit, availableFloorBytes=self.available_floor,
                      peakTreeRssBytes=0, minimumAvailableBytes=available_bytes())
        save(directory / 'process.json', report)
        clean_env = {k: v for k, v in os.environ.items()
                     if not k.startswith('BEND_') and k not in ('NODE_OPTIONS', 'NODE_PATH')}
        clean_env.update(env or {})
        self.seen = {}
        try:
            if self.interrupted:
                report['stoppedFor'] = 'signal'
            elif begin >= deadline:
                report['stoppedFor'] = 'deadline'
            elif available_bytes() < self.available_floor:
                report['stoppedFor'] = 'host-headroom'
            else:
                with (directory / 'stdout.log').open('w') as stdout, (directory / 'stderr.log').open('w') as stderr:
                    self.active = subprocess.Popen(report['command'], stdout=stdout, stderr=stderr,
                                                   env=clean_env, start_new_session=True)
                    self._tree(self.active.pid)
                    while self.active.poll() is None:
                        rss, free = self._tree(self.active.pid), available_bytes()
                        report['peakTreeRssBytes'] = max(report['peakTreeRssBytes'], rss)
                        report['minimumAvailableBytes'] = min(report['minimumAvailableBytes'], free)
                        reason = ('signal' if self.interrupted else
                                  'tree-rss-limit' if rss > self.rss_limit else
                                  'host-headroom' if free < self.available_floor else
                                  'deadline' if time.monotonic() >= deadline else None)
                        if reason:
                            report['stoppedFor'] = reason
                            break
                        time.sleep(0.02)
                    self._stop()
                    report['returncode'] = self.active.wait(timeout=2)
                report['complete'] = report.get('returncode') == 0 and 'stoppedFor' not in report
        except Exception as error:
            report['error'] = repr(error)
        finally:
            self._stop()
            if self.active is not None:
                self.active.wait(timeout=2)
            self.active = None
            report.update(wallSeconds=time.monotonic() - begin, finished=time.time())
            save(directory / 'process.json', report)
        return report

    def __exit__(self, *_args):
        self._stop()
        for sig, handler in self.handlers.items():
            signal.signal(sig, handler)
        self.lock.close()
