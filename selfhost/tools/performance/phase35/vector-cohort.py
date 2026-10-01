#!/usr/bin/env python3
"""Bind a prepared checked candidate and frozen references to pair/fold controls."""
import json
from pathlib import Path
import shutil
import sys

HERE = Path(__file__).resolve().parent
PROGRAMS = HERE.parent/'programs'
sys.path.insert(0, str(PROGRAMS))
from run import load_bundle, relative_path, require, verify
from support import identity, save


def file_identity(file):
    row = identity(file)
    row['file'] = row.pop('path')
    return row


def main():
    if len(sys.argv) != 3:
        raise SystemExit('usage: vector-cohort.py PREP_MANIFEST NEW_OUT')
    candidate_file, out = [Path(x).resolve() for x in sys.argv[1:]]
    catalog_file = PROGRAMS/'catalog.json'
    reference_file = PROGRAMS/'baseline/manifest.json'
    catalog = json.loads(catalog_file.read_text())
    selected = [next(c for c in catalog['cases'] if c['id'] == name)
                for name in ['local-pair', 'local-fold']]
    inputs = [identity(p) for p in [__file__, PROGRAMS/'run.py', PROGRAMS/'support.py',
        catalog_file, HERE/'vector-pair-points.json']]
    for case in selected:
        inputs.append(verify(relative_path(PROGRAMS, case['source']['path']), case['source']))
    candidate_manifest = json.loads(candidate_file.read_text())
    role = candidate_manifest['roles']['candidate']
    require(role.get('compiler', {}).get('kind') in ['checked-development-attempt', 'installed-checked-release'],
            'Control cohort requires a prepared checked compiler, not a JS prototype')
    preparation_file = relative_path(candidate_file.parent, candidate_manifest['preparation']['path'])
    inputs.append(verify(preparation_file, candidate_manifest['preparation']))
    require(json.loads(preparation_file.read_text())['complete'], 'Incomplete preparation')
    out.mkdir(parents=True, exist_ok=False)
    (out/'consumed').mkdir()
    for file in [Path(__file__), PROGRAMS/'run.py', PROGRAMS/'support.py', catalog_file,
                 HERE/'vector-pair-points.json', candidate_file, reference_file]:
        dest = ('candidate-' if file == candidate_file else 'reference-' if file == reference_file else '')+file.name
        shutil.copyfile(file, out/'consumed'/dest)
    report = dict(kind='phase35-private-vector-control-cohort', complete=False,
                  inputs=inputs, cases={}, adaptation='pair default.bench invokes original default.pair')
    report['pass'] = False
    save(out/'derive.json', report)
    try:
        catalog_hash = identity(catalog_file)['sha256']
        reference = load_bundle(reference_file, catalog, catalog_hash, selected,
                                ['baseline', 'typescript'], inputs, out/'raw-reference')
        candidate = load_bundle(candidate_file, catalog, catalog_hash, selected,
                                ['candidate'], inputs, out/'raw-candidate')
        for case, name in zip(selected, ['pair', 'fold']):
            target = out/name
            target.mkdir()
            cohort = dict(complete=False, variants={}, inputs={}, sourceSha256=case['source']['sha256'])
            raw_candidate = candidate['points'][case['id']]['candidate']
            original_candidate = relative_path(candidate_file.parent, raw_candidate['path'])
            emission_file = Path(str(original_candidate)+'.json')
            emission = json.loads(emission_file.read_text())
            require(emission['complete'] and emission['observation']['checked'], 'Unchecked fixture emission')
            require(emission['input']['sha256'] == case['source']['sha256']
                    and emission['output']['sha256'] == identity(original_candidate)['sha256'],
                    'Candidate receipt/source/module mismatch')
            inputs.append(identity(emission_file))
            shutil.copyfile(emission_file, target/'candidate-checked-emission.json')
            cohort['inputs']['checkedEmission'] = file_identity(target/'candidate-checked-emission.json')
            for role in ['baseline', 'candidate', 'typescript']:
                bundle = candidate if role == 'candidate' else reference
                entry = bundle['points'][case['id']][role]
                source = Path(entry['resolved'])
                text = source.read_text()
                if name == 'pair':
                    require(text.count('export default ') == 1, 'Expected one export default')
                    text = text.replace('export default ', 'const $Pair_exports = ', 1)
                    text += '\nexport default {...$Pair_exports,bench:p=>$Pair_exports.pair(p)};\n'
                output = target/(role+'.mjs')
                output.write_text(text)
                cohort['variants'][role] = file_identity(output)
                cohort['inputs'][role] = file_identity(source)
            if name == 'pair':
                shutil.copyfile(HERE/'vector-pair-points.json', target/'points.json')
                cohort['inputs']['points'] = file_identity(target/'points.json')
            cohort['complete'] = True
            save(target/'derive.json', cohort)
            report['cases'][name] = dict(cohort=file_identity(target/'derive.json'), variants=cohort['variants'])
            save(out/'derive.json', report)
        for item in inputs:
            verify(item['path'], item)
        report['complete'] = report['pass'] = True
    except Exception as error:
        report['error'] = repr(error)
        raise
    finally:
        save(out/'derive.json', report)
    print(json.dumps(dict(complete=True, cohorts=[str(out/c) for c in ['pair','fold']])))


if __name__ == '__main__':
    main()
