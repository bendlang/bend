#!/usr/bin/env python3
"""Freeze one empty-child constructor lookup guard after fresh profiling."""
import difflib
import hashlib
import json
import shutil
import sys
from pathlib import Path

repo = Path(__file__).resolve().parents[4]
phase = repo / 'selfhost/build/phase22'
out = phase / 'context-source-14'
parent_file = repo / 'selfhost/build/phase22/context-build-12/attempt.json'
parent = json.loads(parent_file.read_text())
assert parent['api']['sha256'] == 'a80737cd74e8b3e78b07006580ed3aded060c530b3d67af032db81a17fa3f404'

def identity(p):
    p = p.resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
            'bytes': p.stat().st_size}

assert identity(Path(parent['api']['file']))['sha256'] == parent['api']['sha256']
inputs = [Path(__file__), parent_file, Path(parent['api']['file']),
          repo/'design/phase22/constructor-bool-worker.md',
          repo/'selfhost/build/phase22/contextual-profile-01/report.json',
          repo/'selfhost/build/phase22/contextual-profile-callers-01/report.json']
frozen_inputs = [identity(p) for p in inputs]
out.mkdir()
project = out / 'project'
members = {}
for row in parent['snapshot']['sources']:
    source = Path(row['frozen']['file'])
    relative = source.relative_to(parent['snapshot']['root'])
    assert identity(source)['sha256'] == row['frozen']['sha256']
    target = project / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
    members[str(relative)] = identity(target)
assert len(members) == 215
file = project / 'src/front/validate.bend'
before = file.read_text()
needle = '      f_choose(KDef, f_eq(dk(d), "Ctr") && f_eq(dn(d), name), u => d, u => f_ctor_children(name, dc(d), ds))'
replacement = '      f_ctor_named(name, d, ds, f_eq(dk(d), "Ctr") && f_eq(dn(d), name))'
helper = """@unsafe
def f_ctor_named(+name: String, +d: KDef, +rest: List<&2,KDef>, +same: Bool) -> KDef:
  match same:
    case True{}: d
    case False{}: f_ctor_children(name, dc(d), rest)

"""
assert before.count(needle) == 1
after = before.replace(needle, replacement)
assert after.count("@unsafe\ndef f_ctor_children(") == 1
after = after.replace("@unsafe\ndef f_ctor_children(", helper + "@unsafe\ndef f_ctor_children(")
file.write_text(after)
members['src/front/validate.bend'] = identity(file)
(out / 'candidate.patch').write_text(''.join(difflib.unified_diff(
    before.splitlines(True), after.splitlines(True),
    fromfile='parent/src/front/validate.bend', tofile='candidate/src/front/validate.bend')))
(out / 'workflow.json').write_text(json.dumps({
    'project': str(project), 'upstream': parent['config']['upstream'],
    'profile': 'equality', 'cpu': '3', 'jobs': 1, 'strictExact': True}, indent=2) + '\n')
assert [identity(p) for p in inputs] == frozen_inputs
(out / 'manifest.json').write_text(json.dumps({
    'kind': 'phase22-constructor-bool-worker-candidate', 'complete': True,
    'installed': False, 'parentApi': parent['api'], 'inputs': frozen_inputs,
    'project': str(project), 'members': members,
    'changedFiles': ['src/front/validate.bend'],
    'delta': {'physicalLines': len(after.splitlines())-len(before.splitlines()), 'nonblankLines': len([x for x in after.splitlines() if x.strip()])-len([x for x in before.splitlines() if x.strip()]),
              'bytes': len(after.encode()) - len(before.encode()),
              'definitions': 1, 'laws': 0, 'types': 0},
    'scope': 'One Bool worker preserves eager kind/name comparison and delegates to the existing child search; no installed source, host or representation change.'
}, indent=2) + '\n')
print(out)
