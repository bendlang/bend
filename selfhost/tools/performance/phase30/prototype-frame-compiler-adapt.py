#!/usr/bin/env python3
"""Bind actual12/13 emissions to the retained independent frame controls."""
from pathlib import Path
import argparse, hashlib, importlib.util, json, re, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
BUILD = ROOT / 'selfhost/build/phase30'
PARSER = HERE / 'inspect-terminal-region.py'
spec = importlib.util.spec_from_file_location('frame_compiler_parser', PARSER)
parser = importlib.util.module_from_spec(spec); spec.loader.exec_module(parser)

def ident(p):
    p = Path(p).resolve(); raw = p.read_bytes()
    return {'file': str(p), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}

def checked(p, expected):
    receipt = Path(str(p) + '.json'); data = json.loads(receipt.read_text())
    assert data['complete'] and data['observation']['checked']
    assert data['output']['sha256'] == ident(p)['sha256']
    attempt = Path(data['attempt']['file'])
    assert attempt.parent.name == expected and ident(attempt)['sha256'] == data['attempt']['sha256']
    return [ident(p), ident(receipt), ident(attempt)]

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('baseline', type=Path); ap.add_argument('candidate', type=Path); ap.add_argument('out', type=Path)
    a = ap.parse_args(); a.out = a.out.resolve(); a.out.mkdir(parents=True, exist_ok=False)
    design = ROOT / 'design/phase30/actual-frame-reuse-validation.md'
    original = BUILD / 'review-tree-frame-01'
    controls = original / 'inherited-controls.mjs'
    counts = HERE / 'review-tree-frame-counts.mjs'
    report = {'kind': 'phase30-actual-frame-reuse-validation', 'complete': False,
              'inputs': [ident(p) for p in [Path(__file__), design, PARSER, original / 'derive.json', controls, counts]]}
    try:
        report['inputs'] += checked(a.baseline, 'attempt-12') + checked(a.candidate, 'attempt-13')
        old, new = a.baseline.read_text(), a.candidate.read_text()
        proof = json.loads((original / 'derive.json').read_text())['proof']
        push = proof['push']; replacement = proof['replacementPush'].replace('$reuseFrame30', '$saved')
        assert old.count(push) == new.count(replacement) == 1
        assert old.count(proof['pop']) == new.count(proof['replacementPop']) == 1
        assert old.replace(push, '<push>').replace(proof['pop'], '<pop>') == new.replace(replacement, '<push>').replace(proof['replacementPop'], '<pop>')
        proof = {**proof, 'replacementPush': replacement, 'scope': 'Only actual checked12/13 private frame push and pop differ.'}
        report['proof'] = proof
        for name, text in [('baseline', old), ('reuse', new)]:
            (a.out / (name + '.mjs')).write_text(text)
            row = next(line for line in text.splitlines() if line.startswith('G["rcol"]='))
            fast_open = row.index('/* private scalar tree */') - 1
            fast_close = parser.close(row, fast_open)
            callback = 'function(a,$entered){'
            callback_open = row.rfind(callback, 0, fast_open) + len(callback) - 1
            callback_close = parser.close(row, callback_open)
            sentinel = row[:fast_open + 1] + 'return "fast";' + row[fast_close:fast_close + 1] + 'return "generic";' + row[callback_close:]
            (a.out / (name + '-depth-sentinel.mjs')).write_text(text.replace(row, sentinel))
        shutil.copyfile(controls, a.out / 'inherited-controls.mjs')
        count_text = counts.read_text(); assert count_text.count('$reuseFrame30') == 2
        (a.out / 'actual-counts.mjs').write_text(count_text.replace('$reuseFrame30', '$saved'))
        shutil.copyfile(Path(__file__), a.out / 'consumed-adapt.py'); shutil.copyfile(design, a.out / 'design.md')
        report['outputs'] = {name: ident(a.out / (name + '.mjs')) for name in ['baseline', 'reuse']}
        report['diagnostics'] = [ident(a.out / p) for p in ['baseline-depth-sentinel.mjs', 'reuse-depth-sentinel.mjs', 'inherited-controls.mjs', 'actual-counts.mjs']]
        (a.out / 'boundaries.json').write_text(json.dumps({'variants': {k: v['file'] for k, v in report['outputs'].items()}, 'inputs': [str(a.out / 'derive.json'), str(design)]}, indent=2) + '\n')
        report['complete'] = True
    except Exception as error:
        report['error'] = repr(error); raise
    finally:
        (a.out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'complete': True, 'out': str(a.out)}))

if __name__ == '__main__':
    main()
