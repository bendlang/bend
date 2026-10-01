#!/usr/bin/env python3
"""Verify the unrelated starting work is unchanged and unstaged; no mutation."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('out', type=Path, help='New audit receipt')
args = parser.parse_args()
assert not args.out.exists()
start = Path(__file__).with_name('protected-files-start.json')
rows = json.loads(start.read_text())
assert len(rows) == 103 and len({row['path'] for row in rows}) == 103
raw = subprocess.check_output(['git', 'status', '--porcelain=v1', '-z', '--untracked-files=all'], cwd=ROOT)
status = {}
for entry in raw.decode().split('\0'):
    if entry:
        assert entry[2] == ' ', 'Unexpected rename/status format'
        status[entry[3:]] = entry[:2]
checked = []
for row in rows:
    file = ROOT / row['path']
    actual = dict(path=row['path'], status=status.get(row['path']),
                  bytes=file.stat().st_size, sha256=hashlib.sha256(file.read_bytes()).hexdigest())
    assert actual == row, row['path']
    assert actual['status'][0] in [' ', '?'], 'Protected work was staged'
    checked.append(actual)
args.out.parent.mkdir(parents=True, exist_ok=True)
args.out.write_text(json.dumps(dict(complete=True, count=len(checked),
    inventorySha256=hashlib.sha256(start.read_bytes()).hexdigest(),
    producerSha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), files=checked), indent=2)+'\n')
print(json.dumps(dict(complete=True, protected=len(checked), unchanged=True, unstaged=True)))
