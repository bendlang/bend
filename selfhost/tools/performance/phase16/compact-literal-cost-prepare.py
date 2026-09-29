from pathlib import Path
import difflib, hashlib, json, shutil

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
out = phase / 'compact-literal-cost-01'
out.mkdir()
before = phase / 'wave9-build-01'
after = phase / 'literal-context-build-01'

def ident(p):
    return {'file': str(p.resolve()), 'canonicalPath': str(p.resolve()),
            'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}

def hosts(attempt):
    m = json.loads((attempt / 'attempt.json').read_text())
    return {str(Path(r['frozen']['file']).relative_to(m['snapshot']['root'])):
            Path(r['frozen']['file']) for r in m['snapshot']['sources']
            if '/tools/' in r['frozen']['file']}

a, b = hosts(before), hosts(after)
assert a.keys() == b.keys()
changed = sorted(n for n in a if a[n].read_bytes() != b[n].read_bytes())
assert changed == ['tools/development/workflow.mjs', 'tools/typed-driver.mjs']
review = {'pass': True,
          'scope': 'Complete reviewed literal transport/cache5/range validation delta; no language parsing or checking moved into the host. Namespace correction is Bend source. Prototype timing does not authorize promotion.',
          'changes': [], 'controls': [],
          'plan': ident(root / 'design/phase16/compact-literal-cost.md')}
for n in changed:
    patch = out / (n.replace('/', '-') + '.patch')
    patch.write_text(''.join(difflib.unified_diff(a[n].read_text().splitlines(True),
                    b[n].read_text().splitlines(True), fromfile=n, tofile=n)))
    review['changes'].append({'relative': n, 'before': ident(a[n]),
                              'after': ident(b[n]), 'patch': ident(patch)})
for name in ['literal-context-frontend-01', 'literal-context-checks-01',
             'literal-context-literals-01', 'checker-literal-host-01']:
    p = phase / name / 'report.json'
    r = json.loads(p.read_text())
    assert r['complete'] and r['pass']
    review['controls'].append(ident(p))
(out / 'host-review.json').write_text(json.dumps(review, indent=2) + '\n')
attempt = json.loads((before / 'attempt.json').read_text())
bootstrap = json.loads(Path(attempt['bootstrapReport']['file']).read_text())
config = {'baseline': str(before), 'candidate': str(after),
          'source': bootstrap['source'], 'cpu': '0', 'mode': 'measure',
          'hostReview': str(out / 'host-review.json')}
(out / 'matrix.json').write_text(json.dumps(config, indent=2) + '\n')
shutil.copy2(__file__, out / 'consumed-tool.py')
print(out)
