#!/usr/bin/env python3
"""Acquire one fresh checked tree fixture with TS and two frozen compiler images."""
from pathlib import Path
import hashlib, json, os, subprocess, sys, time
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
previous,candidate,out=(Path(x).resolve() for x in sys.argv[1:])
out.mkdir(parents=True,exist_ok=False)
NODE=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
def identity(p):
 p=Path(p).resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
source=HERE/'inspect-source-trees.bend';frozen=out/'source.bend';frozen.write_bytes(source.read_bytes())
upstream=ROOT/'selfhost/.bootstrap/upstream-phase23/bend2'
inputs=[identity(x) for x in [Path(__file__),NODE,source,HERE/'inspect-source-tree-controls.mjs',
 ROOT/'design/phase30/source-scalar-tree-controls.md',previous/'attempt.json',candidate/'attempt.json',
 HERE.parent/'phase25/emit.mjs',HERE.parent/'phase26/emit.mjs',
 *[upstream/x for x in ['base.bend','bend.ts','comp.ts']]]]
save(out/'plan.json',{'kind':'phase30-checked-source-tree-plan','complete':True,'inputs':inputs,
 'source':identity(frozen),'previous':str(previous),'candidate':str(candidate),'cpu':7,'timeoutSeconds':120,
 'scope':'Checked acquisition and controls, not timing. Source/oracle frozen before execution.'})
(out/'consumed-acquisition.py').write_bytes(Path(__file__).read_bytes())
report={'kind':'phase30-checked-source-tree-acquisition','complete':False,'pass':False,'steps':[]}
def child(name,args):
 command=['taskset','-c','7',str(NODE),'--stack-size=4096','--max-old-space-size=1024',*map(str,args)]
 row={'name':name,'command':command,'complete':False};report['steps'].append(row);save(out/'report.json',report)
 start=time.monotonic()
 with (out/(name+'.stdout')).open('w') as stdout,(out/(name+'.stderr')).open('w') as stderr:
  try:row['exitCode']=subprocess.run(command,cwd=ROOT,env=env,stdout=stdout,stderr=stderr,timeout=120).returncode
  except subprocess.TimeoutExpired:row['timeout']=True
 row.update(wallSeconds=time.monotonic()-start,stdout=identity(out/(name+'.stdout')),stderr=identity(out/(name+'.stderr')))
 row['complete']=row.get('exitCode')==0 and not row.get('timeout',False);save(out/'report.json',report)
 return row['complete']
ok=True
for side,attempt in [('typescript',None),('previous',previous),('candidate',candidate)]:
 args=([HERE.parent/'phase25/emit.mjs','upstream',frozen,out/(side+'.mjs')] if attempt is None else
       [HERE.parent/'phase26/emit.mjs',attempt,frozen,out/(side+'.mjs')])
 ok=child(side,args) and ok
if ok:ok=child('controls',[HERE/'inspect-source-tree-controls.mjs',out,out/'controls'])
for x in inputs:assert identity(x['file'])==x,x['file']
report.update({'complete':True,'pass':ok});save(out/'report.json',report)
print(json.dumps({'complete':True,'pass':ok,'out':str(out)}));raise SystemExit(0 if ok else 1)
