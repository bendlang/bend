#!/usr/bin/env python3
"""Prepare one fillable-header guard and its independent CPU1 workflow."""
from pathlib import Path
import shutil, json, hashlib, difflib, subprocess, sys
R = Path(__file__).resolve().parents[4]
parent = R / 'selfhost/build/phase22/context-source-11'
out = R / 'selfhost/build/phase22/context-source-12'
assert not out.exists()
out.mkdir()
shutil.copytree(parent / 'project', out / 'project')
f = out / 'project/src/front/declarations.bend'
before = f.read_text()
a = 'f_choose(FRawResult, Bool.not(f_def_fillable(old)) && f_decl_taken(name, book, scope),'
b = 'f_choose(FRawResult, f_choose(Bool, Bool.not(f_def_fillable(old)), u => f_decl_taken(name, book, scope), u => False{}),'
assert before.count(a) == 1
after = before.replace(a, b)
f.write_text(after)
patch = out / 'parent-declarations.patch'
patch.write_text(''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True), fromfile='a/src/front/declarations.bend', tofile='b/src/front/declarations.bend')))
def identity(p):
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
inputs = [parent / 'manifest.json', R / 'design/phase22/context-fillable-cost.md', Path(__file__), patch]
(out / 'parent.json').write_text(json.dumps({'parent': str(parent), 'correction': 'Do not compute declaration membership for an already fillable header; no other semantic or materialization change.', 'inputs': [identity(p) for p in inputs], 'delta': {'files': 1, 'lines': 0, 'definitions': 0, 'types': 0, 'bytes': len(after.encode()) - len(before.encode())}}, indent=2) + '\n')
subprocess.run([sys.executable, str(R / 'selfhost/tools/performance/phase22/context-freeze.py'), str(out.relative_to(R))], check=True, cwd=R)
workflow = out / 'workflow.json'
config = json.loads(workflow.read_text())
config['cpu'] = '1'
workflow.write_text(json.dumps(config, indent=2) + '\n')
(out / 'workflow-freeze.json').write_text(json.dumps({'complete': True, 'inputs': [identity(workflow), identity(out / 'manifest.json'), identity(out / 'parent.json')], 'scope': 'CPU1 is frozen before the first compiler invocation.'}, indent=2) + '\n')
