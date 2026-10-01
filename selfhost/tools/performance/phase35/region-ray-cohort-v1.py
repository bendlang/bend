#!/usr/bin/env python3
"""Bind maintained checked raytrace emissions to the preserved branch controls."""
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
        raise SystemExit('usage: region-ray-cohort.py PREP_MANIFEST NEW_OUT')
    candidate_file, out = [Path(x).resolve() for x in sys.argv[1:]]
    catalog_file = PROGRAMS/'catalog.json'
    reference_file = PROGRAMS/'baseline/manifest.json'
    controls_file = HERE/'branch-controls-v2.mjs'
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
    report = dict(kind='phase35-checked-ray-region-cohort', complete=False, inputs=inputs,
                  compiler=compiler, dependencies=[], modules=[], adaptation='Only append the shared nearest-distance checksum wrapper; compiler bodies stay byte-identical.')
    save(out/'derive.json', report)
    try:
        catalog_hash = identity(catalog_file)['sha256']
        reference = load_bundle(reference_file, catalog, catalog_hash, [case], ['baseline'], inputs, out/'raw-reference')
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
            require(name in definitions, 'Unknown source dependency '+name)
            dependencies.add(name)
            for child in re.findall(r'get\(G,"([^"\\]+)"\)', definitions[name]):
                visit(child)
        visit('nearest.t')
        report['dependencies'] = sorted(dependencies)
        suffix = '''\nconst $regionBench=(count,seed)=>{let sum=0;for(let k=0;k<count;k++){const ox=((seed+k)%5)-2;const value=call(get(G,"nearest.t"),[9n,ox,0,0,0,0,1,1000000000,1000000000,false]);sum=(sum+floatBits(value))>>>0;}return sum;};
export default {...$regionExports,raytraceBench:$regionExports.bench,bench:$regionBench};
'''
        for role, bundle, variant in [('baseline', reference, 'baseline'), ('candidate', candidate, 'branch')]:
            source_file = Path(bundle['points']['raytrace'][role]['resolved'])
            text = source_file.read_text()
            require(text.count('export default ') == 1, 'One original default export required')
            output = out/(variant+'.mjs')
            output.write_text(text.replace('export default ', 'const $regionExports = ', 1)+suffix)
            report['modules'].append(dict(role=role, variant=variant, original=identity(source_file), output=identity(output)))
        controls = controls_file.read_text()
        require(controls.count('/* private Bool loop prototype */') == 1, 'One structural assertion expected')
        controls = controls.replace('/* private Bool loop prototype */', '/* private final Bool loop */').replace('phase35-final-bool-loop-controls', 'phase35-checked-final-bool-loop-controls')
        (out/'controls.mjs').write_text(controls)
        report['controls'] = identity(out/'controls.mjs')
        report['controlAdaptation'] = 'Only provenance label and non-vacuity marker changed from the preserved v2 semantic controls.'
        for row in inputs:
            require(identity(row['path']) == row, 'Input changed: '+row['path'])
        report['complete'] = True
    finally:
        save(out/'derive.json', report)
    print(json.dumps(dict(complete=True, cohort=str(out), controls=str(out/'controls.mjs'), dependencies=report['dependencies'])))


if __name__ == '__main__':
    main()
