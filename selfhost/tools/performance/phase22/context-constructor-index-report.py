#!/usr/bin/env python3
"""Bind the frozen constructor-scope implementation and independent controls."""
from pathlib import Path
import hashlib, json
R = Path(__file__).resolve().parents[4]
def read(p): return json.loads((R / p).read_text())
def ident(p):
    p = R / p
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
source = 'selfhost/build/phase22/context-source-17'
attempt = 'selfhost/build/phase22/context-build-16'
controls = 'implementation/phase22/context-controls-constructor-index.json'
review = 'implementation/phase22/constructor-index-source-review.json'
census = 'implementation/phase22/context-source-census-cost17.json'
a = read(attempt + '/attempt.json'); v = read(attempt + '/validation-001/report.json')
c = read(controls); counts = read(census)
assert v['complete'] and v['pass'] and v['strictExact']
assert c['complete'] and c['pass']
paths = [str(Path(__file__).relative_to(R)), 'design/phase22/context-constructor-index.md', 'selfhost/tools/performance/phase22/context-constructor-index-prepare.py', source + '/manifest.json', source + '/parent.json', attempt + '/attempt.json', attempt + '/validation-001/report.json', controls, review, census]
r = {'kind': 'phase22-constructor-scope-index-implementation', 'complete': True, 'selected': False, 'source': source, 'attempt': attempt, 'api': a['api'], 'change': {'scopeField': 'ctors: KDef', 'newHelpers': ['f_ctor_index', 'f_ctor_index_def', 'f_ctor_index_find'], 'parentRelativeLines': 17, 'changedScopedLookupExpressions': 5, 'retainedRawLookup': True, 'newTermFields': 0, 'cacheOrPublicAbiChange': False}, 'correctness': {'artifactKind': v['artifactKind'], 'checkedBuild': True, 'maintained36StrictExact': True, 'independentDirectControls': 42, 'independentPublicParentAndCandidateExact': 24, 'sourceReview': ident(review)}, 'netCompilerDeltaFromPhase21': counts['delta'], 'totalChangedSnapshotLines': counts['totalChangedPhysicalLines'], 'cost': 'Separate root-owned same-source gate; this report makes no measured gain or promotion claim.', 'demandScope': 'Factory eagerly visits finite declaration/child metadata once without term-type/body traversal. It does not preserve raw early exit on arbitrary poisoned metadata tails; unchanged raw lookup retains that contract. Actual factory/update/lookup payload controls passed.', 'inputs': [ident(p) for p in paths]}
out = R / 'implementation/phase22/context-constructor-index.json'; assert not out.exists(); out.write_text(json.dumps(r, indent=2) + '\n')
md = R / 'implementation/phase22/context-constructor-index.md'; assert not md.exists()
md.write_text('''# Constructor-only parser scope index

Source17/build16 adds a constructor index to the existing parser scope and routes
five prior-book checks through it. Three wrappers reuse the existing exact-name
index algorithm. Local raw-book scans and the general recursive lookup remain.
Initial construction preserves the first depth-first winner; qualified header
publication updates once, and empty or partial headers retain the identical tree.
No new KTerm field, persistent cache format or public ABI is introduced.

The genuinely checked derived-B1 workflow passed maintained36. Independent42
direct controls cover full chosen definitions, named misses, duplicates, real hash
collisions,4096-wide/512-deep forests, publication history, qualification, unchanged
pattern errors and term-payload demand. Independent24 public cases are exact on
both parent and candidate, and separate source review found no blocker.

The new factory deliberately visits all finite constructor metadata once; it does
not claim the raw lookup's early exit on arbitrary poisoned metadata tails. Term
types and bodies are not traversed. The original general lookup is unchanged.

This experiment adds17 lines,3 definitions and one scope field. Against Phase21,
the complete candidate has300 fewer compiler-module lines,3305 more bytes,31 more
definitions,81 fewer laws and one additional type/module. Total changed snapshot
lines are293 fewer, including host changes. This counts the index concept honestly;
the larger simplification is retirement of the duplicate parser route.

All identities and independent evidence are bound in the adjacent JSON. Runtime,
broad final integration and promotion remain separate root-owned gates; this
implementation report alone makes no speed or installation claim.
''')
print(out)
