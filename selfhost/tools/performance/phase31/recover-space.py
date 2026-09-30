#!/usr/bin/env python3
"""Remove only redundant synthetic inputs after checking their archived bytes."""
import hashlib
import json
import tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
EVIDENCE = ROOT / 'implementation/phase30/evidence'
OUT = ROOT / 'implementation/phase31/verified-space-recovery.json'
assert not OUT.exists()
receipt_path = EVIDENCE / 'receipt.json'
transport = json.loads((EVIDENCE / 'transport.json').read_text())
assert hashlib.sha256(receipt_path.read_bytes()).hexdigest() == transport['receiptSha256']
receipt = json.loads(receipt_path.read_text())
selected = {r['path']: r for r in receipt['files']
            if r['path'].startswith('selfhost/build/phase30/review-terminal-bounds-')
            and r['path'].endswith('.book.json') and r['bytes'] > 40_000_000}
assert len(selected) == 11
joined = hashlib.sha256()
parts = []
for item in transport['chunks']:
    p = ROOT / item['path']
    data = p.read_bytes()
    assert len(data) == item['bytes']
    assert hashlib.sha256(data).hexdigest() == item['sha256']
    joined.update(data)
    parts.append(p)
assert joined.hexdigest() == receipt['archive']['sha256']

class Joined:
    def __init__(self, paths):
        self.paths = iter(paths)
        self.current = next(self.paths).open('rb')

    def read(self, size):
        result = bytearray()
        while len(result) < size and self.current is not None:
            data = self.current.read(size - len(result))
            if data:
                result.extend(data)
            else:
                self.current.close()
                p = next(self.paths, None)
                self.current = p.open('rb') if p else None
        return bytes(result)

verified = []
with tarfile.open(fileobj=Joined(parts), mode='r|gz') as archive:
    for member in archive:
        if member.name not in selected:
            continue
        expected = selected[member.name]
        assert member.isfile() and member.size == expected['bytes']
        stream = archive.extractfile(member)
        digest = hashlib.sha256()
        while data := stream.read(1024 * 1024):
            digest.update(data)
        assert digest.hexdigest() == expected['sha256']
        p = ROOT / member.name
        assert not p.is_symlink() and p.stat().st_size == expected['bytes']
        assert hashlib.sha256(p.read_bytes()).hexdigest() == expected['sha256']
        verified.append(expected)
assert len(verified) == len(selected)
report = {'complete': False, 'archiveSha256': joined.hexdigest(),
          'scope': 'Only redundant live synthetic bound-test books; all bytes '
                   'independently checked in committed Phase30 chunks first.',
          'verified': verified, 'removed': []}
OUT.write_text(json.dumps(report, indent=2) + '\n')
for item in verified:
    (ROOT / item['path']).unlink()
    report['removed'].append(item['path'])
    OUT.write_text(json.dumps(report, indent=2) + '\n')
report['complete'] = True
report['logicalBytesRemoved'] = sum(r['bytes'] for r in verified)
OUT.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'complete': True, 'files': len(verified),
                  'logicalBytes': report['logicalBytesRemoved']}))
