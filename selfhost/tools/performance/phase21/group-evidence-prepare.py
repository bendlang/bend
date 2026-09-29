#!/usr/bin/env python3
"""Freeze metadata after root's Phase21 release freeze; no capture/extraction."""
from pathlib import Path
import hashlib, json, shutil, subprocess, sys

R = Path(__file__).resolve().parents[4]
E = R / 'implementation/phase21/group-evidence'
BASE = 'c385d3913e9f10c6c4d9c5cfef3f34bc0682d351'
SOURCE = 'selfhost/build/phase21/group-range-source-02/project'
ATTEMPT = 'selfhost/build/phase21/group-range-build-02'
API = '44094e58cb0ef033e2c08c2827565e859c3594b3136868d4f821262145aea7f0'
STATUS = 'installed-group-range-release'

def sha(p):
    h = hashlib.sha256()
    with p.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''): h.update(block)
    return h.hexdigest()

def write(p, value):
    with p.open('x') as f: json.dump(value, f, indent=2); f.write('\n')

def path(value):
    p = Path(value)
    p = (p if p.is_absolute() else R / p).resolve()
    assert p.is_relative_to(R), p
    return p

def relative(p): return p.relative_to(R).as_posix()

freeze_arg, expected_sha = sys.argv[1:]
original = path(freeze_arg)
assert sha(original) == expected_sha
root = json.loads(original.read_text())
assert root['allProducersClosed'] is True
assert root['finalAttempt'] == ATTEMPT and root['finalSource'] == SOURCE
assert root['finalApiSha256'] == API and root['anchorStatus'] == STATUS
release_commit = subprocess.check_output(['git', 'rev-parse', root['releaseCommit'] + '^{commit}'], cwd=R, text=True).strip()
frozen_inputs = {}
for row in root['files'] + root['inputs']:
    p = path(row.get('file', row.get('path')))
    assert sha(p) == row['sha256'], p
    if 'bytes' in row: assert p.stat().st_size == row['bytes'], p
    frozen_inputs[relative(p)] = row['sha256']
assert not (E / 'root-release-freeze.json').exists()
shutil.copy2(original, E / 'root-release-freeze.json')

prior_protected = 'implementation/phase20/declaration-evidence/phase6-start-state.json'
protected = json.loads((R / prior_protected).read_text())['rows']
assert len(protected) == 75
status = {x[3:]: x[:2] for x in subprocess.check_output(
    ['git', 'status', '--porcelain=v1', '--untracked-files=all'], cwd=R, text=True).splitlines()}
for row in protected:
    assert sha(R / row['path']) == row['sha256'] and status.get(row['path']) == row['status'], row['path']
write(E / 'phase6-start-state.json', {'kind': 'phase21-protected-phase6-identities',
    'count': 75, 'unchangedFrom': prior_protected, 'rows': protected})

source = R / SOURCE
members = {p.relative_to(source).as_posix(): sha(p) for p in sorted(source.rglob('*')) if p.is_file()}
assert len(members) == 214
manifest = json.loads((source.parent / 'manifest.json').read_text())
assert set(members) == set(manifest['members'])
changed = []; delta_lines = delta_bytes = 0
for name, digest in members.items():
    assert digest == manifest['members'][name]['sha256']
    before = subprocess.check_output(['git', 'show', BASE + ':selfhost/' + name], cwd=R)
    after = (source / name).read_bytes()
    if before != after:
        changed.append(name)
        delta_lines += len(after.splitlines()) - len(before.splitlines())
        delta_bytes += len(after) - len(before)
assert changed == ['src/front/declarations.bend', 'src/front/parallel.bend', 'src/front/sugar.bend']
assert (delta_lines, delta_bytes) == (3, 156)
write(E / 'source-delta.json', {'baselineCommit': BASE, 'source': SOURCE,
    'members': members, 'count': 214, 'changedFiles': changed,
    'delta': {'physicalLines': 3, 'bytes': 156, 'definitions': 0, 'laws': 0, 'types': 0}})

phase_root = R / 'selfhost/build/phase21'
roots = sorted(relative(p) for p in phase_root.iterdir() if p.name.startswith('group-'))
if 'closedRoots' in root: assert set(roots) == set(root['closedRoots'])
# Freeze exact lists once; the collector has no wildcard prefix selection.
trees = {'final': [], 'experiments': []}
for name in roots:
    leaf = Path(name).name
    topic = 'experiments' if leaf.startswith(('group-comma-', 'group-range-source-',
        'group-range-build-', 'group-range-controls-', 'group-range-structure-')) else 'final'
    trees[topic].append(name)
extra = set(frozen_inputs)
for folder in ['design/phase21', 'implementation/phase21', 'selfhost/tools/performance/phase21']:
    extra.update(relative(p) for p in (R / folder).iterdir() if p.is_file())
