#!/usr/bin/env python3
"""Read-only immutable Phase22 duplicate estimate; never creates hardlinks."""
from pathlib import Path
import hashlib, json, os, stat, sys
R = Path(__file__).resolve().parents[4]
BASE = R / 'selfhost/build/phase22'
plan_path, out_arg = map(Path, sys.argv[1:])
plan_path = plan_path.resolve(); out = out_arg.resolve()
initial_plan = plan_path.read_bytes()
tool_path = Path(__file__).resolve(); initial_tool = tool_path.read_bytes()
plan = json.loads(initial_plan)
assert plan.get('readOnlyEstimateAuthorized') is True
assert plan.get('allListedProducersClosed') is True
assert not out.exists()
roots = []
for name in plan['roots']:
    p = R / name
    assert p.is_absolute() and p.resolve() == p and p.is_relative_to(BASE)
    assert p != BASE and p.is_dir()
    assert not any(parent.is_symlink() for parent in [p, *p.parents])
    assert not any(p.is_relative_to(q) or q.is_relative_to(p) for q in roots)
    roots.append(p)
assert not any(out.is_relative_to(p) for p in roots)
out.mkdir()
(out / 'consumed-plan.json').write_bytes(initial_plan)
(out / 'consumed-tool.py').write_bytes(initial_tool)
def digest(data): return hashlib.sha256(data).hexdigest()
def key(s): return (s.st_dev, s.st_ino, s.st_mode, s.st_size, s.st_mtime_ns, s.st_ctime_ns, s.st_nlink)
files = []; excluded = []
for root in roots:
    for directory, dirs, names in os.walk(root, followlinks=False):
        parent = Path(directory)
        for name in list(dirs):
            if (parent / name).is_symlink():
                excluded.append({'path': str((parent / name).relative_to(R)), 'reason': 'directory symlink'})
                dirs.remove(name)
        for name in names:
            p = parent / name; s = p.lstat()
            if not stat.S_ISREG(s.st_mode) or s.st_nlink != 1:
                excluded.append({'path': str(p.relative_to(R)), 'reason': 'not singly linked regular file'})
                continue
            files.append({'path': str(p.relative_to(R)), 'bytes': s.st_size, 'mode': stat.S_IMODE(s.st_mode), 'device': s.st_dev, 'inode': s.st_ino, 'links': s.st_nlink, 'allocatedBytes': s.st_blocks * 512, 'mtimeNs': s.st_mtime_ns, 'ctimeNs': s.st_ctime_ns, '_stat': key(s)})
by_shape = {}
for row in files: by_shape.setdefault((row['device'], row['bytes'], row['mode']), []).append(row)
groups = []; hashed = 0
for shape, rows in by_shape.items():
    if len(rows) < 2 or shape[1] == 0: continue
    by_hash = {}
    for row in rows:
        p = R / row['path']; assert p.resolve() == p
        h = hashlib.sha256()
        fd = os.open(p, os.O_RDONLY | os.O_NOFOLLOW)
        with os.fdopen(fd, 'rb') as f:
            assert key(os.fstat(f.fileno())) == row['_stat']
            for block in iter(lambda: f.read(1024 * 1024), b''): h.update(block)
            assert key(os.fstat(f.fileno())) == row['_stat']
        assert key(p.lstat()) == row['_stat']
        row['sha256'] = h.hexdigest(); hashed += 1
        by_hash.setdefault(row['sha256'], []).append(row)
    for sha, same in by_hash.items():
        if len(same) < 2: continue
        same.sort(key=lambda x: x['path'])
        groups.append({'sha256': sha, 'bytes': shape[1], 'mode': shape[2], 'device': shape[0], 'donor': same[0]['path'], 'members': [x['path'] for x in same], 'logicalDuplicateBytes': shape[1] * (len(same) - 1), 'estimatedFreedAllocatedBytes': sum(x['allocatedBytes'] for x in same[1:])})
for row in files: row.pop('_stat')
assert plan_path.read_bytes() == initial_plan and tool_path.read_bytes() == initial_tool
report = {'kind': 'phase22-read-only-hardlink-estimate', 'complete': True, 'mutationAuthorized': False, 'plan': {'file': str(plan_path), 'sha256': digest(initial_plan)}, 'tool': {'file': str(tool_path), 'sha256': digest(initial_tool)}, 'roots': plan['roots'], 'regularFiles': len(files), 'hashedFiles': hashed, 'groups': groups, 'estimatedFreedAllocatedBytes': sum(g['estimatedFreedAllocatedBytes'] for g in groups), 'logicalDuplicateBytes': sum(g['logicalDuplicateBytes'] for g in groups), 'files': files, 'excluded': excluded, 'scope': 'Read-only estimate. No inode sharing, deletion, capture or permission for mutation. All files remain required logical capsule members.'}
(out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({k: report[k] for k in ['complete', 'regularFiles', 'hashedFiles', 'estimatedFreedAllocatedBytes', 'logicalDuplicateBytes']}))
