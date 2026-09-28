"""Validate the narrow collector adapter without changing original evidence."""
import copy
import importlib.util
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
here = Path(__file__).resolve().parent
root = here.parents[2]
spec = importlib.util.spec_from_file_location('phase13_collector', here / 'collect.py')
adapter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(adapter)
report = {'kind': 'phase13-inline-source-reference-controls', 'complete': False, 'pass': False,
          'adapter': adapter.identity(here / 'collect.py'), 'reports': [], 'negativeControls': []}
for name, (_, _, expected) in adapter.contracts.items():
    data = json.loads((root / name).read_text())
    adapter.embedded.clear()
    remaining = list(adapter.references(data, name))
    assert len(adapter.embedded) == expected
    audited = list(adapter.embedded.values())
    assert all(row['report'] == name for row in audited)
    report['reports'].append({'file': name, **adapter.identity(root / name),
                              'inlineReferences': audited, 'remainingFileReferences': remaining})
    broken = copy.deepcopy(data)
    keys = audited[0]['pointer'].split('/')[1:-1]
    row = broken
    for key in keys:
        row = row[int(key)] if isinstance(row, list) else row[key]
    row['source'] += ' hash mismatch'
    try:
        list(adapter.references(broken, name))
    except RuntimeError as error:
        assert 'hash mismatch' in str(error)
        report['negativeControls'].append({'report': name, 'refused': str(error)})
    else:
        raise AssertionError('Corrupt inline source was accepted')
fixture = {'source': 'real/source.mjs', 'file': 'real/input.mjs', 'sha256': 'a' * 64}
refs = list(adapter.references(fixture, 'ordinary-report.json'))
assert sorted(row['path'] for row in refs) == ['real/input.mjs', 'real/source.mjs']
report['ordinaryFileReferencesPreserved'] = refs
report['complete'] = report['pass'] = True
output = here / 'inline-source-check-01.json'
assert not output.exists()
output.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'complete': True, 'pass': True, 'inlineSources': sum(len(row['inlineReferences']) for row in report['reports']),
                  'corruptHashRefusals': len(report['negativeControls']), 'ordinaryFileReferences': len(refs)}))
