#!/usr/bin/env python3
"""Close final owned parser gates on one exact checked-derived compiler image."""
from pathlib import Path
import json, hashlib
R = Path(__file__).resolve().parents[4]
S = 'selfhost/build/phase22/context-source-17'
B = 'selfhost/build/phase22/context-build-16'
API = 'ade8ef020e439b81ecb53057b33a473c34a3cbd993b98a044121ecc3c2b8c9c3'
def read(p): return json.loads((R / p).read_text())
def identity(p):
    p = R / p
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
def gate(name, count):
    path = 'selfhost/build/phase22/' + name
    r = read(path + '/report.json'); p = read(path + '/selected/paired.json')
    assert r['complete'] and r['exactAgreement'] and r['selected']['exactDifferences'] == 0
    assert r['api']['sha256'] == API and len(p['rows']) == count and not p['missing']
    assert all(x['exactAgreement'] for x in p['rows'])
    return {'report': identity(path + '/report.json'), 'paired': identity(path + '/selected/paired.json'), 'observations': count, 'exact': count, 'rawPass': r['pass'], 'rawSelectedComplete': r['selected']['selectedComplete'], 'referenceStatuses': r['selected']['reference']['statuses'], 'candidateStatuses': r['selected']['candidate']['statuses']}
a = read(B + '/attempt.json'); v = read(B + '/validation-001/report.json')
assert a['api']['sha256'] == API and a['artifactKind'] == 'derived-b1'
assert v['complete'] and v['pass'] and v['strictExact']
gates = {name: gate(name, count) for name, count in [('context-group196-05', 196), ('context-header-candidate-04', 12), ('context-normalization-candidate-03', 12)]}
delta_path = 'selfhost/build/phase22/context-group196-05/delta.json'; d = read(delta_path)
assert d['pass'] and d['candidateExact'] == 196 and not d['lost'] and not d['referenceChanged']
completion_path = 'selfhost/build/phase22/completion-beta-controls-04/report.json'; c = read(completion_path)
assert c['complete'] and c['pass'] and c['matched'] == 17 and c['api']['sha256'] == API
marked_path = 'implementation/phase22/context-controls-marked-subset-final.json'; marked = read(marked_path)
assert marked['complete'] and marked['pass'] and marked['observations'] == 114 and marked['api']['sha256'] == API
census_path = 'implementation/phase22/context-source-census-cost17.json'; census = read(census_path)
nonblank_path = 'implementation/phase22/context-source-nonblank-final.json'; nonblank = read(nonblank_path)
paths = [str(Path(__file__).relative_to(R)), S + '/manifest.json', S + '/parent.json', B + '/attempt.json', B + '/build.json', B + '/validation-001/report.json', B + '/equality/api.mjs', delta_path, completion_path, marked_path, census_path, nonblank_path, 'implementation/phase22/context-constructor-index.json', 'implementation/phase22/context-template-index.json', 'implementation/phase22/context-header-cost.json', 'selfhost/build/phase22/context-source-08/frontend-retirement-closure.json']
r = {'kind': 'phase22-final-owned-contextual-parser-correctness', 'complete': True, 'ownedCorrectnessPass': True, 'source': S + '/project', 'attempt': B, 'api': a['api'], 'checkedApi': a['checkedApi'], 'artifactKind': a['artifactKind'], 'newFixedPointClaim': False, 'ownedGates': gates, 'completion17': identity(completion_path), 'marked114Subset': identity(marked_path), 'original196Delta': {'parentExact': d['baselineExact'], 'candidateExact': d['candidateExact'], 'gained': len(d['gained']), 'lost': len(d['lost']), 'primitiveChanged': d['primitiveChanged']}, 'census': census['delta'], 'nonblankDelta': nonblank['delta'], 'totalChangedPhysicalLines': census['totalChangedPhysicalLines'], 'retiredFrontendWorkers': census['removedUnreachableFrontendWorkers'], 'retiredFrontendDefLawBlockLines': census['removedFrontendDefLawBlockLines'], 'scope': ['Exact final-image owned controls only; root full frontend, independent cohorts, histories, CLI, cost and promotion remain separate receipts.', 'Original196 and marked114 overlap; marked114 is a selection/fixture/oracle/full-reference-result subset audit, not a separate acquisition.', 'All historical expected labels and raw pass:false/selectedComplete flags remain unchanged. Healthy complete acquisition and strict paired equality are audited separately.', 'Derived equality-v5 API is not byte-identical to the upstream-checked bootstrap API and is not a new fixed-point claim.', 'All failed preparations, parser controls and rejected cost images remain preserved. No fixture-specific branch or comparator relaxation.'], 'inputs': [identity(p) for p in paths]}
out = R / 'implementation/phase22/contextual-parser-final.json'; assert not out.exists(); out.write_text(json.dumps(r, indent=2) + '\n')
md = R / 'implementation/phase22/contextual-parser-final.md'; assert not md.exists()
md.write_text('''# Final contextual parser gates

Source17/build16 closes the owned gates on derived API `'''+API+'''`:
original196, header12 and normalization12 all agree exactly with the pinned
reference; direct completion17 also passes. The unchanged marked114 observations
are an exact subset of the freshly acquired196, including all43 historical gaps.
No separate114 acquisition or disjoint total is claimed.

The original196 comparison improves Phase21's139 exact observations to196, with57
gains and no losses. Two observations of `group/body-comma` change false acceptance
to the pinned refusal; the other55 gains retain primitive outcomes. Historical
fixture labels and raw runner failures remain untouched.

The final parser has one contextual grammar, actual completed-source loader ABI2,
the existing scoped flatten owner, and ordered higher/lower materialization. The
old raw route and duplicate scope/flatten implementation are retired. Subsequent
cost corrections guard redundant declaration scans and use existing index
algorithms for template-count projection and a constructor-only scope index.

Against Phase21 the compiler modules have300 fewer physical lines and241 fewer
nonblank lines,3305 more bytes,31 more definitions,81 fewer laws and one additional
type/module. The earlier98-worker/977-block-line retirement remains explicit.
The constructor index adds one scope field and3 helpers; no term-field or cache
ABI growth is hidden in these counts.

This receipt binds owned correctness and source accounting. Root-owned full
frontend, histories, independent cohorts, CLI, measured runtime and promotion
receipts establish their own scopes. The derived API is distinct from the checked
bootstrap artifact; no new fixed point or universal-language proof is claimed.
''')
print(json.dumps({'complete': True, 'ownedCorrectnessPass': True, 'api': API, 'gates': {k:v['observations'] for k,v in gates.items()}}))