extra.update(relative(p) for p in E.iterdir() if p.is_file() and not p.name.startswith('selection-review'))
extra.update([
    relative(original), 'selfhost/dist/base.bend', 'selfhost/dist/release-lineage/equality.mjs',
    'implementation/phase20/declaration-evidence/preservation.json',
    'implementation/phase20/declaration-evidence/capsule-01/manifest.json',
    'implementation/phase19/context-evidence/preservation.json',
    'implementation/phase19/context-evidence/capsule-02/manifest.json',
    'selfhost/tools/performance/phase20/declaration-preserve.py',
    'selfhost/tools/performance/phase16/compact-recover.py',
    'selfhost/tools/performance/phase18/cursor-paired-run.mjs',
    'selfhost/tools/performance/phase16/check-matrix-v2.mjs',
    'selfhost/tools/performance/phase16/frontend-gate-v2.mjs',
    'selfhost/tools/performance/phase15/release-smoke.mjs',
    'selfhost/tools/performance/phase15/release-smoke-launch.mjs',
    'selfhost/tools/development/workflow.mjs', 'selfhost/tools/development/process.mjs',
    'selfhost/tools/development/equality.mjs', 'selfhost/tools/development/release.mjs',
    'selfhost/tools/conformance/inventory.mjs', 'selfhost/tools/conformance/compare-artifacts.mjs',
    'selfhost/tools/conformance/persistent-probe.mjs',
    'implementation/phase8/conformance-harness-evidence/frontend-triage.mjs'])
# A root can also appear in input identities; avoid duplicate collector topics.
extra = {name for name in extra if not any(name == tree or name.startswith(tree + '/') for tree in roots)}
for name in extra: assert (R / name).is_file(), name
excluded = [relative(p) for p in (R / 'selfhost/build/phase19').glob('context-*/project')]
excluded += [relative(p) for p in (R / 'selfhost/build/phase19').glob('context-*/snapshot')]
excluded += ['experiments/phase6', 'implementation/phase6', 'selfhost/tools/performance/phase6',
    'selfhost/dist/release-history', 'selfhost/dist/selfcheck', 'selfhost/dist/selfhost']
plan = {'kind': 'phase21-group-evidence-selection', 'anchorStatus': STATUS,
    'releaseCommit': release_commit, 'baselineCommit': BASE, 'finalSource': SOURCE,
    'finalAttempt': ATTEMPT, 'finalApiSha256': API, 'phaseRoot': relative(phase_root),
    'topics': {'final': [], 'experiments': []}, 'extraTrees': trees,
    'extraFiles': {'final': sorted(extra)}, 'closedDocumentationDirectories': [],
    'excludedTrees': excluded, 'excludedTopLevelReason': 'Outside exact closed Phase21 group selection.',
    'maxPartPayloadBytes': 64000000, 'maxArchiveBytes': 99000000,
    'externalPrerequisites': [
        {'kind': 'committed-source', 'commit': BASE, 'scope': 'Fixed Phase20 source for independent 214-member reconstruction.'},
        {'kind': 'prior-release-capsule', 'path': 'implementation/phase20/declaration-evidence/preservation.json',
         'manifest': 'implementation/phase20/declaration-evidence/capsule-01/manifest.json',
         'scope': 'Phase20 comparison source/API and earlier dependency chain; original records are not rebound.'},
        {'kind': 'private-contextual-capsule', 'path': 'implementation/phase19/context-evidence/preservation.json',
         'scope': 'Prior contextual experiments stay external; no project payload is captured.'},
        {'kind': 'upstream-checkout', 'path': 'selfhost/.bootstrap/upstream-phase8',
         'commit': 'b2111cf43244e65f76ddc278ee695e669f720cbf', 'scope': 'Pinned compiler/Base/upstream fixtures.'},
        {'kind': 'toolchain', 'scope': 'Recorded Node/Clang binaries remain external; no home configuration or credentials.'}]}
write(E / 'selection-proposal.json', plan)
for name in sorted(extra | {relative(E / 'selection-proposal.json')}): frozen_inputs[name] = sha(R / name)
write(E / 'root-freeze.json', {'kind': 'phase21-preservation-root-freeze-adapter',
    'authorized': True, 'authorization': 'Root explicit preservation grant and retained final release freeze.',
    'allProducersClosed': True, 'anchorStatus': STATUS, 'finalAttempt': ATTEMPT,
    'finalApiSha256': API, 'inputs': [{'path': p, 'sha256': h} for p, h in sorted(frozen_inputs.items())],
    'additionalFiles': []})
print(json.dumps({'prepared': True, 'roots': len(roots), 'sourceMembers': 214,
    'deltaFiles': changed, 'protected': 75, 'captureRun': False}))
