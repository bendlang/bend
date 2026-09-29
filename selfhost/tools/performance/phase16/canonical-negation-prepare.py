#!/usr/bin/env python3
"""Freeze a surface canonical-reference fix and its immutable source delta."""
from pathlib import Path
import difflib, hashlib, json, shutil

root = Path(__file__).resolve().parents[4]
base = root / 'selfhost/build/phase16/spans-shared-migration-01/project'
out = root / 'selfhost/build/phase16/canonical-source-01'
out.mkdir()
project = out / 'project'
shutil.copytree(base, project)

def replace(relative, old, new):
    p = project / relative
    source = p.read_text()
    assert source.count(old) == 1, (relative, source.count(old))
    p.write_text(source.replace(old, new))

replace('src/front/parser.bend', 'kt("Ref", "Empty", 0, 1, Nil{})',
        'kt("FGlobal", "Empty", 0, 1, Nil{})')
replace('src/front/fresh_work.bend',
        'def ffw_walk(term, env, next, stack):\n',
        'def ffw_walk(term, env, next, stack):\n'
        '  f_choose(FFresh, String.eq(tg(term), "FGlobal"), u => ffw_done(kt_span("Ref", nm(term), 0, 1, Nil{}, kb(term), ke(term)), next, stack), u => ffw_scoped(term, env, next, stack))\n'
        '@unsafe\ndef ffw_scoped(term, env, next, stack):\n')

def identity(p):
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}

changes = []
for name in ['src/front/parser.bend', 'src/front/fresh_work.bend']:
    a, b = base / name, project / name
    patch = out / (name.replace('/', '_') + '.patch')
    patch.write_text(''.join(difflib.unified_diff(a.read_text().splitlines(True), b.read_text().splitlines(True), fromfile=name, tofile=name)))
    changes.append({'relative': name, 'before': identity(a), 'after': identity(b), 'patch': identity(patch), 'lineDelta': len(b.read_text().splitlines()) - len(a.read_text().splitlines())})
(out / 'manifest.json').write_text(json.dumps({'kind': 'phase16-canonical-reference', 'parent': str(base), 'tool': identity(Path(__file__)), 'plan': identity(root / 'design/phase16/canonical-negation.md'), 'changes': changes}, indent=2) + '\n')
(out / 'workflow.json').write_text(json.dumps({'project': str(project), 'upstream': str(root / 'selfhost/.bootstrap/upstream-phase8'), 'profile': 'equality', 'cpu': '0', 'jobs': 1}, indent=2) + '\n')
shutil.copy2(__file__, out / 'consumed-tool.py')
print(out)
