#!/usr/bin/env python3
"""Archive closed Phase35 evidence as one verified stream in <=40 MiB volumes.

Capture is root-orchestrated only, after all jobs and report writers have closed.
File contents and compressed volumes are streamed; only inventory metadata is
kept in memory. No compiler, benchmark, network request or external tool is run.
"""
import argparse
from datetime import datetime, timezone
import fcntl
import gzip
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import stat
import sys
import tarfile

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT/'selfhost/build/phase35'
OUT = Path(__file__).resolve().parent
LOCK = ROOT/'selfhost/build/phase32/execution.lock'
CHUNK = 1024*1024
MAX_VOLUME = 40*1024*1024
PREFIX = 'validation.tar.gz.part-'


def now():
    return datetime.now(timezone.utc).isoformat()


def digest_stream(stream):
    digest, size = hashlib.sha256(), 0
    while True:
        chunk = stream.read(CHUNK)
        if not chunk:
            return digest.hexdigest(), size
        digest.update(chunk)
        size += len(chunk)


def identity(file):
    with file.open('rb') as stream:
        digest, size = digest_stream(stream)
    return dict(path=str(file), bytes=size, sha256=digest)


def save(file, value, replace=False):
    if not replace:
        with file.open('x', encoding='utf8') as stream:
            json.dump(value, stream, indent=2)
            stream.write('\n')
        return
    temporary = file.with_name(file.name+'.tmp')
    with temporary.open('x', encoding='utf8') as stream:
        json.dump(value, stream, indent=2)
        stream.write('\n')
    temporary.replace(file)


def safe_name(name):
    path = PurePosixPath(name)
    if not name or path.is_absolute() or any(p in ('', '.', '..') for p in path.parts):
        raise ValueError('Unsafe archive member: '+repr(name))
    if str(path) != name or '\\' in name or '\x00' in name:
        raise ValueError('Noncanonical archive member: '+repr(name))
    return name


def fingerprint(value):
    return (value.st_dev, value.st_ino, value.st_mode, value.st_size,
            value.st_mtime_ns, value.st_ctime_ns)


def inventory(source):
    """Hash every regular file, retain empty directories, refuse special files."""
    if source.is_symlink() or not source.is_dir():
        raise ValueError('Source must be an ordinary directory: '+str(source))
    files, directories, excluded = [], [], []
    for parent, children, names in os.walk(source, followlinks=False):
        children.sort()
        names.sort()
        for name in children:
            file = Path(parent)/name
            mode = file.lstat().st_mode
            if not stat.S_ISDIR(mode):
                raise ValueError('Symlink or special directory: '+str(file))
            directories.append(dict(path=safe_name(file.relative_to(source).as_posix()),
                                    mode=stat.S_IMODE(mode)))
        for name in names:
            file = Path(parent)/name
            relative = safe_name(file.relative_to(source).as_posix())
            before = file.lstat()
            if not stat.S_ISREG(before.st_mode):
                raise ValueError('Symlink or special file: '+str(file))
            # Do not drop arbitrary files just because a parent is __pycache__.
            if file.suffix in ('.pyc', '.pyo'):
                excluded.append(relative)
                continue
            with file.open('rb') as stream:
                opened = os.fstat(stream.fileno())
                if fingerprint(opened) != fingerprint(before):
                    raise RuntimeError('Source replaced before hashing: '+relative)
                digest, size = digest_stream(stream)
                after = os.fstat(stream.fileno())
            if fingerprint(before) != fingerprint(after) or fingerprint(after) != fingerprint(file.lstat()):
                raise RuntimeError('Source changed while hashing: '+relative)
            if size != before.st_size:
                raise RuntimeError('Source size changed while hashing: '+relative)
            files.append(dict(path=relative, bytes=size,
                              mode=stat.S_IMODE(before.st_mode), sha256=digest))
    files.sort(key=lambda row: row['path'])
    directories.sort(key=lambda row: row['path'])
    return files, directories, sorted(excluded)


