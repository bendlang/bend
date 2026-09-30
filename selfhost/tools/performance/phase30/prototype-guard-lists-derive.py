#!/usr/bin/env python3
"""Isolate repeated fixed-list allocation inside the complete scalar guard."""
from pathlib import Path
import argparse, hashlib, importlib.util, json, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PARSER = HERE / 'inspect-terminal-region.py'
spec = importlib.util.spec_from_file_location('guard_lists_parser', PARSER)
parser = importlib.util.module_from_spec(spec); spec.loader.exec_module(parser)

def ident(p):
    p = Path(p).resolve(); raw = p.read_bytes()
    return {'file': str(p), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}

def save(p, x):
    p.write_text(json.dumps(x, indent=2) + '\n')

def replace_once(text, old, new):
    assert text.count(old) == 1, old
    return text.replace(old, new)

def derive(text):
    for name in ['$guardPrototypes30', '$guardMarkerKeys30', '$guardMetadataKeys30']:
        assert name not in text, 'Private identifier collision: ' + name
    start = text.index('function scalarGuard(names){')
    # Parse this known function locally: the expression parser intentionally
    # does not understand arbitrary preceding runtime line comments.
    end = start + parser.close(text[start:], len('function scalarGuard(names)')) + 1
    original = text[start:end]
    changed = replace_once(original,
        'for(const p of [scalarObjectPrototype,...scalarPrimitivePrototypes]){',
        'for(const p of $guardPrototypes30){')
    changed = replace_once(changed,
        "for(const k of ['request','bounce','build','code'])",
        'for(const k of $guardMarkerKeys30)')
    assert changed.count("for(const k of ['io','typeName'])") == 2
    changed = changed.replace("for(const k of ['io','typeName'])", 'for(const k of $guardMetadataKeys30)')
    changed = replace_once(changed, "![a,c,e,b].every(d=>Object.hasOwn(d,'value'))",
        "(!Object.hasOwn(a,'value')||!Object.hasOwn(c,'value')||!Object.hasOwn(e,'value')||!Object.hasOwn(b,'value'))")
    constants = '''// Private fixed lists; every dynamic metadata check below remains live.
const $guardPrototypes30=[scalarObjectPrototype,...scalarPrimitivePrototypes];
const $guardMarkerKeys30=['request','bounce','build','code'];
const $guardMetadataKeys30=['io','typeName'];
'''
    replacement = constants + changed
    candidate = text[:start] + replacement + text[end:]
    assert candidate[:start] + original + candidate[start + len(replacement):] == text
    return candidate, {'start': start, 'end': end, 'original': original, 'replacement': replacement,
                       'exactReconstruction': True, 'metadataReadsRetainedBeforeChecks': True,
                       'captureChanged': False, 'cacheAdded': False}

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('helper', type=Path); ap.add_argument('whole', type=Path); ap.add_argument('out', type=Path)
    a = ap.parse_args(); a.out = a.out.resolve(); a.out.mkdir(parents=True, exist_ok=False)
    design = ROOT / 'design/phase30/scalar-guard-fixed-lists.md'
    report = {'kind': 'phase30-complete-guard-fixed-list-ablation', 'complete': False,
              'inputs': [ident(p) for p in [Path(__file__), PARSER, design]], 'cases': {}}
    save(a.out / 'derive.json', report)
    try:
        originals = []
        for label, file in [('helper', a.helper.resolve()), ('whole', a.whole.resolve())]:
            receipt = Path(str(file) + '.json'); d = json.loads(receipt.read_text())
            assert d['complete'] and d['observation']['checked']
            assert d['output']['sha256'] == ident(file)['sha256']
            attempt = Path(d['attempt']['file']); assert attempt.parent.name == 'attempt-14'
            for key in ['input', 'api', 'runtime', 'base', 'driver', 'attempt']:
                assert ident(d[key]['file'])['sha256'] == d[key]['sha256']
                report['inputs'].append(ident(d[key]['file']))
            report['inputs'] += [ident(file), ident(receipt)]
            folder = a.out / label; folder.mkdir()
            old = file.read_text(); new, proof = derive(old); originals.append(proof['original'])
            (folder / 'baseline.mjs').write_text(old); (folder / 'candidate.mjs').write_text(new)
            report['cases'][label] = {'baseline': ident(folder / 'baseline.mjs'), 'candidate': ident(folder / 'candidate.mjs'), 'proof': proof}
            core = attempt.parent / 'snapshot/src/runtime/js/core.mjs'
        assert originals[0] == originals[1]
        # The retained direct guard suite consumes only core.mjs. Bind the actual
        # frozen snapshot and require that it has the same exact guard body.
        core_source = core.read_text(); core_candidate, proof = derive(core_source)
        assert proof['original'] == originals[0]
        report['inputs'].append(ident(core))
        (a.out / 'core-baseline.mjs').write_text(core_source); (a.out / 'core-candidate.mjs').write_text(core_candidate)
        report['directGuardCores'] = {name: ident(a.out / ('core-' + name + '.mjs')) for name in ['baseline', 'candidate']}
        shutil.copyfile(Path(__file__), a.out / 'consumed-derive.py'); shutil.copyfile(design, a.out / 'design.md')
        report['complete'] = True
    except Exception as error:
        report['error'] = repr(error); raise
    finally:
        save(a.out / 'derive.json', report)
    print(json.dumps({'complete': True, 'out': str(a.out)}))

if __name__ == '__main__':
    main()
