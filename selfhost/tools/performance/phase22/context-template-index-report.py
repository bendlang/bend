#!/usr/bin/env python3
"""Freeze the dx-only index experiment without attributing a speed gain."""
from pathlib import Path
import hashlib, json
R = Path(__file__).resolve().parents[4]
def read(p): return json.loads((R / p).read_text())
def ident(p):
    p = R / p
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
proof = 'selfhost/build/phase22/context-template-index-proof-01/report.json'
gate = 'implementation/phase22/context-controls-template-screen-01.json'
attempt = 'selfhost/build/phase22/context-build-14'
source = 'selfhost/build/phase22/context-source-15'
p = read(proof); g = read(gate); a = read(attempt + '/attempt.json'); v = read(attempt + '/validation-001/report.json')
assert p['complete'] and p['pass'] and len(p['primitive']) == 8
assert g['complete'] and g['pass']
assert v['complete'] and v['pass'] and v['strictExact']
paths = [str(Path(__file__).relative_to(R)), 'design/phase22/context-template-index.md', 'design/phase22/context-template-index-proof.md', 'selfhost/tools/performance/phase22/context-template-index-proof.mjs', 'selfhost/tools/performance/phase22/context-template-index-prepare.py', source + '/manifest.json', source + '/parent.json', source + '/workflow-freeze.json', attempt + '/attempt.json', attempt + '/validation-001/report.json', proof, gate]
r = {'kind': 'phase22-template-count-index-ablation', 'complete': True, 'selected': False, 'source': source, 'attempt': attempt, 'api': a['api'], 'change': 'Use the existing declaration index for the Ref call template-count projection only.', 'netDelta': read(source + '/parent.json')['delta'], 'correctness': {'artifactKind': v['artifactKind'], 'checkedBuild': True, 'maintained36StrictExact': True, 'primitiveControls': 8, 'independentPublicParentAndCandidateExact': 24, 'instrumentedProduction': [{'name': x['name'], 'counts': x['counts']} for x in p['production']]}, 'explicitCounterexample': next(x for x in p['primitive'] if x['name'] == 'negative-private-different-count-duplicates'), 'scope': 'Equality of dx under the actual contextual producer invariant, not full-definition or arbitrary prior/index equality. Instrumented probe has unchanged original API prefix but separately named modified identity. No performance or final promotion claim; constructor Bool-worker experiment is separate.', 'inputs': [ident(x) for x in paths]}
out = R / 'implementation/phase22/context-template-index.json'; assert not out.exists(); out.write_text(json.dumps(r, indent=2) + '\n')
md = R / 'implementation/phase22/context-template-index.md'; assert not md.exists()
md.write_text('''# Existing template-count index reuse

Source15/build14 changes one expression in `f_context_call_input`: a Ref call's
template count comes from the existing current declaration index. No field,
helper, line, cache or traversal is added. Family and marked-name consumers are
unchanged. Source15 starts from source13 and excludes the separate constructor
Bool-worker experiment.

The genuinely checked derived-B1 workflow and maintained36 pass. Eight direct
compiled controls establish the narrow projection and retain its limits: an
arbitrary initial duplicate prior gives linear count1 versus indexed count2;
same-count definitions and missing sentinels can be structurally unequal.
Incremental publication selects the identical new header in both routes, while
successful imported fills preserve the inherited count and invalid fills refuse.

A separately hashed appended instrumentation extension compared both counts at
15,798 actual Ref calls in the frozen compiler workload, including27 template
calls and472 missing calls, with zero mismatches. Additional template-self and
ordinary-template programs also matched; the imported-law fixture completed but
contains no call. This is diagnostic evidence, not a checked API or cost measure.

The independent unchanged template24 cohort is exact on both source13 and15,
with no primitive change, lost match or reference drift. The proof depends on the
actual contextual producer invariant; it does not license a blanket replacement
of linear lookup for malformed supplied priors. No speed gain or promotion is
claimed. Final union correctness and cost remain separate gates.
''')
print(out)