class VolumeWriter(io.RawIOBase):
    """Split a single gzip stream; all hashes are incremental, never buffered."""
    def __init__(self, out, limit):
        super().__init__()
        self.out, self.limit = out, limit
        self.sink = None
        self.current_size = 0
        self.current_hash = None
        self.volumes = []
        self.total = 0
        self.logical_hash = hashlib.sha256()

    def writable(self):
        return True

    def _open(self):
        if len(self.volumes) >= 99999:
            raise RuntimeError('Volume count exceeds filename ordering bound')
        self.name = PREFIX+str(len(self.volumes)+1).zfill(5)
        self.sink = (self.out/self.name).open('xb')
        self.current_size, self.current_hash = 0, hashlib.sha256()

    def _finish(self):
        if self.sink is None:
            return
        self.sink.flush()
        os.fsync(self.sink.fileno())
        self.sink.close()
        row = dict(path=self.name, bytes=self.current_size,
                   sha256=self.current_hash.hexdigest())
        self.volumes.append(row)
        self.sink = None
        print(json.dumps(dict(stage='volume-closed', **row)), flush=True)

    def write(self, data):
        if self.closed:
            raise ValueError('Write after close')
        view, offset = memoryview(data), 0
        while offset < len(view):
            if self.sink is None:
                self._open()
            count = min(len(view)-offset, self.limit-self.current_size)
            chunk = view[offset:offset+count]
            written = self.sink.write(chunk)
            if written != count:
                raise OSError('Short volume write')
            self.current_hash.update(chunk)
            self.logical_hash.update(chunk)
            self.current_size += count
            self.total += count
            offset += count
            if self.current_size == self.limit:
                self._finish()
        return len(view)

    def flush(self):
        if self.sink is not None:
            self.sink.flush()

    def close(self):
        if not self.closed:
            self._finish()
            super().close()


class VolumeReader(io.RawIOBase):
    """Reopen consecutive files, verify each volume and concatenated bytes."""
    def __init__(self, out, rows):
        super().__init__()
        self.out, self.rows = out, rows
        self.index, self.source = 0, None
        self.current_size, self.current_hash = 0, None
        self.total, self.logical_hash = 0, hashlib.sha256()

    def readable(self):
        return True

    def _open(self):
        row = self.rows[self.index]
        file = self.out/row['path']
        info = file.lstat()
        if not stat.S_ISREG(info.st_mode) or info.st_size != row['bytes']:
            raise ValueError('Wrong volume type/size: '+row['path'])
        self.source = file.open('rb')
        self.current_size, self.current_hash = 0, hashlib.sha256()

    def _finish(self):
        row = self.rows[self.index]
        self.source.close()
        self.source = None
        if self.current_size != row['bytes'] or self.current_hash.hexdigest() != row['sha256']:
            raise ValueError('Volume hash/size mismatch: '+row['path'])
        self.index += 1

    def readinto(self, buffer):
        if not len(buffer):
            return 0
        while self.index < len(self.rows):
            if self.source is None:
                self._open()
            count = self.source.readinto(buffer)
            if count:
                view = memoryview(buffer)[:count]
                self.current_hash.update(view)
                self.logical_hash.update(view)
                self.current_size += count
                self.total += count
                return count
            self._finish()
        return 0

    def close(self):
        if self.source is not None:
            self.source.close()
            self.source = None
        super().close()


