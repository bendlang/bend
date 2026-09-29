from pathlib import Path
import difflib, gzip, hashlib, json, shutil, tarfile, tempfile

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
out = root / 'implementation/phase16/wave7-evidence'
out.mkdir()
files = {}

def add(p):
    p = p.resolve()
    assert p.is_relative_to(root), p
    assert p.is_file() and not p.is_symlink(), p
    files[str(p.relative_to(root))] = p

def tree(p):
    for f in sorted(p.rglob('*')):
        if f.is_file():
            add(f)

for name in ['wave7-build-01/validation-001', 'wave7-frontend-01', 'wave7-checks-01', 'wave7-alias-direct-01', 'wave6-frontend-01']:
    report = json.loads((phase / name / 'report.json').read_text())
    assert report['complete'] and report['pass'], name
for name in ['wave7-source-01', 'wave7-build-01', 'wave7-frontend-01', 'wave7-checks-01', 'wave7-alias-direct-01']:
    tree(phase / name)
for file in ['wave7-source-counts-01.json', 'wave6-frontend-01/report.json', 'wave6-frontend-01/candidate.json']:
    add(phase / file)
for file in ['selfhost/build/phase15/frontend-01/candidate.json', 'selfhost/build/phase8/reference-frontend-01/reference.json']:
    add(root / file)
for case in json.loads((phase / 'wave7-source-01/selection.json').read_text())['cases']:
    if 'file' in case:
        # Sibling .bend files preserve custom imports without language parsing in this archiver.
        folder = Path(case['file']).parent
        for file in sorted(folder.rglob('*.bend')):
            add(file)

source = phase / 'wave7-source-01/project'
baseline = root / 'selfhost/build/phase15/combined-02/snapshot'
patch = []
for folder in ['src', 'tools', 'tests']:
    names = {str(p.relative_to(source)) for p in (source / folder).rglob('*') if p.is_file()}
    names |= {str(p.relative_to(baseline)) for p in (baseline / folder).rglob('*') if p.is_file()}
    for name in sorted(names):
        old, new = baseline / name, source / name
        before = old.read_text() if old.exists() else ''
        after = new.read_text() if new.exists() else ''
        if before != after:
            patch.extend(difflib.unified_diff(before.splitlines(True), after.splitlines(True), fromfile='a/' + name, tofile='b/' + name))
(out / 'phase15-to-wave7.patch').write_text(''.join(patch))

def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

inventory = [{'path': name, 'bytes': p.stat().st_size, 'sha256': digest(p)} for name, p in sorted(files.items())]
archive = out / 'checkpoint.tar.gz'
with archive.open('xb') as raw:
    with gzip.GzipFile(filename='', mode='wb', fileobj=raw, compresslevel=6, mtime=0) as compressed:
        with tarfile.open(fileobj=compressed, mode='w') as tar:
            for row in inventory:
                p = files[row['path']]
                info = tar.gettarinfo(str(p), arcname=row['path'])
                info.uid = info.gid = info.mtime = 0
                info.uname = info.gname = ''
                with p.open('rb') as f:
                    tar.addfile(info, f)
for row in inventory:
    assert digest(files[row['path']]) == row['sha256'], row['path']

with tempfile.TemporaryDirectory(prefix='bend-wave7-recovery-', dir='/tmp') as directory:
    recovered = Path(directory)
    with tarfile.open(archive, 'r:gz') as tar:
        assert set(tar.getnames()) == set(files)
        for member in tar.getmembers():
            assert member.isfile() and not member.name.startswith('/') and '..' not in Path(member.name).parts
        tar.extractall(recovered)
    for row in inventory:
        p = recovered / row['path']
        assert p.stat().st_size == row['bytes'] and digest(p) == row['sha256'], row['path']

report = {'complete': True, 'pass': True, 'scope': 'Accepted wave7 checkpoint and exact comparison inputs only; earlier Phase16 experiments and profiles need separate preservation.',
          'tool': {'path': str(Path(__file__).relative_to(root)), 'sha256': digest(Path(__file__))},
          'archive': {'path': archive.name, 'bytes': archive.stat().st_size, 'sha256': digest(archive)},
          'patch': {'path': 'phase15-to-wave7.patch', 'sha256': digest(out / 'phase15-to-wave7.patch')},
          'recovery': {'files': len(inventory), 'bytes': sum(row['bytes'] for row in inventory), 'independentExtractAndHash': True},
          'members': inventory}
(out / 'manifest.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({k: report[k] for k in ['complete', 'pass', 'archive', 'recovery']}))
