#!/usr/bin/env python3
"""Finish a verified redundant-copy cleanup with bounded receipt writes."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
PRIOR = ROOT / 'implementation/phase32/verified-space-recovery-interrupted.json'
OUT = ROOT / 'implementation/phase32/verified-space-recovery.json'
assert not OUT.exists()
old = json.loads(PRIOR.read_text())
assert not old['complete'] and len(old['verified']) > 1000
transport = json.loads((ROOT / 'implementation/phase30/evidence/transport.json').read_text())
digest = hashlib.sha256()
for item in transport['chunks']:
    data = (ROOT / item['path']).read_bytes()
    assert len(data) == item['bytes'] and hashlib.sha256(data).hexdigest() == item['sha256']
    digest.update(data)
assert digest.hexdigest() == old['archiveSha256']
remaining = []
missing = []
for item in old['verified']:
    p = ROOT / item['path']
    assert p.is_relative_to(ROOT / 'selfhost/build/phase30')
    if not p.exists():
        missing.append(item['path'])
        continue
    assert not p.is_symlink() and p.stat().st_size == item['bytes']
    assert hashlib.sha256(p.read_bytes()).hexdigest() == item['sha256']
    remaining.append(item)
assert set(old['removed']) <= set(missing)
report = dict(complete=False, previousReceiptSHA256=hashlib.sha256(PRIOR.read_bytes()).hexdigest(),
              archiveSHA256=digest.hexdigest(), alreadyAbsent=missing, removed=[],
              reason='Initial cleanup interrupted because per-file full receipt writes scaled poorly; all archive members were verified before any deletion.')
def save():
    temp = OUT.with_suffix('.tmp')
    temp.write_text(json.dumps(report, indent=2) + '\n')
    temp.replace(OUT)
save()
for at, item in enumerate(remaining):
    (ROOT / item['path']).unlink()
    report['removed'].append(item['path'])
    if at % 500 == 0:
        save()
report['complete'] = True
report['totalLogicalBytesRecovered'] = sum(x['bytes'] for x in old['verified'])
save()
print(json.dumps({k: report[k] for k in ['complete', 'totalLogicalBytesRecovered']}))
