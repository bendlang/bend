from pathlib import Path
import hashlib, json, subprocess, tempfile

root = Path(__file__).resolve().parents[4]
out = root / 'implementation/phase16/wave7-evidence'
manifest = json.loads((out / 'manifest.json').read_text())
patch = out / 'phase15-to-wave7.patch'
assert hashlib.sha256(patch.read_bytes()).hexdigest() == manifest['patch']['sha256']
prefix = 'selfhost/build/phase16/wave7-source-01/project/'
members = [r for r in manifest['members'] if r['path'].startswith(prefix)]
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
baseline = []
with tempfile.TemporaryDirectory(prefix='bend-wave7-patch-', dir='/tmp') as directory:
    restored = Path(directory)
    for row in members:
        relative = row['path'][len(prefix):]
        data = subprocess.check_output(['git', 'show', head + ':selfhost/' + relative], cwd=root)
        destination = restored / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
        baseline.append({'path': relative, 'sha256': hashlib.sha256(data).hexdigest()})
    subprocess.run(['git', 'apply', '--check', str(patch)], cwd=restored, check=True)
    subprocess.run(['git', 'apply', str(patch)], cwd=restored, check=True)
    for row in members:
        file = restored / row['path'][len(prefix):]
        assert file.stat().st_size == row['bytes'] and hashlib.sha256(file.read_bytes()).hexdigest() == row['sha256'], row['path']
report = {'complete': True, 'pass': True, 'gitBaseline': head, 'sourceFiles': len(members),
          'scope': 'Reconstruct source solely from committed Phase15 files plus the saved patch, then compare every byte with the accepted wave7 inventory.',
          'toolSha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), 'baseline': baseline}
with (out / 'patch-recovery.json').open('x') as f:
    json.dump(report, f, indent=2)
    f.write('\n')
print(json.dumps({k: report[k] for k in ['complete', 'pass', 'gitBaseline', 'sourceFiles']}))
