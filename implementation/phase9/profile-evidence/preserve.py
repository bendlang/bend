#!/usr/bin/env python3
"""Losslessly preserve one closed CPU-profile producer; never parse its JSON."""
import gzip
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import time
import zlib

raw = Path(sys.argv[1]).resolve(strict=True)
out = Path(sys.argv[2]).resolve()
out.mkdir()
report = {'kind': 'phase9-lossless-profile-preservation', 'complete': False,
          'scope': 'Byte preservation only. The original profile attempt and failed summary statuses are unchanged.',
          'raw': {'file': str(raw)}, 'python': sys.version, 'zlib': zlib.ZLIB_VERSION,
          'startedUnixSeconds': time.time(), 'gzipLevel': 6, 'gzipMtime': 0}
manifest = out / 'manifest.json'


def save():
    manifest.write_text(json.dumps(report, indent=2) + '\n')


def digest(file):
    h = hashlib.sha256()
    with file.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


save()
try:
    before = raw.stat()
    compressed = out / 'checking.cpuprofile.gz'
    h, count = hashlib.sha256(), 0
    with raw.open('rb') as source, compressed.open('xb') as target:
        with gzip.GzipFile(filename='', mode='wb', compresslevel=6, mtime=0, fileobj=target) as encoded:
            for block in iter(lambda: source.read(1024 * 1024), b''):
                h.update(block)
                count += len(block)
                encoded.write(block)
    after = raw.stat()
    for name in ('st_dev', 'st_ino', 'st_size', 'st_mtime_ns', 'st_ctime_ns'):
        if getattr(before, name) != getattr(after, name):
            raise RuntimeError('Raw profile changed during preservation: ' + name)
    if count != before.st_size:
        raise RuntimeError('Raw byte count mismatch')
    report['raw'].update(bytes=count, sha256=h.hexdigest())
    report['compressedBytes'] = compressed.stat().st_size
    report['compressedSha256'] = digest(compressed)
    restored, size = hashlib.sha256(), 0
    with gzip.open(compressed, 'rb') as decoded:
        for block in iter(lambda: decoded.read(1024 * 1024), b''):
            restored.update(block)
            size += len(block)
    if size != count or restored.hexdigest() != h.hexdigest():
        raise RuntimeError('Gzip roundtrip differs from raw profile')
    report['roundtrip'] = {'pass': True, 'bytes': size, 'sha256': restored.hexdigest()}
    parts = []
    if compressed.stat().st_size > 95000000:
        joined = hashlib.sha256()
        with compressed.open('rb') as stream:
            index = 0
            while True:
                block = stream.read(64 * 1024 * 1024)
                if not block:
                    break
                file = out / ('checking.cpuprofile.gz.part-%04d' % index)
                with file.open('xb') as target:
                    target.write(block)
                joined.update(block)
                parts.append({'file': file.name, 'bytes': len(block), 'sha256': digest(file)})
                index += 1
        if joined.hexdigest() != report['compressedSha256']:
            raise RuntimeError('Split compressed bytes differ')
        retained = Path('/tmp') / ('phase9-profile-unsplit-' + report['compressedSha256'] + '.gz')
        if retained.exists():
            raise FileExistsError(retained)
        shutil.move(str(compressed), retained)
        report['untrackedRedundantGzip'] = str(retained)
    else:
        parts.append({'file': compressed.name, 'bytes': compressed.stat().st_size, 'sha256': report['compressedSha256']})
    report['parts'] = parts
    report['tool'] = {'file': str(Path(__file__).resolve()), 'sha256': digest(Path(__file__))}
    report['complete'] = True
except BaseException as error:
    report['error'] = repr(error)
    raise
finally:
    report['finishedUnixSeconds'] = time.time()
    save()
print(json.dumps({'complete': report['complete'], 'raw': report['raw'], 'compressedBytes': report.get('compressedBytes'), 'parts': report.get('parts')}, indent=2))
