#!/usr/bin/env python3
"""Capture closed Phase31 evidence and verify every independently read member."""
import hashlib
import json
import tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
SOURCE = ROOT / 'selfhost/build/phase31'
ARCHIVE = OUT / 'campaign.tar.gz'
RECEIPT = OUT / 'receipt.json'
assert not ARCHIVE.exists() and not RECEIPT.exists(), \
    'Evidence capsules and receipts are immutable; choose a new identity'
paths = sorted(SOURCE.rglob('*'))
assert not any(p.is_symlink() for p in paths), 'Unexpected symlink in evidence'
files = [p for p in paths if p.is_file()]


def identity(p):
    return {'path': p.relative_to(ROOT).as_posix(), 'bytes': p.stat().st_size,
            'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
            'mode': p.stat().st_mode & 0o7777}


items = [identity(p) for p in files]
# Some validated retry books share an inode with an older immutable acquisition.
# Store their logical bytes as regular members, so recovery needs no link policy.
with ARCHIVE.open('xb') as stream:
    with tarfile.open(fileobj=stream, mode='w:gz', compresslevel=9,
                      dereference=True) as archive:
        for p in files:
            archive.add(p, arcname=p.relative_to(ROOT), recursive=False)
assert items == [identity(p) for p in files], 'Input changed while capturing'
assert files == [p for p in sorted(SOURCE.rglob('*')) if p.is_file()], 'File set changed'

restored = []
with tarfile.open(ARCHIVE, 'r:gz') as archive:
    for member in archive:
        assert member.isfile() and not member.name.startswith('/')
        assert '..' not in Path(member.name).parts
        data = archive.extractfile(member).read()
        restored.append({'path': member.name, 'bytes': len(data),
                         'sha256': hashlib.sha256(data).hexdigest(),
                         'mode': member.mode})
assert restored == items, 'Independent decompression differs'
receipt = {'complete': True, 'archive': identity(ARCHIVE), 'members': len(items),
           'producer': identity(Path(__file__).resolve()),
           'logicalBytes': sum(i['bytes'] for i in items),
           'recovery': 'Independent reopened gzip/tar stream: every regular member '
                       'compared by exact name, size, SHA256 and mode. Hardlinks stored '
                       'as regular bytes. No extraction or experiments rerun.',
           'files': items}
with RECEIPT.open('x') as stream:
    stream.write(json.dumps(receipt, indent=2) + '\n')
print(json.dumps({k: v for k, v in receipt.items() if k != 'files'}, indent=2))
