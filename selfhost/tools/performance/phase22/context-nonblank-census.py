#!/usr/bin/env python3
"""Count nonblank lines in the actual configured compiler module sets."""
from pathlib import Path
import json, hashlib, sys
R = Path(__file__).resolve().parents[4]
parent, candidate, output = [Path(x).resolve() for x in sys.argv[1:]]
assert not output.exists()
def identity(p): return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
def count(root):
    config = root / 'src/compiler.json'
    rows = []
    for name in json.loads(config.read_text())['modules']:
        p = root / name; lines = p.read_text().splitlines()
        rows.append({'path': name, 'physicalLines': len(lines), 'nonblankLines': sum(bool(line.strip()) for line in lines), 'input': identity(p)})
    return {'config': identity(config), 'modules': rows, 'physicalLines': sum(x['physicalLines'] for x in rows), 'nonblankLines': sum(x['nonblankLines'] for x in rows)}
a = count(parent); b = count(candidate)
r = {'kind': 'phase22-compiler-nonblank-census', 'complete': True, 'parent': a, 'candidate': b, 'delta': {k: b[k] - a[k] for k in ['physicalLines', 'nonblankLines']}, 'scope': 'Actual compiler.json modules only. Nonblank means line.strip() is nonempty; comments remain counted. No generated API, snapshot duplication or host files.', 'tool': identity(Path(__file__).resolve())}
output.write_text(json.dumps(r, indent=2) + '\n'); print(json.dumps({'parent': {k:a[k] for k in ['physicalLines','nonblankLines']}, 'candidate': {k:b[k] for k in ['physicalLines','nonblankLines']}, 'delta': r['delta']}))