def verify(out, manifest):
    archive = manifest['archive']
    volumes = archive['volumes']
    if not volumes or archive['volumeLimitBytes'] > MAX_VOLUME:
        raise ValueError('Invalid volume declaration')
    for at, row in enumerate(volumes, 1):
        if row['path'] != PREFIX+str(at).zfill(5) or not 0 < row['bytes'] <= archive['volumeLimitBytes']:
            raise ValueError('Invalid volume ordering/size')
    if sorted(p.name for p in out.glob(PREFIX+'*')) != [row['path'] for row in volumes]:
        raise ValueError('Missing or unexpected volume files; concatenation would be ambiguous')
    if sum(row['bytes'] for row in volumes) != archive['bytes']:
        raise ValueError('Volume lengths disagree with logical gzip stream')
    files = {safe_name(row['path']): row for row in manifest['files']}
    directories = {safe_name(row['path']): row for row in manifest['directories']}
    if len(files) != len(manifest['files']) or len(directories) != len(manifest['directories']) or files.keys() & directories.keys():
        raise ValueError('Duplicate inventory paths')
    if (manifest['fileCount'] != len(files) or manifest['directoryCount'] != len(directories) or
            manifest['logicalBytes'] != sum(row['bytes'] for row in files.values())):
        raise ValueError('Inventory counts/bytes disagree with manifest totals')
    seen_files, seen_directories = set(), set()
    raw = VolumeReader(out, volumes)
    with io.BufferedReader(raw, buffer_size=CHUNK) as stream:
        with gzip.GzipFile(fileobj=stream, mode='rb') as decompressed:
            with tarfile.open(fileobj=decompressed, mode='r|') as tar:
                for member in tar:
                    name = safe_name(member.name)
                    if member.isdir():
                        if name not in directories or name in seen_directories:
                            raise ValueError('Unexpected/duplicate directory: '+name)
                        if member.mode != directories[name]['mode']:
                            raise ValueError('Directory mode mismatch: '+name)
                        seen_directories.add(name)
                    elif member.isfile():
                        if name not in files or name in seen_files:
                            raise ValueError('Unexpected/duplicate file: '+name)
                        expected = files[name]
                        with tar.extractfile(member) as contents:
                            digest, size = digest_stream(contents)
                        if (member.size != expected['bytes'] or size != expected['bytes'] or
                                member.mode != expected['mode'] or digest != expected['sha256']):
                            raise ValueError('Member size/mode/hash mismatch: '+name)
                        seen_files.add(name)
                    else:
                        raise ValueError('Unexpected archive member kind: '+name)
                    if member.uid or member.gid or member.mtime or member.uname or member.gname:
                        raise ValueError('Unexpected non-normalized tar metadata: '+name)
            # tar stops at its end markers. Drain gzip too, checking CRC/trailer
            # and all volume hashes, including bytes already read ahead by tar.
            while decompressed.read(CHUNK):
                pass
        while stream.read(CHUNK):
            pass
        if raw.index != len(volumes) or raw.total != archive['bytes'] or raw.logical_hash.hexdigest() != archive['sha256']:
            raise ValueError('Concatenated gzip hash/size mismatch')
    if seen_files != files.keys() or seen_directories != directories.keys():
        raise ValueError('Inventory coverage mismatch')
    return dict(complete=True, reopenedVerified=True, fileCount=len(files),
                directoryCount=len(directories), logicalBytes=sum(r['bytes'] for r in files.values()),
                compressedBytes=archive['bytes'], volumeCount=len(volumes),
                concatenatedGzipSha256=archive['sha256'])


