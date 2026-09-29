#!/usr/bin/env python3
"""Bind the closed alias-header ablation and its single-pair cost screen."""
from pathlib import Path
import json, hashlib
R = Path(__file__).resolve().parents[4]
def read(p): return json.loads((R / p).read_text())
def identity(p):
    p = R / p
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
attempt = 'selfhost/build/phase22/context-build-10'
source = 'selfhost/build/phase22/context-source-11'
screen = 'selfhost/build/phase22/context-controls-header-screen-01/report.json'
cost = 'selfhost/build/phase22/bundle-header-preflight-01/report.json'
a = read(attempt + '/attempt.json')
v = read(attempt + '/validation-001/report.json')
s = read(screen)
c = read(cost)
assert v['complete'] and v['pass'] and v['strictExact']
assert s['complete'] and s['pass'] and s['attempt']['sha256'] == identity(attempt + '/attempt.json')['sha256']
assert c['complete'] and c['mode'] == 'preflight' and c['unsafeDefinitionSetsAgree']
assert [row['variant'] for row in c['rows']] == ['typescript', 'candidate']
rows = []
for row in c['rows']:
    o = row['observation']
    assert o['pass'] and o['inputsVerified'] and row['execution']['exitCode'] == 0
    rows.append({'variant': row['variant'], 'processMs': row['execution']['wallMs'], 'requestMs': o['requestMs'], 'maxRssKiB': o['maxRssKiB']})
paths = [str(Path(__file__).relative_to(R)), 'design/phase22/context-header-cost.md', 'selfhost/tools/performance/phase22/context-header-cost-prepare.py', source + '/manifest.json', source + '/parent.json', attempt + '/attempt.json', attempt + '/validation-001/report.json', screen, cost, 'selfhost/build/phase22/bundle-matrix-inputs-03/preflight-freeze.json', 'selfhost/build/phase22/bundle-matrix-inputs-03/preflight.json', 'selfhost/build/phase22/bundle-matrix-01/report.json']
record = {'kind': 'phase22-alias-header-guard-ablation', 'complete': True, 'selected': False, 'source': source, 'attempt': attempt, 'api': a['api'], 'change': 'Guard both f_declared scans behind an actual changed alias spelling in f_def_context_header.', 'netDeltaFromParent': {'files': 1, 'lines': 0, 'definitions': 0, 'types': 0}, 'correctness': {'checkedBuild': True, 'artifactKind': v['artifactKind'], 'maintained36StrictExact': True, 'header58StrictExact': True, 'newBroader196Run': False, 'scope': 'Broad final union gates remain required; unchanged production semantics inferred only within the tested and reviewed guard contract.'}, 'cost': {'mode': 'preflight', 'rows': rows, 'fullResultEquality': True, 'unsafeSetsAgree': True, 'sameWindowBaseline': False, 'scope': 'One TS and one candidate observation; direction only relative to the separate prior matrix, no robust final ratio or promotion claim.'}, 'demandScope': 'Reduced prior-book demand on unchanged alias spelling is intentional; arbitrary poisoned or stateful JavaScript getters are not an equivalence claim.', 'inputs': [identity(p) for p in paths]}
out = R / 'implementation/phase22/context-header-cost.json'
assert not out.exists()
out.write_text(json.dumps(record, indent=2) + '\n')
md = R / 'implementation/phase22/context-header-cost.md'
assert not md.exists()
md.write_text('''# Declaration alias guard ablation

Source11/build10 guards the two recursive declaration-membership scans when an
alias spelling is unchanged. This changes one existing expression, with zero
new lines, definitions or types. The changed-alias path keeps both old calls and
their order. Reduced demand on an unused private poisoned book is intentional.

The genuinely checked derived-B1 workflow passed maintained36 strictly, and the
independent frozen header58 passed with no lost exact observations. No broader196
rerun is claimed for this isolated image; the final union must repeat its gates.

The authorized exclusive preflight used the same Phase21 compiler source and
reviewed one-driver host difference as the rejected final bundle matrix. Both
fresh-process observations passed complete result and unsafe-set equality.

| Image | Process | Request | Peak RSS |
| --- | ---: | ---: | ---: |
| TypeScript | 3.4297 s | 2.3521 s | 482,056 KiB |
| Source11 | 13.4959 s | 12.3887 s | 731,516 KiB |

The lower observation than the earlier contextual 14.7744 s is a useful direction,
not a robust ratio: this preflight has one sample per image and no contemporaneous
installed-baseline lane. It remains above the earlier installed 11.1282 s. No
promotion or overall recovery is claimed. All exact input identities and raw
reports are bound in the adjacent JSON; source10 and its failed cost screen remain.
''')
print(out)
