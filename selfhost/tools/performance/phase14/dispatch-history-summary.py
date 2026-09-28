#!/usr/bin/env python3
"""Classify retained complete-result changes; never change the gate's oracle."""
import collections
import hashlib
import json
import pathlib
import shutil
import sys

source = pathlib.Path(sys.argv[1]).resolve()
out = pathlib.Path(sys.argv[2]).resolve()
out.mkdir()
def identity(file):
    return {'file': str(file), 'sha256': hashlib.sha256(file.read_bytes()).hexdigest()}
report = json.loads(source.read_text())
assert report['complete'] and report['pass'] and report['inputsVerified'] and report['exactPairedCompleteResults']
summary = {'kind': 'phase14-combined-history-difference-classification', 'complete': False,
           'scope': 'Classification of original recorded results only. The actual history gate compares every complete paired result without stripping any field.',
           'inputs': [identity(source), identity(pathlib.Path(__file__).resolve())], 'histories': []}
for history in report['histories']:
    baseline, candidate = history['rows']
    assert baseline['name'] == 'baseline' and candidate['name'] == 'candidate'
    assert len(baseline['requests']) == len(candidate['requests'])
    assert all(a['result'] == b['result'] for a, b in zip(baseline['requests'], candidate['requests']))
    fields, changes = collections.Counter(), []
    for row in baseline['changedFromPhase12']:
        a, b = row['oldResult'], row['currentResult']
        changed = sorted(k for k in set(a) | set(b) if k not in a or k not in b or a[k] != b[k])
        fields.update(changed)
        if changed != ['hostProvenance']:
            changes.append({'index': row['index'], 'id': row['id'], 'lane': row['lane'], 'changedFields': changed})
    summary['histories'].append({'name': history['name'], 'requestsPerVariant': len(baseline['requests']),
                                'changedFromPhase12': len(baseline['changedFromPhase12']), 'changedFieldCounts': dict(fields),
                                'beyondHostProvenance': changes, 'exactPairedCompleteResults': True})
assert identity(source) == summary['inputs'][0]
summary['complete'] = True
shutil.copyfile(__file__, out / 'consumed-tool.py')
(out / 'report.json').write_text(json.dumps(summary, indent=2) + '\n')
print(json.dumps(summary['histories']))
