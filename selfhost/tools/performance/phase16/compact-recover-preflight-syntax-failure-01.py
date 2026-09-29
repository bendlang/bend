#!/usr/bin/env python3
"""Independent scoped-capsule extraction and committed-Phase15 source recovery."""
from pathlib import Path, PurePosixPath
import hashlib, json, os, posixpath, stat, subprocess, sys, tarfile, tempfile

ROOT = Path(__file__).resolve().parents[4]

def need(ok, message):
    if not ok: raise ValueError(message)

def sha(file):
    h = hashlib.sha256()
    with open(file, 'rb') as f:
        for block in iter(lambda:f.read(1024*1024),b''): h.update(block)
    return h.hexdigest()

def safe(name):
    p = PurePosixPath(name)
    need(bool(name) and not p.is_absolute() and '..' not in p.parts and '.' not in p.parts, 'Unsafe path: '+name)
    return p

def regular(file, row):
    s = file.lstat(); need(stat.S_ISREG(s.st_mode), 'Not regular: '+str(file))
    need(s.st_size == row['bytes'] and sha(file) == row['sha256'] and stat.S_IMODE(s.st_mode) == row['mode'], 'Restored bytes/mode mismatch: '+str(file))

directory, report_arg = sys.argv[1:]; capsule = Path(directory).resolve(); report_file = Path(report_arg).resolve()
report = {'kind':'phase16-independent-compact-recovery','complete':False,'pass':False,'toolSha256':sha(__file__)}
need(not report_file.exists(), 'Recovery report already exists')
try:
    manifest_file = capsule/'manifest.json'; raw = manifest_file.read_bytes(); m = json.loads(raw)
    need(m['complete'] and m['captured'], 'Incomplete capture')
    inventory_file = capsule/m['inventory']['path']; need(sha(inventory_file) == m['inventory']['sha256'], 'Inventory changed')
    inv = json.loads(inventory_file.read_text()); rows = inv['members']; indexed = {r['path']:r for r in rows}
    need(len(indexed) == len(rows), 'Duplicate inventory path')
    links = {r['path'] for r in rows if r['type'] == 'symlink'}
    for row in rows:
        need(row['type'] in ['file','symlink'], 'Unsupported inventory member')
        need(not any(str(p) in links for p in safe(row['path']).parents), 'Symlink ancestor')
        if row['type'] == 'symlink':
            need(not row['target'].startswith('/'), 'Absolute link')
            target = posixpath.normpath(posixpath.join(posixpath.dirname(row['path']),row['target'])); safe(target)
            need(target in indexed and indexed[target]['type'] == 'file' and target == row['resolvedTarget'], 'Unselected link target')
            need(indexed[target]['sha256'] == row['targetSha256'], 'Link target hash mismatch')
            need(not any(str(p) in links for p in safe(target).parents), 'Target symlink ancestor')
            data = os.fsencode(row['target']); need(len(data) == row['bytes'] and hashlib.sha256(data).hexdigest() == row['sha256'], 'Link literal identity mismatch')
    covered = []
    for archive in m['archives']:
        safe(archive['path']); p = capsule/archive['path']
        need(p.stat().st_size == archive['bytes'] and sha(p) == archive['sha256'], 'Archive changed')
        covered.extend(archive['members'])
    need(len(covered) == len(set(covered)) and set(covered) == set(indexed), 'Archive coverage mismatch')
    with tempfile.TemporaryDirectory(prefix='phase16-compact-recovery-',dir='/tmp') as tmp:
        recovered = Path(tmp); seen = set()
        for archive in m['archives']:
            with tarfile.open(capsule/archive['path'],'r:gz') as tar:
                names = []; delayed = []
                for member in tar:
                    name = member.name; safe(name); need(name in indexed and name not in seen, 'Unknown/duplicate tar member')
                    seen.add(name); names.append(name); row = indexed[name]; target = recovered/name
                    need(stat.S_IMODE(member.mode) == row['mode'], 'Tar mode mismatch')
                    if row['type'] == 'symlink':
                        need(member.issym() and member.linkname == row['target'], 'Tar link mismatch'); continue
                    need(member.isfile() and not member.islnk() and member.size == row['bytes'], 'Tar regular type/size mismatch')
                    target.parent.mkdir(parents=True,exist_ok=True)
                    with tar.extractfile(member) as source, target.open('xb') as output:
                        for block in iter(lambda:source.read(1024*1024),b''): output.write(block)
                    target.chmod(row['mode']); regular(target,row)
                need(set(names) == set(archive['members']), 'Per-archive coverage mismatch')
        need(seen == set(indexed), 'Missing restored members')
        for row in rows:
            if row['type'] == 'symlink':
                target = recovered/row['path']; target.parent.mkdir(parents=True,exist_ok=True)
                regular(recovered/row['resolvedTarget'],indexed[row['resolvedTarget']]); os.symlink(row['target'],target)
                need(os.readlink(target) == row['target'] and stat.S_IMODE(target.lstat().st_mode) == row['mode'], 'Restored link mismatch')
                need(target.resolve().is_relative_to(recovered), 'Restored link escapes')
        for row in rows:
            if row['type'] == 'file': regular(recovered/row['path'],row)
        report['extraction'] = {'files':len(rows),'symlinks':len(links),'bytes':sum(r['bytes'] for r in rows),'allBytesAndModesVerified':True}
    patch = capsule/inv['patch']['path']; need(sha(patch) == inv['patch']['sha256'], 'Source patch changed')
    prefix = inv['finalSource']+'/'; source_rows = [r for r in rows if r['path'].startswith(prefix)]
    base_rows = {r['path']:r for r in inv['sourceBaseline']}
    need(set(base_rows) == {r['path'][len(prefix):] for r in source_rows}, 'Source membership mismatch')
    with tempfile.TemporaryDirectory(prefix='phase16-source-recovery-',dir='/tmp') as tmp:
        restored = Path(tmp)
        for name, base in base_rows.items():
            safe(name)
            if base['exists']:
                data = subprocess.check_output(['git','show',inv['baselineCommit']+':selfhost/'+name],cwd=ROOT)
                need(hashlib.sha256(data).hexdigest() == base['sha256'], 'Committed baseline bytes mismatch')
                target = restored/name; target.parent.mkdir(parents=True,exist_ok=True); target.write_bytes(data)
        for args in [['--check'],[]]: subprocess.run(['git','apply',*args,str(patch)],cwd=restored,check=True)
        for row in source_rows:
            target = restored/row['path'][len(prefix):]; target.chmod(row['mode']); regular(target,row)
        actual = {p.relative_to(restored).as_posix() for p in restored.rglob('*') if p.is_file()}
        need(actual == set(base_rows), 'Unexpected reconstructed source membership')
        report['sourceReconstruction'] = {'baselineCommit':inv['baselineCommit'],'files':len(source_rows),'allBytesAndModesVerified':True,'usesWorkingTreeSource':False,'patchSha256':sha(patch)}
    need(manifest_file.read_bytes() == raw and sha(inventory_file) == m['inventory']['sha256'], 'Metadata changed during recovery')
    report.update(complete=True,pass=True,manifestSha256=hashlib.sha256(raw).hexdigest(),inventorySha256=sha(inventory_file))
except Exception as e:
    report['error'] = repr(e)
finally:
    with report_file.open('x') as f: json.dump(report,f,indent=2); f.write('\n')
print(json.dumps(report));
if not report['pass']: sys.exit(1)
