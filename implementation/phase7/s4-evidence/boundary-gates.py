#!/usr/bin/env python3
"""Run preserved A02/B01 provenance builds and maintained boundary controls."""
from pathlib import Path
import json, os, subprocess, time, hashlib
root=Path(__file__).resolve().parents[3]
out=root/'selfhost/build/phase7/s4/boundary-gates-01'
out.mkdir()
node='/home/ai/.nvm/versions/node/v24.18.0/bin/node'
upstream=root/'selfhost/.bootstrap/upstream'
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k!='NODE_OPTIONS'}
env.update(BEND_UPSTREAM=str(upstream),BEND_BASE=str(upstream/'bend2/base.bend'))
report={'complete':False,'pass':False,'commands':[],'scope':'Correctness only; frontend conformance may run concurrently on other CPUs.'}
def save(): (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
def run(name,args):
 row={'name':name,'argv':args,'started':time.time()};report['commands'].append(row);save()
 with (out/(name+'.stdout')).open('x') as stdout, (out/(name+'.stderr')).open('x') as stderr:
  row['exitCode']=subprocess.run(args,cwd=root,env=env,stdout=stdout,stderr=stderr,timeout=300).returncode
 row['seconds']=time.time()-row['started'];save()
 assert row['exitCode']==0, name
roots=['f_load_origins','f_load_origins_for','f_loaded_origins_for','f_load_graph','f_load_graph_trace','f_load_graph_seed_trace','f_parse','f_source_parsed']
try:
 for name in ['a02','b01']:
  attempt=root/('selfhost/build/phase7/s4/attempt-'+name)
  m=json.loads((attempt/'attempt.json').read_text());b=json.loads(Path(m['bootstrapReport']['file']).read_text())
  run('provenance-build-'+name,['taskset','-c','0',node,'--stack-size=4096','--max-old-space-size=4096',str(Path(m['snapshot']['root'])/'tools/stage0-library.mjs'),b['source'],str(out/(name+'.mjs')),*roots])
 run('provenance-controls',[node,'--stack-size=4096',str(root/'selfhost/tests/provenance-consolidation.mjs'),str(out/'a02.mjs'),str(out/'b01.mjs'),str(out/'provenance.json')])
 run('diagnostic-controls',[node,'--stack-size=4096',str(root/'selfhost/tests/diagnostic-reuse.mjs'),str(root/'selfhost/build/phase7/s4/attempt-b01/api.mjs'),str(root/'selfhost/build/phase7/s4/attempt-a02/api.mjs'),str(out/'diagnostic')])
 report['complete']=report['pass']=True
except Exception as error:
 report['error']=repr(error)
save();print(json.dumps(report));raise SystemExit(0 if report['pass'] else 1)
