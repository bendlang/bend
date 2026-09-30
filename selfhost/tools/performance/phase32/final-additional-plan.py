#!/usr/bin/env python3
"""Freeze unchanged worker-admission/component/HVM gates for a final image."""
from pathlib import Path
import hashlib,json,shutil,sys

ROOT=Path(__file__).resolve().parents[4]
attempt,out=(Path(x).resolve() for x in sys.argv[1:])
m=json.loads((attempt/'attempt.json').read_text())
assert m['checked'] and m['config']['strictExact']
out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=Path(p).resolve();raw=p.read_bytes()
 return dict(file=str(p),sha256=hashlib.sha256(raw).hexdigest(),bytes=len(raw))
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
old=ROOT/'selfhost/build/phase30/final-integration-plan-17/plan.json'
prior=json.loads(old.read_text());selected={c['name']:c for c in prior['commands'] if c['name'] in ['worker-admission','component-and-hvm']}
assert set(selected)=={'worker-admission','component-and-hvm'}
bindings={k:m[k]['file'] for k in ['api','runtime','base']}
bindings['driver']=str(Path(m['snapshot']['root'])/'tools/typed-driver.mjs')
save(out/'worker-config.json',bindings)
worker=list(selected['worker-admission']['command'])
assert worker[:3]==['taskset','-c','7']
worker[-2:]=[str(out/'worker-config.json'),str(out/'worker-admission')]
component=list(selected['component-and-hvm']['command'])
component[-3:]=[str(attempt),str(out/'component'),str(out/'hvm')]
inputs=[ident(p) for p in [Path(__file__),ROOT/'design/phase32/final-integration.md',
 old,attempt/'attempt.json',*bindings.values(),worker[3],worker[6],component[1],
 ROOT/'selfhost/build/phase30/worker-admission-plan-07/plan.json',
 ROOT/'selfhost/tools/performance/phase27/component-membership.bend',
 ROOT/'selfhost/tools/performance/phase27/component-membership-oracle.mjs',
 ROOT/'selfhost/tools/performance/phase28/corpus/app-pure-hvm5-mini.bend',
 ROOT/'selfhost/build/phase28/application-timing-config.json']]
for source in [Path(worker[6]),Path(component[1])]:shutil.copyfile(source,out/('consumed-'+source.name))
commands=[dict(name='worker-admission',command=worker,cpu=7,outerTimeoutSeconds=120,executed=False),
          dict(name='component-and-hvm',command=component,cpu=7,outerTimeoutSeconds=300,executed=False)]
for row in inputs:assert ident(row['file'])==row
save(out/'plan.json',dict(kind='phase32-additional-final-controls-plan',complete=True,executed=False,
 inputs=inputs,attempt=ident(attempt/'attempt.json'),commands=commands,
 scope='Retained controls/oracles/tools unchanged; only final API/runtime/Base/driver and output directories rebound. No timing.'))
shutil.copyfile(Path(__file__),out/'consumed-plan.py')
print(json.dumps(dict(complete=True,executed=False,out=str(out))))
