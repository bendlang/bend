#!/usr/bin/env python3
"""Freeze the dx-only template-call index reuse after its projection proof."""
from pathlib import Path
import json, hashlib, shutil, difflib, subprocess, sys
R = Path(__file__).resolve().parents[4]
P = R / 'selfhost/build/phase22/context-source-13'
O = R / 'selfhost/build/phase22/context-source-15'
proof = R / 'selfhost/build/phase22/context-template-index-proof-01/report.json'
r = json.loads(proof.read_text())
assert r['complete'] and r['pass'] and len(r['primitive']) == 8
assert r['production'][-1]['counts']['refs'] > 15000
assert not O.exists()
O.mkdir()
shutil.copytree(P / 'project', O / 'project')
p = O / 'project/src/front/contextual.bend'
before = p.read_text()
a = '+count = f_choose(U32, f_eq(tg(head), "Ref"), u => dx(f_find(nm(head), prior)), u => 0)'
b = '+count = f_choose(U32, f_eq(tg(head), "Ref"), u => dx(index_find(index, nm(head), index_hash(nm(head), 2166136261), 32)), u => 0)'
assert before.count(a) == 1
after = before.replace(a, b)
p.write_text(after)
patch = O / 'parent-contextual.patch'
patch.write_text(''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True), fromfile='a/src/front/contextual.bend', tofile='b/src/front/contextual.bend')))
def identity(p): return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
inputs = [P / 'manifest.json', R / 'design/phase22/context-template-index.md', R / 'design/phase22/context-template-index-proof.md', proof, Path(__file__), patch]
(O / 'parent.json').write_text(json.dumps({'parent': str(P), 'changedFromParent': ['src/front/contextual.bend'], 'delta': {'lines': 0, 'bytes': len(after.encode()) - len(before.encode()), 'definitions': 0, 'types': 0}, 'inputs': [identity(p) for p in inputs], 'scope': 'Only Ref call template-count projection reuses the existing current index. Family/marked paths and constructor experiment14 excluded.'}, indent=2) + '\n')
subprocess.run([sys.executable, str(R / 'selfhost/tools/performance/phase22/context-freeze.py'), str(O.relative_to(R))], cwd=R, check=True)
workflow = O / 'workflow.json'
c = json.loads(workflow.read_text()); c['cpu'] = '1'
workflow.write_text(json.dumps(c, indent=2) + '\n')
(O / 'workflow-freeze.json').write_text(json.dumps({'complete': True, 'inputs': [identity(workflow), identity(O / 'parent.json'), identity(O / 'manifest.json')], 'scope': 'CPU1 frozen before first compiler invocation.'}, indent=2) + '\n')
