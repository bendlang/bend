#!/usr/bin/env python3
"""Reuse exact checked Phase35 and pinned TypeScript modules as the Phase36 reference."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PROGRAMS = HERE.parent/'programs'
sys.path.insert(0, str(PROGRAMS))
from run import load_bundle, relative_path, require
from prepare import observe_row
from support import identity, save

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('out', type=Path)
a = p.parse_args()
out = a.out.resolve()
out.mkdir(parents=True, exist_ok=False)
source = ROOT/'selfhost/build/phase35/combined-full-01/manifest.json'
reference = PROGRAMS/'baseline/manifest.json'
attempt_file = ROOT/'selfhost/build/phase35/checked09/attempt.json'
catalog_file = PROGRAMS/'catalog.json'
inputs = []
def tracked(file):
    row = identity(file)
    inputs.append(row)
    return row

def verify(entry):
    actual = tracked(entry.get('path', entry.get('file')))
    require(actual['sha256'] == entry['sha256'], 'Changed preserved input: '+actual['path'])
    return actual

report = dict(kind='phase36-reference-role-adapter', complete=False,
              scope='No compiler or benchmark execution. Exact previous checked output becomes baseline; pinned TS and catalog stay unchanged.',
              inputs=inputs, checkedReceipts=[], adapters=[])
save(out/'preparation.json', report)
try:
    for file in [__file__, PROGRAMS/'run.py', PROGRAMS/'support.py', source, reference, attempt_file, catalog_file]:
        tracked(file)
    candidate = json.loads(source.read_text())
    portable = json.loads(reference.read_text())
    preparation_file = relative_path(source.parent, candidate['preparation']['path'])
    verify(dict(path=str(preparation_file), sha256=candidate['preparation']['sha256']))
    preparation = json.loads(preparation_file.read_text())
    require(preparation['complete'], 'Incomplete previous preparation')
    require(tracked(PROGRAMS/'prepare.py')['sha256'] == preparation['producer']['sha256'], 'Changed observation adapter')
    catalog = json.loads(catalog_file.read_text())
    attempt = json.loads(attempt_file.read_text())
    require(attempt['checked'] and attempt['config']['strictExact'], 'Unchecked baseline attempt')
    require(attempt['api']['sha256'] == '467bc7dec2751a94cb677c5eb2da22a8fb69ee3522c6e164cb2bfcc147a78d82', 'Wrong baseline API')
    for key in ['api', 'checkedApi', 'runtime', 'base', 'bootstrapReport', 'derivationReport']:
        verify(attempt[key])
    for item in attempt['snapshot']['sources']:
        verify(item['frozen'])
    compiler = candidate['roles']['candidate']['compiler']
    for key in ['api', 'runtime', 'base']:
        require(compiler[key]['sha256'] == attempt[key]['sha256'], 'Wrong prepared '+key)
    previous = load_bundle(source, catalog, tracked(catalog_file)['sha256'], catalog['cases'], ['candidate'], inputs, out/'phase35')
    ts = load_bundle(reference, catalog, tracked(catalog_file)['sha256'], catalog['cases'], ['baseline', 'typescript'], inputs, out/'portable')
    rows = []
    seen = set()
    for case in catalog['cases']:
        old = previous['points'][case['id']]['candidate']
        original = relative_path(source.parent, old['path'])
        checked = original
        expected_output = old['sha256']
        if case.get('adapter'):
            require(case['adapter'] == 'generic-row', 'Unknown case adapter')
            matches = [r for r in preparation['adapters'] if r['adapted']['sha256'] == old['sha256']]
            require(len(matches) == 1, 'Missing unique observation adapter')
            adapter = matches[0]
            checked = relative_path(source.parent, adapter['raw']['path'])
            expected_output = adapter['raw']['sha256']
            verify(dict(path=str(checked), sha256=expected_output))
            require(observe_row(checked.read_text()) == original.read_text(), 'Observation adapter replay differs')
            require(adapter['producer']['sha256'] == preparation['producer']['sha256'], 'Wrong observer producer')
            report['adapters'].append(adapter)
        receipt_file = Path(str(checked)+'.json')
        receipt = json.loads(receipt_file.read_text())
        receipt_identity = tracked(receipt_file)
        require(receipt['complete'] and receipt['observation']['checked'], 'Unchecked prepared output')
        require(receipt['input']['sha256'] == case['source']['sha256'], 'Wrong checked source')
        require(receipt['attempt']['sha256'] == tracked(attempt_file)['sha256'], 'Wrong checked attempt')
        require(receipt['compiler']['api']['sha256'] == attempt['api']['sha256'], 'Wrong emitted API')
        require(receipt['output']['sha256'] == expected_output, 'Wrong checked output')
        verify(receipt['output'])
        dest = out/'phase35'/checked.relative_to(source.parent)
        if dest not in seen:
            shutil.copyfile(receipt_file, Path(str(dest)+'.json'))
            seen.add(dest)
            report['checkedReceipts'].append(receipt_identity)
        modules = {}
        for role, entry in [('baseline', old), ('typescript', ts['points'][case['id']]['typescript'])]:
            dest = Path(entry['resolved'])
            tracked(dest)
            modules[role] = dict(path=str(dest.relative_to(out)), sha256=entry['sha256'], bytes=entry['bytes'])
        rows.append(dict(id=case['id'], sourceSha256=case['source']['sha256'], point=case['point'], modules=modules))
    result = dict(kind='bend-program-bundle', schemaVersion=1, complete=True,
                  upstreamCommit=catalog['upstreamCommit'], catalogSha256=tracked(catalog_file)['sha256'],
                  roles={'baseline':dict(label='Phase35 checked09', compiler=compiler), 'typescript':portable['roles']['typescript']}, cases=rows,
                  preparation=dict(path='preparation.json'), provenance='Exact checked Phase35 modules and archived pinned TS, verified by preparation.json; role relabel only.')
    for row in inputs:
        require(identity(row['path']) == row, 'Input changed during reference adapter')
    report['complete'] = True
    save(out/'preparation.json', report)
    result['preparation'].update(sha256=identity(out/'preparation.json')['sha256'])
    save(out/'manifest.json', result)
    shutil.copyfile(__file__, out/'consumed-freeze-baseline.py')
except Exception as error:
    report['error'] = repr(error)
    save(out/'preparation.json', report)
    raise
print(json.dumps(dict(complete=True, cases=len(rows), checkedModules=len(seen), manifest=str(out/'manifest.json'))))
