"""Check the exact inherited inline-source contracts without running inventory."""
import copy
import importlib.util
import json
from pathlib import Path
import sys
sys.dont_write_bytecode = True
here = Path(__file__).resolve().parent
root = here.parents[2]
spec = importlib.util.spec_from_file_location('adapter', here / 'collect.py')
adapter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(adapter)
rows = []
for origin, (_, _, count) in adapter.contracts.items():
    value = json.loads((root / origin).read_text())
    before = len(adapter.embedded)
    references = list(adapter.references(value, origin))
    assert len(adapter.embedded) - before == count
    assert all(not ('\n' in row['path']) for row in references)
    rows.append({'report': origin, 'inlineSources': count, 'sha256': adapter.expected_reports[origin]})
assert len(adapter.embedded) == 61
first = next(iter(adapter.contracts))
original = json.loads((root / first).read_text())
modified = copy.deepcopy(original)
modified['kind'] = 'other'
try:
    list(adapter.references(modified, first))
    raise AssertionError('Wrong report kind was admitted')
except RuntimeError:
    pass
expected = adapter.expected_reports[first]
adapter.expected_reports[first] = '0' * 64
try:
    list(adapter.references(original, first))
    raise AssertionError('Changed report identity was admitted')
except RuntimeError:
    pass
finally:
    adapter.expected_reports[first] = expected
source = 'not a path\n'
generic = {'source': source, 'sha256': adapter.legacy.digest(source.encode())}
assert list(adapter.references(generic, 'selfhost/build/phase15/unknown/report.json')) == [
    {'report': 'selfhost/build/phase15/unknown/report.json', 'pointer': '/source', 'path': source,
     'sha256': generic['sha256']}]
report = {'complete': True, 'pass': True, 'contracts': rows, 'verifiedInlineSourceFields': 61,
          'negativeControls': ['wrong report kind refused', 'changed byte-pinned report refused',
                               'unknown source field remains a normal reference'],
          'scope': 'Exact inherited adapter contracts only; no inventory, prerequisite archive verification or Phase15 capture yet.'}
with (here / 'inline-source-check.json').open('x') as stream:
    json.dump(report, stream, indent=2)
    stream.write('\n')
print(json.dumps(report, indent=2))
