#!/usr/bin/env python3
"""Transport a verified capsule as sub-100-MiB Git files without changing bytes."""
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
ARCHIVE = HERE / 'campaign.tar.gz'
RECEIPT = HERE / 'receipt.json'
TRANSPORT = HERE / 'transport.json'
CHUNK_BYTES = 64 * 1024 * 1024
assert not TRANSPORT.exists()
assert not list(HERE.glob('campaign.tar.gz.part-*'))
original = json.loads(RECEIPT.read_text())
assert original['complete']
expected = original['archive']
assert ARCHIVE.stat().st_size == expected['bytes']
assert hashlib.sha256(ARCHIVE.read_bytes()).hexdigest() == expected['sha256']

chunks = []
with ARCHIVE.open('rb') as source:
    number = 1
    while data := source.read(CHUNK_BYTES):
        target = HERE / f'campaign.tar.gz.part-{number:03d}'
        with target.open('xb') as stream:
            stream.write(data)
        chunks.append({'path': target.relative_to(ROOT).as_posix(),
                       'bytes': len(data),
                       'sha256': hashlib.sha256(data).hexdigest()})
        number += 1

# Independently reread all transport bytes before removing the duplicate whole
# file. Concatenation reproduces the already reopened/member-verified gzip.
combined = hashlib.sha256()
total = 0
for item in chunks:
    data = (ROOT / item['path']).read_bytes()
    assert len(data) == item['bytes']
    assert hashlib.sha256(data).hexdigest() == item['sha256']
    combined.update(data)
    total += len(data)
assert total == expected['bytes']
assert combined.hexdigest() == expected['sha256']
report = {
    'complete': True,
    'scope': 'Byte-exact transport of the independently verified capsule. '
             'The original receipt archive path names the logical reassembled '
             'stream; the committed payload consists of these ordered chunks.',
    'archive': expected,
    'receiptSha256': hashlib.sha256(RECEIPT.read_bytes()).hexdigest(),
    'producerSha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'chunkBytes': CHUNK_BYTES,
    'chunks': chunks,
    'concatenatedBytes': total,
    'concatenatedSha256': combined.hexdigest(),
    'verification': 'Every chunk independently reread, exact size/hash checked, '
                    'and ordered concatenation checked against the full '
                    'archive size/hash from the original member-level receipt.',
}
with TRANSPORT.open('x') as stream:
    stream.write(json.dumps(report, indent=2) + '\n')
# Only the newly created, independently verified redundant representation is
# removed. All captured experiments remain in the byte-identical chunks.
ARCHIVE.unlink()
print(json.dumps({'complete': True, 'chunks': len(chunks),
                  'bytes': total, 'sha256': combined.hexdigest()}))
