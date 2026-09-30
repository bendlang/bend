#!/usr/bin/env python3
"""Freeze all five checker ablations; serial children, bounded 512 MiB heaps."""
import argparse
import hashlib
import json
import shutil
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('derive')
parser.add_argument('controls')
parser.add_argument('out')
parser.add_argument('--cpu', type=int, default=3)
args = parser.parse_args()
root = Path.cwd()
derive = Path(args.derive).resolve()
controls = Path(args.controls).resolve()
d = json.loads(derive.read_text())
c = json.loads(controls.read_text())
assert d['complete'] and d['pass'] and c['complete'] and c['pass']
assert list(d['variants']) == ['baseline', 'direct', 'fields', 'combined', 'captured']
assert c['projectionOnlyPair']['allOtherBytesIdentical']
for role in ['captured', 'fields']:
    assert c['projectionOnlyPair'][role] == d['variants'][role]

out = Path(args.out).resolve()
out.mkdir(parents=True, exist_ok=False)
tool = root / 'selfhost/tools/performance/phase32'
node = Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')


def identity(p):
    p = Path(p).resolve()
    b = p.read_bytes()
    return dict(file=str(p), sha256=hashlib.sha256(b).hexdigest(), bytes=len(b))


for name in ['checker-timing-worker.mjs', 'checker-fixtures.mjs', 'checker-timing-run.py']:
    shutil.copyfile(tool / name, out / name)
inputs = [identity(p) for p in [
    derive, controls, __file__, out / 'checker-timing-worker.mjs',
    out / 'checker-fixtures.mjs', out / 'checker-timing-run.py',
    root / 'design/phase32/checker-matched-projections.md', node,
]] + list(d['variants'].values())
roles = list(d['variants'])
plan = dict(
    kind='phase32-checker-matched-projection-confirmation-plan',
    complete=True, executed=False, variants=d['variants'], inputs=inputs,
    cpu=args.cpu, campaignTimeoutSeconds=240, node=str(node),
    nodeArgs=['--stack-size=4096', '--max-old-space-size=512'],
    warmMs=1500, targetMs=200, samples=5,
    order=[roles[i:] + roles[:i] for i in [0, 2, 4]],
    workloads=['cached', 'uncached', 'infer_ref'],
    worker=str(out / 'checker-timing-worker.mjs'),
    scope='Private immutable finite fixtures only. All five roles; matched captured/fields '
          'differ only in eleven callback bodies. Fresh serial process per role/workload, '
          '1.5 seconds warmup, five approximately 200 ms samples, three rotated trials. '
          'Full values checked outside samples; every sample and half drift retained. '
          'No public ABI admission, compiled request, or whole-compiler speed claim.',
    resources='Exactly one timed child at once; 512 MiB V8 old-space allowance per '
              'child is not an RSS cap. Runner retains existing 20 second child timeout. '
              'Root reserves CPU and monitors host/cgroup headroom before execution.',
)
(out / 'plan.json').write_text(json.dumps(plan, indent=2) + '\n')
shutil.copyfile(__file__, out / 'consumed-plan.py')
print(out / 'plan.json')
