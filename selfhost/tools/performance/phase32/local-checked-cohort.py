#!/usr/bin/env python3
"""Bind checked ablations to the unchanged Phase31/TypeScript source cohort."""
from pathlib import Path
import hashlib, json, shutil, sys

ROOT = Path(__file__).resolve().parents[4]
RAW = ROOT/'selfhost/build/phase32'
out = Path(sys.argv[1]).resolve(); out.mkdir(parents=True, exist_ok=False)
def ident(p):
    p = Path(p).resolve(); b = p.read_bytes()
    return dict(file=str(p), sha256=hashlib.sha256(b).hexdigest(), bytes=len(b))
def save(p, x): p.write_text(json.dumps(x, indent=2)+'\n')
original = json.loads((RAW/'local-01/derive.json').read_text())
assert original['complete'] and original['pass']
report = dict(complete=False, inputs=[ident(__file__), ident(RAW/'local-01/derive.json')], cases={})
shutil.copyfile(__file__, out/'consumed-cohort.py')
try:
    for case in ['pair', 'fold']:
        target = out/case; target.mkdir(); variants = {}
        reference_receipt = json.loads(Path(original['cases'][case]['inputs']['receipt']).read_text())
        for role, emission in [('baseline', None), ('statements', 'emission-01'),
                ('read_fusion', 'emission-02'), ('record_vectors', 'emission-03'), ('typescript', None)]:
            dest = target/(role+'.mjs')
            if emission:
                source = RAW/emission/(case+'.mjs')
                receipt_path = Path(str(source)+'.json')
                receipt = json.loads(receipt_path.read_text())
                assert receipt['complete'] and receipt['observation']['checked']
                assert receipt['output']['sha256'] == ident(source)['sha256']
                assert receipt['input']['sha256'] == reference_receipt['input']['sha256']
                report['inputs'] += [ident(source), ident(receipt_path)]
                text = source.read_text()
                if case == 'pair':
                    assert text.count('export default ') == 1
                    text = text.replace('export default ', 'const $Pair_exports = ', 1)
                    text += '\nexport default {...$Pair_exports,bench:p=>$Pair_exports.pair(p)};\n'
                dest.write_text(text)
            else:
                entry = original['cases'][case]['variants'][role]
                assert ident(entry['file']) == entry
                report['inputs'].append(entry); shutil.copyfile(entry['file'], dest)
            variants[role] = ident(dest)
        report['cases'][case] = dict(variants=variants)
        save(target/'derive.json', dict(complete=True, variants=variants))
        if case == 'pair': shutil.copyfile(RAW/'local-01/pair/points.json', target/'points.json')
    report['complete'] = True
finally: save(out/'derive.json', report)
