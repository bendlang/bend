#!/usr/bin/env python3
"""Coalesce identical, closed experiment files; preserve every logical byte/path/mode."""
from pathlib import Path
import hashlib, json, os, stat, sys

ROOT = Path(__file__).resolve().parents[4]
def need(ok, message):
    if not ok: raise ValueError(message)
def sha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1024 * 1024), b''): h.update(b)
    return h.hexdigest()
def ident(p):
    return {'file': str(p), 'sha256': sha(p)}
planfile = Path(sys.argv[1]).resolve()
plan = json.loads(planfile.read_text())
need(plan['mutationAuthorized'] is True and plan['allListedProducersClosed'] is True, 'Closed-file authorization required')
estimatefile = Path(plan['estimate']['file']).resolve()
need(sha(estimatefile) == plan['estimate']['sha256'], 'Changed estimate')
estimate = json.loads(estimatefile.read_text())
need(estimate['complete'] is True and estimate['mutationAuthorized'] is False, 'Expected read-only estimate')
need(plan['roots'] == estimate['roots'], 'Exact reviewed roots required')
out = Path(sys.argv[2]).resolve()
need(not any(out.is_relative_to(ROOT/r) for r in plan['roots']), 'Output inside selected root')
out.mkdir()
report = {'kind': 'phase22-closed-evidence-hardlink-dedup', 'complete': False, 'pass': False,
    'inputs': [ident(planfile), ident(estimatefile), ident(Path(__file__).resolve())],
    'groups': [], 'replacedFiles': 0, 'estimatedFreedAllocatedBytes': 0,
    'scope': 'Only physical storage sharing changes. All logical files, bytes and modes remain present. Inode/link count/ctime and donor mtime are not evidence identity; future edits to these immutable files are forbidden.'}
def save():
    (out/'report.json').write_text(json.dumps(report, indent=2)+'\n')
(out/'consumed-tool.py').write_bytes(Path(__file__).read_bytes())
(out/'consumed-plan.json').write_bytes(planfile.read_bytes())
save()
def file(name):
    p = ROOT/name
    need(p.is_relative_to(ROOT/'selfhost/build/phase22'), 'Outside Phase22')
    need(p.as_posix() == str(ROOT)+'/'+name and '..' not in Path(name).parts, 'Unsafe name')
    need(any(name.startswith(r+'/') for r in plan['roots']), 'Outside exact closed roots')
    need(not any(q.is_symlink() for q in [p, *p.parents]), 'Symlink path')
    return p
rows = {x['path']: x for x in estimate['files']}
def verify(name, group, initial=False):
    p = file(name); s = p.lstat(); old = rows[name]
    need(stat.S_ISREG(s.st_mode), 'Nonregular file: '+name)
    need(s.st_dev == group['device'] == old['device'], 'Device changed: '+name)
    need(s.st_size == group['bytes'] == old['bytes'], 'Size changed: '+name)
    need(stat.S_IMODE(s.st_mode) == group['mode'] == old['mode'], 'Mode changed: '+name)
    if initial: need(s.st_ino == old['inode'] and s.st_nlink == old['links'] == 1, 'Inode or links changed: '+name)
    need(sha(p) == group['sha256'], 'Bytes changed: '+name)
    return p, s
try:
    used = set()
    for g in estimate['groups']:
        need(len(g['members']) >= 2 and g['donor'] in g['members'], 'Bad group')
        for name in g['members']:
            need(name not in used, 'Overlapping groups'); used.add(name); verify(name, g, True)
    report['preflightFiles'] = len(used); save()
    for g in estimate['groups']:
        anchor, ast = verify(g['donor'], g, True)
        row = {'sha256': g['sha256'], 'donor': g['donor'], 'members': g['members'], 'completed': []}
        report['groups'].append(row); save()
        for name in g['members']:
            if name == g['donor']: continue
            target, old = verify(name, g, True)
            current = anchor.lstat()
            need(current.st_ino == ast.st_ino and current.st_dev == ast.st_dev, 'Donor replaced')
            need(current.st_size == g['bytes'] and stat.S_IMODE(current.st_mode) == g['mode'], 'Donor metadata changed')
            temp = target.with_name(target.name+'.phase22-hardlink-new')
            need(not temp.exists() and not temp.is_symlink(), 'Existing temporary path')
            created = False
            try:
                os.link(anchor, temp, follow_symlinks=False)
                created = True
                linked = temp.lstat()
                need(linked.st_ino == ast.st_ino and linked.st_dev == ast.st_dev, 'Wrong new link')
                need(target.lstat().st_ino == old.st_ino, 'Target changed before replacement')
                os.replace(temp, target)
            finally:
                if created and (temp.exists() or temp.is_symlink()):
                    remaining = temp.lstat()
                    need(remaining.st_ino == ast.st_ino and remaining.st_dev == ast.st_dev, 'Temporary path replaced')
                    temp.unlink()
            row['completed'].append(name)
            report['replacedFiles'] += 1
            report['estimatedFreedAllocatedBytes'] += old.st_blocks * 512
            save()
        for name in g['members']:
            _, s = verify(name, g)
            need(s.st_ino == ast.st_ino, 'Group inode disagreement')
        row['pass'] = True; save()
    for item in report['inputs']: need(sha(item['file']) == item['sha256'], 'Input changed during operation')
    report['complete'] = report['pass'] = True
except Exception as error:
    report['error'] = repr(error); save(); raise
save()
print(json.dumps({k: report[k] for k in ['complete', 'pass', 'replacedFiles', 'estimatedFreedAllocatedBytes']}))
