#!/usr/bin/env python3
"""Post-capture checks only; never edits selected compiler or experiment inputs."""
from pathlib import Path
import hashlib, json, subprocess

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

baseline = ROOT/'implementation/phase18/evidence/phase6-start-state.json'
original = json.loads(baseline.read_text())
protected = original['unrelatedPhase6']
assert len(protected) == 75
copy = HERE/'phase6-start-state.json'
with copy.open('xb') as output:
    output.write(baseline.read_bytes())
raw = subprocess.check_output(
    ['git', 'status', '--porcelain=v1', '--untracked-files=all', '--',
     *[row['path'] for row in protected]], cwd=ROOT).decode()
statuses = {line[3:]: line[:2] for line in raw.splitlines()}
inventory = json.loads((HERE/'capsule-01/inventory.json').read_text())
selected = {row['path'] for row in inventory['members']}
rows = []
for before in protected:
    current = {'sha256': sha(ROOT/before['path']),
               'status': statuses.get(before['path'], '')}
    rows.append({'path': before['path'], 'before': before, 'after': current,
                 'pass': current['sha256'] == before['sha256']
                     and current['status'] == before['status'],
                 'excludedFromCapture': before['path'] not in selected})
freeze = json.loads((HERE/'root-freeze.json').read_text())
frozen = [{'path': row['path'], 'expectedSha256': row['sha256'],
           'actualSha256': sha(ROOT/row['path']),
           'pass': sha(ROOT/row['path']) == row['sha256']}
          for row in freeze['inputs']]
report = {
    'kind': 'phase19-prefix-post-capture-protected-and-frozen-input-audit',
    'complete': True,
    'pass': all(row['pass'] and row['excludedFromCapture'] for row in rows)
        and all(row['pass'] for row in frozen),
    'count': len(rows),
    'baseline': {'original': str(baseline.relative_to(ROOT)),
                 'preservedCopy': str(copy.relative_to(ROOT)),
                 'sha256': sha(copy)},
    'scope': '75 protected Phase6 byte/status identities plus root-frozen inputs; no protected payload copied.',
    'tool': {'path': str(Path(__file__).relative_to(ROOT)),
             'sha256': sha(Path(__file__))},
    'rows': rows, 'frozenInputs': frozen}
with (HERE/'post-capture-audit.json').open('x') as output:
    json.dump(report, output, indent=2)
    output.write('\n')
print(json.dumps({'pass': report['pass'], 'protected': len(rows),
                  'frozenInputs': len(frozen)}))
raise SystemExit(0 if report['pass'] else 1)
