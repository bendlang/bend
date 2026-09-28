"""Challenge iterative reference traversal against the unchanged legacy walker."""
import importlib.util
import json
from pathlib import Path
import random
import sys
sys.dont_write_bytecode = True
here = Path(__file__).resolve().parent

def module(name, file):
    spec = importlib.util.spec_from_file_location(name, file)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value

adapter = module('adapter', here / 'collect.py')
legacy = module('original', here.parents[1] / 'phase8/migration-evidence/collect.py')
rng = random.Random(14001)
keys = ['file', 'path', 'canonicalPath', 'source', 'target', 'snapshot', 'api', 'apiPath', 'apiFile', 'base', 'basePath', 'runtime', 'runtimePath', 'checkedApi', 'checkedApiFile']
values = ['', '/repo/ordinary.mjs', 'relative/file.json', 'https://external.example/file', 'http://external.example/file', 'inline source\n', 17, None]
hashes = ['a' * 64, 'B' * 64, 'not-a-hash', None, 4]
rows = []
for index in range(200):
    leaf = {key: rng.choice(values) for key in keys}
    leaf.update({key: rng.choice(hashes) for key in ['sha256', 'apiSha256', 'baseSha256', 'runtimeSha256', 'checkedApiSha256']})
    value = {'first': leaf, 'sequence': [leaf.copy(), None, {'nested': leaf.copy()}], 'last': {'file': 'final', 'sha256': 'c' * 64}}
    expected = list(legacy.json_references(value, 'unknown.json'))
    actual = list(adapter.references(value, 'unknown.json'))
    assert actual == expected, index
    rows.append(len(actual))
# Every hash/path pair is covered positively in addition to randomized refusal.
all_pairs = {key: 'path/' + key for key in keys}
all_pairs.update({key: 'd' * 64 for key in ['sha256', 'apiSha256', 'baseSha256', 'runtimeSha256', 'checkedApiSha256']})
assert list(adapter.references(all_pairs, 'pairs.json')) == list(legacy.json_references(all_pairs, 'pairs.json'))
assert len(list(adapter.references(all_pairs, 'pairs.json'))) == 15
# A linked value deeper than the old recursive walker can traverse still keeps
# its one deeply nested reference with the exact pointer.
deep = {'file': 'deep/file', 'sha256': 'e' * 64}
for _ in range(2000):
    deep = {'tail': deep}
actual = list(adapter.references(deep, 'deep.json'))
assert actual == [{'report': 'deep.json', 'pointer': '/tail' * 2000 + '/file', 'path': 'deep/file', 'sha256': 'e' * 64}]
legacy_overflow = False
try:
    list(legacy.json_references(deep, 'deep.json'))
except RecursionError:
    legacy_overflow = True
assert legacy_overflow
# Exact historical inline contracts retain all non-inline ordinary references.
for origin, (_, _, count) in adapter.contracts.items():
    value = json.loads((here.parents[2] / origin).read_text())
    filtered = [r for r in legacy.json_references(value, origin)
                if not adapter.re.fullmatch(adapter.contracts[origin][1], r['pointer'])]
    assert list(adapter.references(value, origin)) == filtered
assert len(adapter.embedded) == 61
report = {'complete': True, 'pass': True, 'randomSeed': 14001, 'shallowEquivalenceCases': 200,
          'allPositiveHashPathPairs': 15, 'deepTailCount': 2000,
          'legacyDeepTraversalOverflows': legacy_overflow, 'iterativeDeepReferenceExact': True,
          'historicalInlineFieldsVerified': 61,
          'scope': 'Exact reference ordering/content equivalence; no omitted raw books or generic source exceptions.'}
with (here / 'reference-walk-check.json').open('x') as stream:
    json.dump(report, stream, indent=2)
    stream.write('\n')
print(json.dumps(report, indent=2))
