#!/usr/bin/env python3
import hashlib
import json
import pathlib

root = pathlib.Path(__file__).resolve().parents[3]
out = root / 'build/phase12/normalizer-observations-01'
out.mkdir(exist_ok=False)
paths = {
    'baseline': root / 'build/phase11/integrated-01/validation-001/selected/paired.json',
    'seed': root / 'build/phase12/normalizer-seed-checked-01/validation-001/selected/paired.json',
    'delayed': root / 'build/phase12/normalizer-checked-01/validation-001/selected/paired.json',
}
reports = {name: json.loads(file.read_text()) for name, file in paths.items()}
rows = []
baseline = {(r['id'], r['lane']): r for r in reports['baseline']['rows']}
for variant in ['seed', 'delayed']:
    for candidate in reports[variant]['rows']:
        key = (candidate['id'], candidate['lane'])
        before = baseline[key]
        fields = ['candidate', 'candidateVerdict', 'candidateEvidence', 'reference']
        differences = [field for field in fields if before.get(field) != candidate.get(field)]
        rows.append({'variant': variant, 'id': key[0], 'lane': key[1],
                     'exact': not differences, 'differences': differences})
report = {'kind': 'phase12-original-public-observation-preservation',
          'scope': 'Exact complete normalized program outcomes, verdict and evidence, plus same reference outcomes; no timing/provenance fields discarded from these objects.',
          'inputs': [{'file': str(file), 'sha256': hashlib.sha256(file.read_bytes()).hexdigest()}
                     for file in [pathlib.Path(__file__), *paths.values()]],
          'baselineCount': len(baseline), 'rows': rows,
          'pass': len(baseline) == 21 and len(rows) == 42 and all(r['exact'] for r in rows)}
(out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'pass': report['pass'], 'observationsPerCandidate': len(rows)//2,
                  'differences': [r for r in rows if not r['exact']]}))
assert report['pass']
