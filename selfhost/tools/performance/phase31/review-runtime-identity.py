#!/usr/bin/env python3
"""Bind existing runtime controls to identical final snapshot bytes; run no JS."""
from pathlib import Path
import hashlib
import json
import shutil
import sys

attempt, prior_receipt, old_attempt, out = map(lambda p: Path(p).resolve(), sys.argv[1:])
out.mkdir()


def identity(path):
    path = Path(path).resolve()
    data = path.read_bytes()
    return dict(file=str(path), sha256=hashlib.sha256(data).hexdigest(), bytes=len(data))


report = dict(kind='phase31-final-runtime-test-identity-inheritance', complete=False,
              executedPrograms=False, priorPassingReceipt=identity(prior_receipt),
              tool=identity(__file__))
report['pass'] = False
shutil.copyfile(__file__, out / 'consumed-review.py')
try:
    prior = json.loads(prior_receipt.read_text())
    old = json.loads((old_attempt / 'attempt.json').read_text())
    final = json.loads((attempt / 'attempt.json').read_text())
    assert prior['complete'] and prior['pass'] and len(prior['cases']) == 55
    snapshot = Path(final['snapshot']['root'])
    fragments = []
    for name in ['core', 'base']:
        file = snapshot / ('src/runtime/js/' + name + '.mjs')
        tested = next(x for x in prior['inputs'] if x['file'].endswith('/' + name + '.mjs'))
        actual = identity(file)
        assert actual['sha256'] == tested['sha256'] and actual['bytes'] == tested['bytes']
        fragments.append(dict(name=name, tested=tested, final=actual, byteIdentical=True))
    runtime = identity(final['runtime']['file'])
    assert runtime['sha256'] == old['runtime']['sha256'] == final['runtime']['sha256']
    for fragment in fragments:
        assert Path(fragment['final']['file']).read_bytes() in Path(runtime['file']).read_bytes()
    report.update(passingCases=55, fragments=fragments,
                  attempts=[identity(p / 'attempt.json') for p in [old_attempt, attempt]],
                  bundledRuntime=runtime, packagedFragmentsPresent=True,
                  optionalExplicitFinalCommand=[
                      'python3', 'selfhost/tools/performance/phase30/run.py', '--cpu', '6',
                      '--timeout', '60', 'selfhost/build/phase31/review-local-runtime07-launch-01',
                      '--', '/home/ai/.nvm/versions/node/v24.18.0/bin/node',
                      'selfhost/tools/performance/phase31/review-local-runtime.mjs',
                      str(snapshot / 'src/runtime/js/core.mjs'),
                      str(snapshot / 'src/runtime/js/base.mjs'),
                      'selfhost/build/phase31/review-local-runtime07-01'],
                  optionalCommandExecuted=False,
                  reason='Both tested fragments exactly match final07 and occur intact in its packaged runtime. The runtime bundle is also byte-identical to actual04. Repeating these native registration/guard controls adds no new coverage.',
                  scope='Static identity binding only. Actual07 private graph execution and hostile boundaries have separate receipts; this is neither a fresh behavioral result nor a timing sample.')
    report.update(complete=True)
    report['pass'] = True
except BaseException as error:
    report['error'] = repr(error)
    raise
finally:
    (out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({k: report[k] for k in ['complete', 'pass', 'passingCases', 'executedPrograms']}))
