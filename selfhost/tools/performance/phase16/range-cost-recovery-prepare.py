"""Compose two independently controlled cost changes onto integration04."""
from pathlib import Path
import difflib
import hashlib
import json
import shutil

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
base = phase / 'spans-integration-source-04/project'
out = phase / 'range-cost-recovery-source-01'
out.mkdir()
shutil.copytree(base, out / 'project')

def identity(p):
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}

owners = [
    ('unsafe-scan-source-01/project', 'src/check/kernel.bend', 'unsafe-scan-candidate-01/report.json'),
    ('spans-allocation-source-01/project', 'src/front/parser.bend', 'spans-allocation-controls-01/report.json'),
]
changes = []
for source, relative, control in owners:
    source = phase / source
    report = phase / control
    data = json.loads(report.read_text())
    assert data['complete'] and data['pass'], control
    changed = [str(p.relative_to(base)) for p in base.rglob('*')
               if p.is_file() and p.read_bytes() != (source / p.relative_to(base)).read_bytes()]
    assert changed == [relative], changed
    target = out / 'project' / relative
    shutil.copy2(source / relative, target)
    patch = out / (relative.replace('/', '_') + '.patch')
    patch.write_text(''.join(difflib.unified_diff(
        (base / relative).read_text().splitlines(True), target.read_text().splitlines(True),
        fromfile=relative, tofile=relative)))
    changes.append({'relative': relative, 'before': identity(base / relative),
                    'after': identity(target), 'patch': identity(patch), 'controls': identity(report)})
(out / 'manifest.json').write_text(json.dumps({
    'parent': str(base), 'changes': changes, 'tool': identity(Path(__file__)),
    'scope': 'Composition only; no additional source changes or timing claim.'}, indent=2) + '\n')
(out / 'workflow.json').write_text(json.dumps({
    'project': str(out / 'project'), 'upstream': str(root / 'selfhost/.bootstrap/upstream-phase8'),
    'profile': 'equality', 'cpu': '0', 'jobs': 1}, indent=2) + '\n')
shutil.copy2(__file__, out / 'consumed-tool.py')
selection = {'cases': [{'id': name + '.bend', 'lanes': ['check']} for name in [
    'check/partial_self_call', 'check/partial_self_call_stuck',
    'check/unsafe_loop', 'check/unsafe_forward_safe', 'check/unsafe_relies', 'check/unsafe_many',
    'halt/polymorphic_self_recursion', 'halt/sugar_self_call', 'halt/type_level_recursion',
    'run/unsafe_mutual', 'run/unsafe_tail_cycle', 'run/unsafe_forward']]}
for case in selection['cases']:
    assert (root / 'selfhost/.bootstrap/upstream-phase8/tests' / case['id']).is_file(), case['id']
(out / 'recursion-selection.json').write_text(json.dumps(selection, indent=2) + '\n')
print(out)
