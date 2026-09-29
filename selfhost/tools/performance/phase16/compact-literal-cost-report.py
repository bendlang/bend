from pathlib import Path
import hashlib, json, re

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
report_path = phase / 'compact-literal-matrix-01/report.json'
r = json.loads(report_path.read_text())
assert r['complete'] and not r.get('error') and r['unsafeDefinitionSetsAgree']
assert len(r['rows']) == 6 and all(x['observation']['pass'] for x in r['rows'])
for item in r['inputs']:
    assert hashlib.sha256(Path(item['file']).read_bytes()).hexdigest() == item['sha256']

def ident(p):
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}

def count(project):
    files = json.loads((project / 'src/compiler.json').read_text())['modules']
    text = ''.join((project / f).read_text() for f in files)
    return {'modules': len(files), 'physicalLines': len(text.splitlines()),
            'nonblankLines': sum(bool(l.strip()) for l in text.splitlines()),
            'bytes': len(text.encode()), 'definitions': len(re.findall(r'^def ', text, re.M)),
            'laws': len(re.findall(r'^law ', text, re.M)),
            'types': len(re.findall(r'^type ', text, re.M))}

s = r['statistics']
out = {'kind': 'phase16-compact-literal-cost-summary', 'complete': True, 'pass': True,
       'installationEligible': False, 'report': ident(report_path),
       'plan': ident(root / 'design/phase16/compact-literal-cost.md'),
       'source': r['source'], 'statistics': s, 'ratios': r['ratios'],
       'memoryReduction': 1 - s['candidate']['maxRssKiB'] / s['baseline']['maxRssKiB'],
       'rows': [{'variant': x['variant'], 'processMs': x['execution']['wallMs'],
                 'requestMs': x['observation']['requestMs'],
                 'maxRssKiB': x['observation']['maxRssKiB']} for x in r['rows']],
       'sourceCounts': {n: count(phase / p / 'project') for n, p in
                        [('baseline', 'wave9-source-01'), ('candidate', 'literal-context-source-04')]},
       'limitations': ['Two serial samples per image, single machine and workload.',
                       'Candidate also contains the small constructor-scope correction.',
                       'Known memo identity/size boundaries prevent promotion.',
                       'No generated-program runtime, new fixed point or kernel claim.'],
       'tool': ident(Path(__file__))}
target = root / 'implementation/phase16/compact-literal-cost.json'
assert not target.exists()
target.write_text(json.dumps(out, indent=2) + '\n')
print(json.dumps({'ratios': out['ratios'], 'memoryReduction': out['memoryReduction'],
                  'sourceCounts': out['sourceCounts']}))
