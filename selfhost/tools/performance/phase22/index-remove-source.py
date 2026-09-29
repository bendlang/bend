#!/usr/bin/env python3
"""Freeze one index_remove Bool worker after caller census and prospective controls."""
import difflib
import hashlib
import json
import shutil
import sys
from pathlib import Path

repo = Path(__file__).resolve().parents[4]
phase = repo / 'selfhost/build/phase22'
out = phase / 'index-remove-source-01'
parent_file = repo / 'selfhost/build/phase21/group-range-build-02/attempt.json'
parent = json.loads(parent_file.read_text())
assert parent['api']['sha256'] == '44094e58cb0ef033e2c08c2827565e859c3594b3136868d4f821262145aea7f0'

def identity(p):
    p = p.resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
            'bytes': p.stat().st_size}

assert identity(Path(parent['api']['file']))['sha256'] == parent['api']['sha256']
inputs = [Path(__file__), parent_file, Path(parent['api']['file']),
          repo/'design/phase22/index-remove-worker.md',
          repo/'implementation/phase22/installed-profile.json',
          repo/'selfhost/tools/performance/phase22/index-remove-controls-cases.json']
frozen_inputs = [identity(p) for p in inputs]
out.mkdir()
project = out / 'project'
members = {}
for row in parent['snapshot']['sources']:
    source = Path(row['frozen']['file'])
    relative = source.relative_to(parent['snapshot']['root'])
    assert identity(source)['sha256'] == row['frozen']['sha256']
    assert identity(repo / 'selfhost' / relative)['sha256'] == row['frozen']['sha256']
    target = project / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
    members[str(relative)] = identity(target)
assert len(members) == 214
file = project / 'src/core/index.bend'
before = file.read_text()
needle = '      kc(List<&2, KDef>, String.eq(dn(h), name), u => index_remove(rest, name), u => Con{h, index_remove(rest, name)})\n'
replacement = """      index_remove_step(h, rest, name, String.eq(dn(h), name))

@unsafe
def index_remove_step(
  +h: KDef, +rest: List<&2, KDef>, +name: String, +same: Bool,
) -> List<&2, KDef>:
  match same:
    case True{}: index_remove(rest, name)
    case False{}: Con{h, index_remove(rest, name)}
"""
assert before.count(needle) == 1
after = before.replace(needle, replacement)
file.write_text(after)
members['src/core/index.bend'] = identity(file)
(out / 'candidate.patch').write_text(''.join(difflib.unified_diff(
    before.splitlines(True), after.splitlines(True),
    fromfile='parent/src/core/index.bend', tofile='candidate/src/core/index.bend')))
(out / 'workflow.json').write_text(json.dumps({
    'project': str(project), 'upstream': parent['config']['upstream'],
    'profile': 'equality', 'cpu': '0', 'jobs': 1, 'strictExact': True}, indent=2) + '\n')
assert [identity(p) for p in inputs] == frozen_inputs
(out / 'manifest.json').write_text(json.dumps({
    'kind': 'phase22-index-remove-worker-candidate', 'complete': True,
    'installed': False, 'parentApi': parent['api'], 'inputs': frozen_inputs,
    'project': str(project), 'members': members,
    'changedFiles': ['src/core/index.bend'],
    'delta': {'physicalLines': len(after.splitlines())-len(before.splitlines()), 'nonblankLines': len([x for x in after.splitlines() if x.strip()])-len([x for x in before.splitlines() if x.strip()]),
              'bytes': len(after.encode()) - len(before.encode()),
              'definitions': 1, 'laws': 0, 'types': 0},
    'scope': 'One explicit Bool worker preserves complete list filtering, order, duplicate semantics and demand. No installed source, host or index representation change.'
}, indent=2) + '\n')
print(out)
