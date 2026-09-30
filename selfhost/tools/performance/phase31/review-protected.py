#!/usr/bin/env python3
"""Verify the preexisting unrelated files and ensure none is staged."""
from pathlib import Path
import hashlib, json, subprocess, sys
root = Path(__file__).resolve().parents[4]
start = root / 'implementation/phase31/start-state.json'
out = Path(sys.argv[1]).resolve()
assert not out.exists()
rows = json.loads(start.read_text())['protectedPreexisting']
changed = []
for item in rows:
    p = root / item['path']
    if not p.is_file():
        changed.append({'path':item['path'], 'missing':True})
        continue
    raw = p.read_bytes()
    if len(raw) != item['bytes'] or hashlib.sha256(raw).hexdigest() != item['sha256']:
        changed.append({'path':item['path'], 'changed':True})
staged = subprocess.check_output(['git','diff','--cached','--name-only','-z'],cwd=root).decode().split('\0')
protected_staged = sorted(set(staged) & {i['path'] for i in rows})
r = {'complete':not changed and not protected_staged, 'scope':'Exact bytes and absence from index for the103 preexisting unrelated files.',
     'startSha256':hashlib.sha256(start.read_bytes()).hexdigest(), 'checked':len(rows), 'changed':changed, 'protectedStaged':protected_staged}
out.write_text(json.dumps(r,indent=2)+'\n')
print(json.dumps(r))
raise SystemExit(0 if r['complete'] else 1)