def capture(source, out, limit):
    out.mkdir(parents=True, exist_ok=True)
    if source == out or source in out.parents:
        raise ValueError('Evidence output cannot be inside captured source')
    if (out/'manifest.json').exists() or (out/'capture.json').exists() or list(out.glob(PREFIX+'*')):
        raise FileExistsError('Capture output already contains an attempt; use a new --out directory')
    state = dict(kind='phase35-evidence-capture', complete=False, started=now(),
                 source=str(source), producer=identity(Path(__file__).resolve()),
                 closedInputAcknowledged=True, sharedExecutionLock=str(LOCK))
    save(out/'capture.json', state)
    try:
        files, directories, excluded = inventory(source)
        print(json.dumps(dict(stage='inventoried', files=len(files), directories=len(directories),
                              logicalBytes=sum(r['bytes'] for r in files))), flush=True)
        rows = [(True, r) for r in directories]+[(False, r) for r in files]
        rows.sort(key=lambda pair: pair[1]['path'])
        sink = VolumeWriter(out, limit)
        with sink:
            with gzip.GzipFile(fileobj=sink, mode='wb', filename='', mtime=0, compresslevel=6) as compressed:
                with tarfile.open(fileobj=compressed, mode='w|', format=tarfile.PAX_FORMAT) as tar:
                    for is_directory, row in rows:
                        info = tarfile.TarInfo(row['path'])
                        info.mode = row['mode']
                        info.uid = info.gid = info.mtime = 0
                        info.uname = info.gname = ''
                        if is_directory:
                            info.type = tarfile.DIRTYPE
                            tar.addfile(info)
                        else:
                            info.size = row['bytes']
                            with (source/row['path']).open('rb') as stream:
                                tar.addfile(info, stream)
        archive = dict(format='one gzip/PAX-tar stream split into ordered byte volumes',
                       bytes=sink.total, sha256=sink.logical_hash.hexdigest(),
                       volumeLimitBytes=limit, volumes=sink.volumes)
        manifest = dict(kind='phase35-validation-capsule', schemaVersion=1, complete=False,
                        source=str(source), started=state['started'], producer=state['producer'],
                        archive=archive, fileCount=len(files), directoryCount=len(directories),
                        logicalBytes=sum(r['bytes'] for r in files), files=files, directories=directories,
                        exclusions=dict(rule='Only regular files with .pyc or .pyo suffixes', files=excluded),
                        scope='All closed Phase35 builds, failed/superseded producers, observations and diagnostics; no success-only filtering.')
        checked = verify(out, manifest)
        if inventory(source) != (files, directories, excluded):
            raise RuntimeError('Evidence changed during capture: path, mode, size, hash or exclusion set')
        if identity(Path(__file__).resolve()) != state['producer']:
            raise RuntimeError('Preservation producer changed during capture')
        manifest.update(complete=True, reopenedVerified=True, sourceRehashed=True, finished=now())
        save(out/'manifest.json', manifest)
        state.update(complete=True, finished=manifest['finished'], verification=checked,
                     sourceRehashed=True, manifest=identity(out/'manifest.json'))
        save(out/'capture.json', state, replace=True)
        print(json.dumps(checked), flush=True)
    except BaseException as error:
        state.update(complete=False, finished=now(), error=repr(error),
                     preservation='Partial volumes are retained; no complete manifest was admitted.')
        save(out/'capture.json', state, replace=True)
        raise


def completed_manifest(out):
    capture_receipt = json.loads((out/'capture.json').read_text())
    manifest_file = out/'manifest.json'
    manifest = json.loads(manifest_file.read_text())
    if (not capture_receipt.get('complete') or not capture_receipt.get('sourceRehashed') or
            not manifest.get('complete') or not manifest.get('reopenedVerified') or
            not manifest.get('sourceRehashed')):
        raise ValueError('Both capture and manifest must record completed verification/source rehash')
    expected, actual = capture_receipt['manifest'], identity(manifest_file)
    # Bind bytes, not the former acquisition-machine absolute path, so a copied
    # evidence directory remains independently verifiable after relocation.
    if expected['sha256'] != actual['sha256'] or expected['bytes'] != actual['bytes']:
        raise ValueError('Manifest identity differs from completed capture receipt')
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=SOURCE)
    parser.add_argument('--out', type=Path, default=OUT)
    parser.add_argument('--closed', action='store_true', help='Root confirms all source jobs/report writers have finished')
    parser.add_argument('--volume-mib', type=int, default=40, choices=range(1, 41))
    parser.add_argument('--verify-only', action='store_true', help='Reopen an existing capsule; write nothing')
    parser.add_argument('--check-source', action='store_true', help='Also rehash source when verifying; requires --closed')
    args = parser.parse_args()
    source, out = args.source.resolve(), args.out.resolve()
    if args.verify_only and not args.check_source:
        manifest = completed_manifest(out)
        print(json.dumps(verify(out, manifest)), flush=True)
        return
    if not args.closed:
        parser.error('Capture/source verification requires --closed after all Phase35 writers finish')
    LOCK.parent.mkdir(parents=True, exist_ok=True)
    with LOCK.open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError('Another compiler/benchmark job holds the shared execution lock') from None
        if args.verify_only:
            manifest = completed_manifest(out)
            result = verify(out, manifest)
            if inventory(source) != (manifest['files'], manifest['directories'], manifest['exclusions']['files']):
                raise RuntimeError('Current source does not match capsule inventory')
            result['sourceRehashed'] = True
            print(json.dumps(result), flush=True)
        else:
            if args.check_source:
                parser.error('--check-source is for --verify-only; capture always rehashes source')
            capture(source, out, args.volume_mib*1024*1024)


if __name__ == '__main__':
    main()
