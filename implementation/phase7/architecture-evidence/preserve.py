#!/usr/bin/env python3
"""Freeze this experiment's raw directory and verify every archived byte."""
import gzip
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import sys
import tarfile


def sha(data):
    return hashlib.sha256(data).hexdigest()


def verify(archive, manifest):
    data = json.loads(manifest.read_text())
    assert sha(archive.read_bytes()) == data['archive']['sha256']
    expected = {row['path']: row for row in data['members']}
    seen = set()
    with tarfile.open(archive, 'r:gz') as tar:
        for member in tar:
            path = PurePosixPath(member.name)
            assert member.isfile() and not path.is_absolute() and '..' not in path.parts
            assert member.name not in seen and member.name in expected
            blob = tar.extractfile(member).read()
            row = expected[member.name]
            assert len(blob) == row['bytes'] and sha(blob) == row['sha256']
            seen.add(member.name)
    assert seen == set(expected)
    return {'pass': True, 'members': len(seen), 'bytes': data['archive']['bytes'],
            'sha256': data['archive']['sha256']}


mode, raw_arg, destination_arg = sys.argv[1:]
raw, destination = Path(raw_arg).resolve(), Path(destination_arg).resolve()
archive, manifest = destination / 'raw.tar.gz', destination / 'manifest.json'
if mode == 'create':
    assert raw.is_dir() and not destination.is_relative_to(raw)
    assert not archive.exists() and not manifest.exists(), 'Use a new destination'
    destination.mkdir(parents=True, exist_ok=True)
    members = []
    with archive.open('xb') as out, gzip.GzipFile(filename='', mode='wb', fileobj=out, mtime=0) as gz:
        with tarfile.open(fileobj=gz, mode='w|') as tar:
            for path in sorted(raw.rglob('*')):
                assert not path.is_symlink(), f'Unexpected symlink: {path}'
                if path.is_dir():
                    continue
                assert path.is_file()
                blob = path.read_bytes()
                name = 'raw/' + path.relative_to(raw).as_posix()
                info = tarfile.TarInfo(name)
                info.size, info.mode, info.mtime = len(blob), path.stat().st_mode & 0o777, 0
                tar.addfile(info, io.BytesIO(blob))
                members.append({'path': name, 'bytes': len(blob), 'sha256': sha(blob)})
    manifest.write_text(json.dumps({'schema': 1,
        'scope': 'All raw architecture attempts, including failures; no promotion claim',
        'originalRoot': str(raw), 'archive': {'file': archive.name,
        'bytes': archive.stat().st_size, 'sha256': sha(archive.read_bytes())},
        'members': members}, indent=2) + '\n')
elif mode != 'verify':
    raise SystemExit('Expected create or verify')
result = verify(archive, manifest)
if mode == 'create':
    (destination / 'verification.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result))
