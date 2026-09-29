from pathlib import Path
import difflib, hashlib, json, shutil

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
out = phase / 'program-completion-cost-01'
out.mkdir()
before = phase / 'wave7-build-01'
after = phase / 'program-completion-checked-01'

def ident(p):
    return {'file': str(p.resolve()), 'canonicalPath': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}

def hosts(p):
    return {str(f.relative_to(p / 'snapshot')): f for f in (p / 'snapshot/tools').rglob('*') if f.is_file()}

a, b = hosts(before), hosts(after)
assert a.keys() == b.keys()
changed = [name for name in a if a[name].read_bytes() != b[name].read_bytes()]
assert changed == ['tools/typed-driver.mjs'], changed
f = changed[0]
patch = out / 'host.patch'
patch.write_text(''.join(difflib.unified_diff(a[f].read_text().splitlines(True), b[f].read_text().splitlines(True), fromfile=f, tofile=f)))
review = {'pass': True, 'scope': 'Only whole-program orchestration, advertised ABI2 and compatible export discovery change; retained source discovery/cache/validation/reference/output boundaries. Independent host10 and direct8 controls pass.',
          'changes': [{'relative': f, 'before': ident(a[f]), 'after': ident(b[f]), 'patch': ident(patch)}],
          'controls': [ident(phase / name / 'report.json') for name in ['program-completion-host-01', 'program-completion-direct-02']],
          'plan': ident(root / 'design/phase16/program-completion-cost.md')}
for row in review['controls']:
    report = json.loads(Path(row['file']).read_text())
    assert report['complete'] and report['pass']
(out / 'host-review.json').write_text(json.dumps(review, indent=2) + '\n')
attempt = json.loads((before / 'attempt.json').read_text())
bootstrap = json.loads(Path(attempt['bootstrapReport']['file']).read_text())
config = {'baseline': str(before), 'candidate': str(after), 'source': bootstrap['source'], 'cpu': '0', 'mode': 'measure', 'hostReview': str(out / 'host-review.json')}
(out / 'matrix.json').write_text(json.dumps(config, indent=2) + '\n')
shutil.copy2(__file__, out / 'consumed-tool.py')
print(out)
