#!/usr/bin/env python3
"""One unreachable registration; exact inverse diff; fixed generic-row protocol."""
from pathlib import Path
import hashlib, json, shutil, sys

ROOT = Path(__file__).resolve().parents[4]
RAW = ROOT / 'selfhost/build/phase31'
DESIGN = ROOT / 'design/phase31/generic-registration-diagnostic.md'
REVIEW = ROOT / 'selfhost/tools/performance/phase31/review-local-data.mjs'
SUFFIX = '\nexactCode(()=>null);\n'

def ident(path):
    path = Path(path).resolve()
    data = path.read_bytes()
    return dict(file=str(path), sha256=hashlib.sha256(data).hexdigest(), bytes=len(data))

def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')

mode, *args = sys.argv[1:]
if mode == 'derive':
    [out] = map(lambda p: Path(p).resolve(), args)
    out.mkdir(parents=True, exist_ok=False)
    original = RAW / 'canary07-plan/confirm.json'
    config = json.loads(original.read_text())
    case = next(c for c in config['cases'] if c['id'] == 'complete-generic-row32')
    for p in config['inputs']:
        assert ident(p['file']) == p, p['file']
    baseline = Path(case['modules']['baseline17'])
    actual = Path(case['modules']['candidate'])
    typescript = Path(case['modules']['typescript'])
    source = baseline.read_text()
    assert source.count('exactCode(') == 1
    assert actual.read_text().count('exactCode(') == 3
    assert source.count('let exactEntry=null,hasExactCodes=false;') == 1
    assert source.count('hasExactCodes=true;') == 1
    assert source.count('if(!hasExactCodes||!exactCodes.has(code)||') == 1
    assert SUFFIX not in source
    derivative = source + SUFFIX
    assert derivative[:-len(SUFFIX)].encode() == baseline.read_bytes()
    target = out / 'registered.mjs'
    target.write_text(derivative)
    variants = dict(baseline=ident(baseline), registered=ident(target),
                    actual07=ident(actual), typescript=ident(typescript))
    inputs = [ident(p) for p in [Path(__file__), DESIGN, REVIEW, original,
                                 baseline, actual, typescript]]
    manifest = dict(kind='phase31-unused-registration-diagnostic', complete=True,
        inputs=inputs, variants=variants, point=case['point'],
        insertion=SUFFIX, inverseDiff=True, registrationCalls=dict(baseline=0, registered=1, actual07=2),
        scope='Unchanged installed17 plus one unretained exactCode wrapper registration. No public body or runtime mutation.')
    save(out / 'derive.json', manifest)
    shutil.copyfile(Path(__file__), out / 'consumed-derive.py')
    shutil.copyfile(DESIGN, out / 'design.md')
    print(json.dumps(dict(complete=True, out=str(out))))
elif mode == 'plan':
    source, controls, out = map(lambda p: Path(p).resolve(), args)
    out.mkdir(parents=True, exist_ok=False)
    manifest = json.loads((source / 'derive.json').read_text())
    assert manifest['complete'] and manifest['inverseDiff']
    review = json.loads(controls.read_text())
    assert review['complete'] and review['pass']
    assert review['variants'] == ['baseline', 'registered', 'actual07']
    assert len(review['oracle']) == 99 and len(review['traces']) == 12
    for p in manifest['inputs'] + list(manifest['variants'].values()) + review['inputs']:
        assert ident(p['file']) == p, p['file']
    inputs = [ident(p) for p in [Path(__file__), DESIGN, source / 'derive.json', controls]]
    inputs += manifest['inputs'] + list(manifest['variants'].values()) + review['inputs']
    modules = {name: item['file'] for name, item in manifest['variants'].items()}
    cases = [dict(id='complete-generic-row32-registration', point=manifest['point'], modules=modules)]
    plan = dict(kind='phase31-unused-registration-timing', complete=True, inputs=inputs, cases=cases,
        scope='Only one extra unused registration; unchanged full-row oracle and long confirmation protocol.',
        criterion='Diagnostic slower with disjoint baseline ranges, >=75% of same-window07 excess, and within2% of07 or overlapping ranges.')
    save(out / 'plan.json', plan)
    save(out / 'confirm.json', dict(protocol='confirm', inputs=[ident(out / 'plan.json'), *inputs], cases=cases))
    shutil.copyfile(Path(__file__), out / 'consumed-plan.py')
    print(json.dumps(dict(complete=True, out=str(out))))
else:
    raise ValueError(mode)
