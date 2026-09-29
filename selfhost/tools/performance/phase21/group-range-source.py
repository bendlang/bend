#!/usr/bin/env python3
"""Freeze the one-expression R1 candidate after independent parent controls."""
import difflib
import hashlib
import json
import shutil
import sys
from pathlib import Path

repo = Path(__file__).resolve().parents[4]
phase = repo / 'selfhost/build/phase21'
out = phase / 'group-range-source-01'
parent_file = repo / 'selfhost/build/phase20/import-diagnostic-build-04/attempt.json'
parent = json.loads(parent_file.read_text())
assert parent['api']['sha256'] == '40c8f7f3b7cd0e96aef57d7d574ebfd85607cd4e096909d083b450b4d973362c'
baseline, structural_plan = map(lambda s: Path(s).resolve(), sys.argv[1:])
controls = json.loads(baseline.read_text())
assert controls['complete'], 'Independent baseline collection must close before source preparation'

def identity(p):
    p = p.resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
            'bytes': p.stat().st_size}

assert identity(Path(parent['api']['file']))['sha256'] == parent['api']['sha256']
inputs = [Path(__file__), parent_file, Path(parent['api']['file']), baseline, structural_plan,
          phase / 'group-start-state-01.json', repo / 'design/phase21/group-boundaries.md',
          repo / 'design/phase21/range-execution.md']
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
file = project / 'src/front/declarations.bend'
before = file.read_text()
needle = 'u => kt("Local", "", 0, 1, [pat, v, b]))'
replacement = 'u => kt_span("Local", "", 0, 1, [pat, v, b], kb(pat), ke(pat)))'
assert before.count(needle) == 1
after = before.replace(needle, replacement)
assert len(before.splitlines()) == len(after.splitlines())
file.write_text(after)
members['src/front/declarations.bend'] = identity(file)
(out / 'candidate.patch').write_text(''.join(difflib.unified_diff(
    before.splitlines(True), after.splitlines(True),
    fromfile='parent/src/front/declarations.bend', tofile='candidate/src/front/declarations.bend')))
(out / 'workflow.json').write_text(json.dumps({
    'project': str(project), 'upstream': parent['config']['upstream'],
    'profile': 'equality', 'cpu': '0', 'jobs': 1, 'strictExact': True}, indent=2) + '\n')
assert [identity(p) for p in inputs] == frozen_inputs
(out / 'manifest.json').write_text(json.dumps({
    'kind': 'phase21-local-first-binder-origin-candidate', 'complete': True,
    'installed': False, 'parentApi': parent['api'], 'inputs': frozen_inputs,
    'project': str(project), 'members': members,
    'changedFiles': ['src/front/declarations.bend'],
    'delta': {'physicalLines': 0, 'nonblankLines': 0,
              'bytes': len(after.encode()) - len(before.encode()),
              'definitions': 0, 'laws': 0, 'types': 0},
    'scope': 'Successful raw Local receives existing pattern range, including typed locals through this shared producer; child-error choice unchanged. Separate typed/parallel parsing workers, host and traversal remain unchanged. No acceptance or error-order change intended.'
}, indent=2) + '\n')
print(out)
