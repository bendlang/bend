#!/usr/bin/env python3
"""Freeze unchanged canary points against the installed Phase31 checked07."""
from pathlib import Path
import hashlib
import importlib.util
import json
import sys

ROOT = Path(__file__).resolve().parents[4]
scalar, row, out = (Path(x).resolve() for x in sys.argv[1:])
out.mkdir(parents=True, exist_ok=False)


def ident(p):
    p = Path(p).resolve()
    b = p.read_bytes()
    return dict(file=str(p), sha256=hashlib.sha256(b).hexdigest(), bytes=len(b))


def save(p, x):
    p.write_text(json.dumps(x, indent=2) + '\n')


prior = ROOT / 'selfhost/build/phase31/canary07-plan/plan.json'
baseline_attempt = ROOT / 'selfhost/build/phase31/attempt-07/attempt.json'
old = json.loads(prior.read_text())
assert old['complete']
inputs = [ident(p) for p in [__file__, prior, baseline_attempt,
          ROOT / 'design/phase32/final-integration.md']]
for p in [scalar, row]:
    receipt = json.loads(Path(str(p) + '.json').read_text())
    assert receipt['complete'] and receipt['observation']['checked']
    assert ident(p)['sha256'] == receipt['output']['sha256']
    inputs += [ident(p), ident(str(p) + '.json')]

parser = ROOT / 'selfhost/tools/performance/phase30/prototype-owned-derive.py'
spec = importlib.util.spec_from_file_location('rowwrap', parser)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
wrapped = out / 'generic-row.mjs'
wrapped.write_text(module.wrap(row.read_text(), False))
inputs += [ident(parser), ident(wrapped)]
assert [c['id'] for c in old['cases']] == [
    'scalar-region-0', 'scalar-region-8192', 'complete-generic-row32']
cases = []
for case in old['cases']:
    scalar_case = case['id'].startswith('scalar-')
    candidate = scalar if scalar_case else wrapped
    original_source = scalar if scalar_case else row
    # Baseline row is a diagnostic wrapper; its underlying receipt is in old.inputs.
    if scalar_case:
        baseline_receipt = Path(case['modules']['candidate'] + '.json')
    else:
        source_paths = [x['file'] for x in old['inputs']
                        if x['file'].endswith('/local-data-actual07-source-01/candidate.mjs.json')]
        assert len(source_paths) == 1
        baseline_receipt = Path(source_paths[0])
    before = json.loads(baseline_receipt.read_text())
    after = json.loads(Path(str(original_source) + '.json').read_text())
    assert before['attempt']['sha256'] == ident(baseline_attempt)['sha256']
    assert before['input']['sha256'] == after['input']['sha256']
    inputs.append(ident(baseline_receipt))
    cases.append(dict(id=case['id'], point=case['point'], modules=dict(
        baseline07=case['modules']['candidate'], candidate=str(candidate),
        typescript=case['modules']['typescript'])))
for case in cases:
    inputs.extend(ident(p) for p in case['modules'].values())
plan = dict(kind='phase32-unmodified-canary-points', complete=True, inputs=inputs,
            cases=cases, scope='Same scalar0/8192 and complete generic row32 points, '
            'with checked Phase31-07 baseline; source receipt identities verified. '
            'No measured result until a separate exclusive root timing grant.')
save(out / 'plan.json', plan)
for protocol in ['screen', 'confirm']:
    save(out / (protocol + '.json'), dict(protocol=protocol,
         inputs=[ident(out / 'plan.json'), *inputs], cases=cases))
(out / 'consumed-plan.py').write_bytes(Path(__file__).read_bytes())
print(json.dumps(dict(complete=True, out=str(out))))
