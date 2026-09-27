#!/usr/bin/env python3
"""Cross-check recorded results and immutable artifacts; does not rerun timing."""
import hashlib
import json
from pathlib import Path
import sys

raw = Path(sys.argv[1]).resolve()
rows = []


def check(name, result):
    rows.append({'name': name, 'pass': bool(result)})


def read(name):
    return json.loads((raw / name).read_text())


def sha(name):
    return hashlib.sha256((raw / name).read_bytes()).hexdigest()


check('production identity', read('baseline/unchanged-final.json')['pass'])
check('release integrity', read('baseline/release-verification-final.json')['value']['exit_code'] == 0)
check('A01 genuine checked B1', read('checked-attempt-01/attempt.json')['artifactKind'] == 'checked-b1')
control = read('checked-controls-01/report.json')
check('A01 148 controls', control['pass'] and control['checks'] == 148)
check('A01 frozen checked artifact', sha('checked-attempt-01/api.mjs') ==
      '5efa1b35c7b3585731fc0937fcb26e3a50a1af3ffcb983bd52a83cdeaebf245b')
timing = read('checked-measure-01/report.json')
check('A01 eight passing timing workers', timing['pass'] and len(timing['workers']) == 8
      and all(w['status'] == 0 for w in timing['workers']))
check('A03 checked component', read('binding-build-01/build.json')['pass'])
control = read('binding-controls-02.json')
check('A03 965 controls', control['pass'] and len(control['rows']) == 965)
check('A03 frozen component artifact', sha('binding-build-01/api.mjs') == control['apiSha256'])
timing = read('binding-measure-02/report.json')
check('A03 eight timing workers', timing['complete'] and len(timing['workers']) == 8)
check('A02 corrected component checked', read('semantic-values-07/build.json')['pass'])
control = read('semantic-values-07/controls.json')
check('A02 100 current suite controls', control['pass'] and control['total'] == control['passed'] == 100)
check('A02 harness-only final revision', sha('semantic-values-06/api.mjs') == sha('semantic-values-07/api.mjs'))
timing = read('semantic-values-bench-01/report.json')
check('A02 eight normalization workers', timing['pass'] and len(timing['workers']) == 8
      and all(w['exitCode'] == 0 for w in timing['workers']))
check('A02 timings still belong to candidate05',
      sha('semantic-values-05/api.mjs') == sha('semantic-values-bench-01/api.mjs')
      and sha('semantic-values-07/api.mjs') != sha('semantic-values-bench-01/api.mjs'))
check('A02 original stronger controls remain failed', not read('semantic-values-03/controls.json')['pass']
      and not read('semantic-values-04/controls.json')['pass'])
residual = read('semantic-values-residual-07/report.json')['rows']
domain = [r for r in residual if r['name'] == 'all-domain']
body = [r for r in residual if r['name'] == 'all-body']
check('A02 known All-domain failure remains recorded', len(domain) == 2
      and domain[0]['mode'] == 'old' and domain[0]['exitCode'] == 0
      and json.loads(domain[0]['stdout'].splitlines()[-1])['result'] is False
      and domain[1]['mode'] == 'new' and domain[1]['timedOut'])
check('A02 codomain probe remains inconclusive', len(body) == 2 and all(r['timedOut'] for r in body))
check('A02 residual uses corrected API', sha('semantic-values-residual-07/api.mjs') == sha('semantic-values-07/api.mjs'))
for group in ['checked-measure-01', 'binding-measure-02', 'semantic-values-bench-01']:
    check(f'{group} raw workers retained', len(list((raw / group).glob('*.json'))) >= 8)
result = {'pass': all(row['pass'] for row in rows), 'checks': rows,
          'scope': 'Preservation/result identity audit only; A02 residual demand failures remain failures.'}
(raw / 'cross-experiment-audit.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result))
sys.exit(0 if result['pass'] else 1)
