#!/usr/bin/env python3
"""Freeze only the reviewed constructor guard over both header guards."""
from pathlib import Path
import json, hashlib, shutil, difflib, subprocess, sys
R = Path(__file__).resolve().parents[4]
P = R / 'selfhost/build/phase22/context-source-12'
C = R / 'selfhost/build/phase22/constructor-source-01'
B = R / 'selfhost/build/phase22/context-source-10'
O = R / 'selfhost/build/phase22/context-source-13'
rel = Path('src/front/validate.bend')
def members(p):
    return {str(x.relative_to(p)): hashlib.sha256(x.read_bytes()).hexdigest() for x in p.rglob('*') if x.is_file()}
b, c = members(B / 'project'), members(C / 'project')
assert b.keys() == c.keys()
assert [p for p in sorted(b) if b[p] != c[p]] == [str(rel)]
assert (P / 'project' / rel).read_bytes() == (B / 'project' / rel).read_bytes()
gate = R / 'selfhost/build/phase22/context-controls-header-screen-02/report.json'
g = json.loads(gate.read_text())
assert g['complete'] and g['pass']
assert not O.exists()
O.mkdir()
shutil.copytree(P / 'project', O / 'project')
shutil.copy2(C / 'project' / rel, O / 'project' / rel)
patch = O / 'parent-validate.patch'
before = (P / 'project' / rel).read_text()
after = (O / 'project' / rel).read_text()
patch.write_text(''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True), fromfile='a/' + str(rel), tofile='b/' + str(rel))))
def identity(p): return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
inputs = [P / 'manifest.json', P / 'parent.json', C / 'manifest.json', C / 'candidate.patch', C / 'project' / rel, R / 'design/phase22/context-cost-union.md', gate, Path(__file__), patch]
(O / 'parent.json').write_text(json.dumps({'parent': str(P), 'importedParent': str(C), 'changedFromParent': [str(rel)], 'delta': {'lines': len(after.splitlines()) - len(before.splitlines()), 'bytes': len(after.encode()) - len(before.encode()), 'definitions': 1, 'types': 0}, 'inputs': [identity(p) for p in inputs], 'scope': 'Exact one-file constructor overlay; both header guards inherited, all other files unchanged from source12.'}, indent=2) + '\n')
subprocess.run([sys.executable, str(R / 'selfhost/tools/performance/phase22/context-freeze.py'), str(O.relative_to(R))], cwd=R, check=True)
print(O)
