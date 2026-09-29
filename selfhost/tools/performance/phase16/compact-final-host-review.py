"""Freeze the complete reviewed final host delta for histories and timing."""
from pathlib import Path
import difflib, hashlib, json, shutil

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
out = phase / 'compact-final-host-review-01'
out.mkdir()
final_dir = phase / 'compact-final-build-01'
final = json.loads((final_dir / 'attempt.json').read_text())

def ident(p):
    return {'file': str(p.resolve()), 'canonicalPath': str(p.resolve()),
            'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}

def hosts(m):
    return {str(Path(r['frozen']['file']).relative_to(m['snapshot']['root'])):
            Path(r['frozen']['file']) for r in m['snapshot']['sources']
            if '/tools/' in r['frozen']['file']}

current = hosts(final)
for label, directory in [('wave9', phase / 'wave9-build-01'),
                         ('phase15', root / 'selfhost/build/phase15/combined-02')]:
    before = json.loads((directory / 'attempt.json').read_text())
    old = hosts(before)
    assert old.keys() == current.keys()
    changed = sorted(n for n in old if old[n].read_bytes() != current[n].read_bytes())
    assert changed == ['tools/development/workflow.mjs', 'tools/typed-driver.mjs']
    review = {'pass': True, 'baseline': ident(directory / 'attempt.json'),
              'candidate': ident(final_dir / 'attempt.json'),
              'plan': ident(root / 'design/phase16/compact-final-gates.md'),
              'scope': 'Complete source-read review: explicit termABI1/spanABI3/loadABI1 transport and cache6 identity, range/literal/Lambda payload checks, contextual ordered one-body loader, shared structured rejection rendering, and checkerABI2 final completion. Semantic parsing/checking remains Bend. Legacy absent term/span/load and checker0/1 paths remain capability selected. Probe-only exports removed. Identical runtime/Base/reference and all other host bytes required.',
              'changes': []}
    for name in changed:
        p = out / (label + '-' + name.replace('/', '-') + '.patch')
        p.write_text(''.join(difflib.unified_diff(old[name].read_text().splitlines(True),
            current[name].read_text().splitlines(True), fromfile=name, tofile=name)))
        review['changes'].append({'relative': name, 'before': ident(old[name]),
                                  'after': ident(current[name]), 'patch': ident(p)})
    for field in ['base', 'runtime']:
        assert before[field]['sha256'] == final[field]['sha256']
    assert before['config']['upstream'] == final['config']['upstream']
    (out / (label + '-review.json')).write_text(json.dumps(review, indent=2) + '\n')
history = {'baselineAttempt': str(phase / 'wave9-build-01'),
           'candidateAttempt': str(final_dir), 'hostReview': str(out / 'wave9-review.json')}
(out / 'history.json').write_text(json.dumps(history, indent=2) + '\n')
bootstrap = json.loads(Path(final['bootstrapReport']['file']).read_text())
timing = {'baseline': str(root / 'selfhost/build/phase15/combined-02'),
          'candidate': str(final_dir), 'source': bootstrap['source'], 'cpu': '0',
          'mode': 'measure', 'hostReview': str(out / 'phase15-review.json')}
(out / 'matrix.json').write_text(json.dumps(timing, indent=2) + '\n')
shutil.copy2(__file__, out / 'consumed-tool.py')
print(out)
