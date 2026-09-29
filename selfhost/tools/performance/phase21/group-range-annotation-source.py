#!/usr/bin/env python3
"""Preserve source01 and construct source02 with explicit typed-Ann cursors."""
import difflib
import hashlib
import json
import shutil
import sys
from pathlib import Path

repo = Path(__file__).resolve().parents[4]
phase = repo / 'selfhost/build/phase21'
previous = phase / 'group-range-source-01'
out = phase / 'group-range-source-02'
inputs = [Path(__file__), repo / 'design/phase21/typed-annotation-origin.md',
          previous / 'manifest.json', *map(lambda p: Path(p).resolve(), sys.argv[1:])]
assert len(inputs) >= 5, 'Require closed source01 structure and pinned Ann-coordinate evidence'

def identity(p):
    p = p.resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
            'bytes': p.stat().st_size}

frozen_inputs = [identity(p) for p in inputs]
old_manifest = json.loads((previous / 'manifest.json').read_text())
for member in old_manifest['members'].values():
    assert identity(Path(member['file'])) == member
out.mkdir()
project = out / 'project'
shutil.copytree(previous / 'project', project)
changes = []

def edit(relative, replacements):
    p = project / relative
    before = p.read_text()
    after = before
    for old, new in replacements:
        assert after.count(old) == 1, (relative, old, after.count(old))
        after = after.replace(old, new)
    p.write_text(after)
    changes.append({'file': relative, 'before': identity(previous / 'project' / relative),
                    'after': identity(p), 'deltaLines': len(after.splitlines())-len(before.splitlines()),
                    'deltaBytes': len(after.encode())-len(before.encode())})

edit('src/front/declarations.bend', [
    ('law f_statement:\n  for +p: FParsed\n', 'law f_statement:\n  for +p: FParsed\n  for +begin: U32\n'),
    ('u => f_statement(f_expr(ts, 0))))', 'u => f_statement(f_expr(ts, 0), f_begin(ts))))'),
    ('def f_statement(p):', 'def f_statement(p, begin):'),
    ('f_typed_let_try(n, ts, f_expr(f_tl(ts), 0))', 'f_typed_let_try(n, ts, f_expr(f_tl(ts), 0), begin)'),
    ('def f_let_ann(\n  +ty: KTerm,\n  +p: FParsed,', 'def f_let_ann(\n  +ty: KTerm,\n  +p: FParsed,\n  +begin: U32,'),
    ('FParsed{kt("Ann", "", 0, 1, [v, ty]), ts}', 'FParsed{kt_span("Ann", "", 0, 1, [v, ty], begin, f_begin(f_space(ts))), ts}')
])
edit('src/front/parallel.bend', [
    ('law f_typed_let_try:\n  for +n: KTerm\n  for +old: List<&2, FToken>\n  for +p: FParsed\n',
     'law f_typed_let_try:\n  for +n: KTerm\n  for +old: List<&2, FToken>\n  for +p: FParsed\n  for +begin: U32\n'),
    ('def f_typed_let_try(n, old, p):', 'def f_typed_let_try(n, old, p, begin):'),
    ('f_let_ann(ty, f_expr(f_tl(ts), 0))', 'f_let_ann(ty, f_expr(f_tl(ts), 0), begin)')
])
edit('src/front/sugar.bend', [
    ('f_statement(FParsed{kt_span("Ref", f_tx(ts), f_atid(ts), 0, Nil{}, begin, f_end(ts)), f_tl(ts)})',
     'f_statement(FParsed{kt_span("Ref", f_tx(ts), f_atid(ts), 0, Nil{}, begin, f_end(ts)), f_tl(ts)}, begin)')
])
parent = json.loads((repo / 'selfhost/build/phase20/import-diagnostic-build-04/attempt.json').read_text())
base = Path(parent['snapshot']['root'])
patch = ''
for x in changes:
    name = x['file']
    patch += ''.join(difflib.unified_diff((base/name).read_text().splitlines(True),
        (project/name).read_text().splitlines(True), fromfile='parent/'+name, tofile='candidate/'+name))
(out/'candidate.patch').write_text(patch)
config = json.loads((previous/'workflow.json').read_text())
config['project'] = str(project)
(out/'workflow.json').write_text(json.dumps(config, indent=2)+'\n')
members = {str(p.relative_to(project)): identity(p) for p in sorted(project.rglob('*')) if p.is_file()}
assert len(members) == 214
assert [identity(p) for p in inputs] == frozen_inputs
(out/'manifest.json').write_text(json.dumps({
    'kind': 'phase21-explicit-local-and-annotation-origins', 'complete': True,
    'installed': False, 'project': str(project), 'parentApi': parent['api'],
    'inputs': frozen_inputs, 'members': members, 'changes': changes,
    'deltaPhase20': {'physicalLines': sum(x['deltaLines'] for x in changes),
                     'bytes': sum(x['deltaBytes'] for x in changes)+old_manifest['delta']['bytes'],
                     'definitions': 0, 'laws': 0, 'types': 0},
    'scope': 'Three existing U32 parameters carry original body start; sole typed Ann producer uses returned spaced cursor. Local first-binder origin retained. No semantic branch, traversal, classifier, host or profile change.'
}, indent=2)+'\n')
print(out)
