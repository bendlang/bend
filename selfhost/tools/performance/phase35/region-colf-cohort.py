#!/usr/bin/env python3
"""Bind checked raytrace emissions to preserved partial-colf controls."""
import json
from pathlib import Path
import re
import shutil
import sys
HERE = Path(__file__).resolve().parent
PROGRAMS = HERE.parent/'programs'
sys.path.insert(0, str(PROGRAMS))
from run import load_bundle, relative_path, require, verify
from support import identity, save


def main():
    if len(sys.argv) != 3:
        raise SystemExit('usage: region-colf-cohort.py PREP_MANIFEST NEW_OUT')
    candidate_file, out = [Path(x).resolve() for x in sys.argv[1:]]
    catalog_file = PROGRAMS/'catalog.json'
    reference_file = PROGRAMS/'baseline/manifest.json'
    controls_file = HERE/'region-colf-controls.mjs'
    catalog = json.loads(catalog_file.read_text())
    case = next(c for c in catalog['cases'] if c['id'] == 'raytrace')
    manifest = json.loads(candidate_file.read_text())
    compiler = manifest['roles']['candidate']['compiler']
    require(compiler['kind'] in ['checked-development-attempt', 'installed-checked-release'], 'Checked compiler required')
    inputs = [identity(p) for p in [__file__, PROGRAMS/'run.py', PROGRAMS/'support.py', catalog_file,
        controls_file, candidate_file, reference_file]]
    preparation = relative_path(candidate_file.parent, manifest['preparation']['path'])
    inputs.append(verify(preparation, manifest['preparation']))
    require(json.loads(preparation.read_text())['complete'], 'Incomplete preparation')
    out.mkdir(parents=True, exist_ok=False)
    (out/'consumed').mkdir()
    for p in [Path(__file__), controls_file, catalog_file, candidate_file, reference_file]:
        name = ('candidate-' if p == candidate_file else 'reference-' if p == reference_file else '')+p.name
        shutil.copyfile(p, out/'consumed'/name)
    report = dict(kind='phase35-checked-partial-colf-cohort', complete=False, inputs=inputs,
                  compiler=compiler, dependencies=[], modules=[], adaptation='Original compiler bodies are retained except a candidate-only diagnostic counter at colf fast tree admission; append shared colf diagnostic exports.')
    save(out/'derive.json', report)
    try:
        catalog_hash = identity(catalog_file)['sha256']
        reference = load_bundle(reference_file, catalog, catalog_hash, [case], ['baseline', 'typescript'], inputs, out/'raw-reference')
        candidate = load_bundle(candidate_file, catalog, catalog_hash, [case], ['candidate'], inputs, out/'raw-candidate')
        entry = candidate['points']['raytrace']['candidate']
        original = relative_path(candidate_file.parent, entry['path'])
        receipt_file = Path(str(original)+'.json')
        receipt = json.loads(receipt_file.read_text())
        require(receipt['complete'] and receipt['observation']['checked'], 'Unchecked candidate emission')
        require(receipt['input']['sha256'] == case['source']['sha256'] and receipt['output']['sha256'] == identity(original)['sha256'], 'Receipt/module/source mismatch')
        inputs.append(identity(receipt_file))
        shutil.copyfile(receipt_file, out/'consumed/candidate-checked-emission.json')
        baseline_text = Path(reference['points']['raytrace']['baseline']['resolved']).read_text()
        definitions = dict(re.findall(r'^G\["([^"\\]+)"\]=(.*);$', baseline_text, re.M))
        dependencies = set()
        def visit(name):
            if name in dependencies:
                return
            dependencies.add(name)
            if name not in definitions:
                require(name == 'F32.to_u32', 'Unknown runtime dependency '+name)
                return
            for child in re.findall(r'get\(G,"([^"\\]+)"\)', definitions[name]):
                visit(child)
        visit('colf')
        report['dependencies'] = sorted(dependencies)
        suffix = """
let $colEntries=0;
export function colfEntryCount(){return $colEntries;}
export function colfCandidatePoint(depth,seed,width=0){return call(get(G,'colf'),[BigInt(depth),seed>>>0,0,width>>>0,40,32]);}
"""
        for role, bundle, variant in [('baseline', reference, 'original'), ('baseline', reference, 'baseline'), ('candidate', candidate, 'partial')]:
            source_file = Path(bundle['points']['raytrace'][role]['resolved'])
            text = source_file.read_text()
            if role == 'candidate':
                lines = text.splitlines(keepends=True)
                targets = [i for i, line in enumerate(lines) if line.startswith('G["colf"]=')]
                require(len(targets) == 1, 'One colf assignment required')
                at = targets[0]
                require(lines[at].count('/* private scalar tree */') == 1, 'Actual colf tree admission required')
                lines[at] = lines[at].replace('/* private scalar tree */', '/* private scalar tree */$colEntries++;', 1)
                text = ''.join(lines)
            output = out/(variant+'.mjs')
            output.write_text(text+suffix)
            report['modules'].append(dict(role=role, variant=variant, original=identity(source_file), output=identity(output), sha256=identity(output)['sha256']))
        controls = controls_file.read_text()
        require(controls.count('/* private partial colf prototype */') == 1, 'One structural assertion expected')
        controls = controls.replace('/* private partial colf prototype */', '/* private scalar tree */')
        controls = controls.replace('phase35-private-partial-colf-prototype', 'phase35-checked-partial-colf-cohort')
        controls = controls.replace('phase35-private-partial-colf-controls', 'phase35-checked-partial-colf-controls')
        (out/'controls.mjs').write_text(controls)
        report['controls'] = identity(out/'controls.mjs')
        report['controlAdaptation'] = 'Only provenance labels and non-vacuity marker changed. Counter is inserted in actual colf fast tree branch, not source program behavior.'
        for row in inputs:
            verify(row['path'], row)
        report['complete'] = True
    except Exception as error:
        report['error'] = repr(error)
        raise
    finally:
        save(out/'derive.json', report)
    print(json.dumps(dict(complete=True, cohort=str(out), controls=str(out/'controls.mjs'), dependencies=report['dependencies'])))


if __name__ == '__main__':
    main()
