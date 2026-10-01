#!/usr/bin/env python3
"""Freeze normal checked-library cost inputs; run only read-only attempt verification."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys
import time

HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];PROGRAMS=HERE.parent/'programs'
sys.path.insert(0,str(PROGRAMS))
from support import ExecutionGuard,identity,save
from run import load_bundle,relative_path,require
ap=argparse.ArgumentParser(description=__doc__)
ap.add_argument('attempt',type=Path);ap.add_argument('candidate_preparation',type=Path);ap.add_argument('out',type=Path)
ap.add_argument('--baseline-preparation',type=Path,required=True)
ap.add_argument('--baseline-attempt',type=Path,required=True)
ap.add_argument('--typescript-preparation',type=Path)
ap.add_argument('--cases',default='local-pair,mandelbrot,symreg,raytrace')
a=ap.parse_args();attempt=a.attempt.resolve();candidate=a.candidate_preparation.resolve();out=a.out.resolve()
assert not out.exists();out.mkdir(parents=True);(out/'consumed').mkdir()
node=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node');baseline=a.baseline_attempt.resolve()
worker=HERE.parent/'phase30/library-cost-worker.mjs'
assert hashlib.sha256(worker.read_bytes()).hexdigest()=='f0dea569bdb02df60ed1156b0cead389e197291f1c3a3c6775102c7a03790f42'
shutil.copyfile(worker,out/'worker.mjs')
def old_identity(file):
 file=Path(file).resolve();h=hashlib.sha256()
 with file.open('rb') as stream:
  for part in iter(lambda:stream.read(2**20),b''):h.update(part)
 return dict(file=str(file),canonicalPath=str(file.resolve()),sha256=h.hexdigest())
tracked=[];catalogfile=PROGRAMS/'catalog.json';catalog=json.loads(catalogfile.read_text());ids=a.cases.split(',')
assert ids and len(set(ids))==len(ids) and set(ids)<=set(['local-pair','mandelbrot','symreg','raytrace'])
cases=[next(c for c in catalog['cases'] if c['id']==name) for name in ids]
report=dict(kind='phase36-normal-library-cost-preparation',complete=False,executed=False,cases=ids,inputs=[],bindings=[])
save(out/'preparation.json',report)
try:
 with ExecutionGuard(rss_mib=2048,available_mib=2048) as guard:
  bindings={}
  for role,image in [('baseline',baseline),('candidate',attempt)]:
   target=out/(role+'-bindings.json')
   proc=guard.run(['taskset','-c','3',str(node),'--stack-size=4096','--max-old-space-size=1024',str(HERE.parent/'phase35/compiler-cost-bindings.mjs'),str(image),str(target)],out/('verify-'+role),time.monotonic()+120)
   report['bindings'].append(dict(role=role,process=proc));save(out/'preparation.json',report)
   require(proc['complete'],'Attempt/cache verification failed: '+role)
   bindings[role]=json.loads(target.read_text());require(bindings[role]['complete'],'Incomplete binding')
  bindings['typescript']={**bindings['baseline'],'cache':None}
  for role,v in bindings.items():v['typescript']=role=='typescript'
  require(bindings['baseline']['base']['sha256']==bindings['candidate']['base']['sha256'],'Different Base sources')
  require(bindings['baseline']['upstream']==bindings['candidate']['upstream'],'Different upstream checkouts')
  reference=PROGRAMS/'baseline/manifest.json'
  sources={'candidate':candidate,'baseline':a.baseline_preparation.resolve() if a.baseline_preparation else reference,
           'typescript':a.typescript_preparation.resolve() if a.typescript_preparation else reference}
  bundles={};by_source={}
  for role,file in sources.items():
   key=str(file)
   if key not in by_source:
    roles=list(json.loads(file.read_text())['roles'])
    require(set(roles)<=set(['baseline','typescript','candidate']),'Unexpected prepared roles')
    by_source[key]=load_bundle(file,catalog,identity(catalogfile)['sha256'],cases,roles,tracked,out/('bundle-'+role))
   bundles[role]=by_source[key]
   compiler=json.loads(file.read_text())['roles'][role]['compiler']
   require(compiler['upstreamCommit']==catalog['upstreamCommit'],'Wrong upstream pin')
   if role!='typescript':
    for k in ['api','runtime','base','driver']:
     require(compiler[k]['sha256']==bindings[role][k]['sha256'],'Wrong '+role+' '+k+' identity')
  output_cases=[]
  for case in cases:
   source=(PROGRAMS/case['source']['path']).resolve();require(identity(source)['sha256']==case['source']['sha256'],'Changed source')
   expected={};receipts={}
   for role,bundle in bundles.items():
    entry=bundle['points'][case['id']][role];module=Path(entry['resolved']);expected[role]=old_identity(module)
    # New prepare.py receipts differ from the historical Phase26 format. Bind
    # their checked observation, source, output, final API and attempt explicitly.
    manifest=json.loads(sources[role].read_text())
    if 'archive' not in manifest:
     original=relative_path(sources[role].parent,entry['path']);receipt_file=Path(str(original)+'.json')
     receipt=json.loads(receipt_file.read_text())
     require(receipt['complete'] and receipt['observation']['checked'],'Unchecked emission')
     require(receipt['input']['sha256']==case['source']['sha256'] and receipt['output']['sha256']==expected[role]['sha256'],'Emission identity mismatch')
     observed=receipt.get('compiler',receipt)
     if role=='typescript':
      require(observed['upstreamCommit']==catalog['upstreamCommit'],'Wrong TypeScript emission pin')
     else:
      require(receipt['attempt']['sha256']==bindings[role]['manifest']['sha256'],'Wrong emission attempt')
      require(observed['api']['sha256']==bindings[role]['api']['sha256'],'Wrong emission API')
     receipts[role]=old_identity(receipt_file);tracked.append(identity(receipt_file))
    elif role!='typescript':
     # The portable Phase34 archive attests its original checked release and
     # verifies every saved module through load_bundle; no live installed image.
     require(role=='baseline' and sources[role]==reference,'Unsupported reference compiler kind')
     receipts[role]=old_identity(reference)
    else:receipts[role]=old_identity(sources[role])
   output_cases.append(dict(id=case['id'],source=old_identity(source),expected=expected,receipts=receipts))
  files=[Path(__file__),HERE.parent/'phase35/compiler-cost-bindings.mjs',HERE.parent/'phase35/compiler-cost-run.py',worker,out/'worker.mjs',node,catalogfile,
      PROGRAMS/'run.py',PROGRAMS/'support.py',ROOT/'design/phase36/campaign.md',*sources.values(),*[Path(x['source']['file']) for x in output_cases]]
  files += [Path(x['file']) for v in bindings.values() for x in v['inputs']]
  files += [Path(x.get('path',x.get('file'))) for x in tracked]
  files += [Path(e['file']) for c in output_cases for e in c['expected'].values()]
  upstream=Path(bindings['typescript']['upstream'])/'bend2'
  files += [p for p in upstream.rglob('*') if p.is_file() and p.suffix in ['.ts','.bend','.mjs','.js']]
  inputs=[old_identity(p) for p in dict.fromkeys(files)]
  config=dict(kind='phase35-normal-checked-library-cost-plan',complete=True,cpu='3',samples=3,timeoutMs=180000,
      heapMiB=1024,rssMiB=2048,availableMiB=2048,node=old_identity(node),worker=old_identity(out/'worker.mjs'),
      variants=bindings,cases=output_cases,order=['typescript','baseline','candidate'],inputs=inputs,
      scope='Unchanged Phase30 checked-library worker. Fresh rotated3 CPU3 processes; normal inspect/Base pipeline against explicit immediately previous checked release, versus TS book_load/valid/js_lib. Exact independently acquired output required; host import/request/process boundaries separate.')
  for item in inputs:require(old_identity(item['file'])==item,'Input changed during planning')
  save(out/'config.json',config)
  for p in [Path(__file__),HERE.parent/'phase35/compiler-cost-bindings.mjs',HERE.parent/'phase35/compiler-cost-run.py',worker]:shutil.copyfile(p,out/'consumed'/p.name)
  report['inputs']=inputs;report['complete']=True
except Exception as error:
 report['error']=repr(error);raise
finally:save(out/'preparation.json',report)
print(json.dumps(dict(complete=True,executed=False,config=str(out/'config.json'),cases=ids,workerSha256=config['worker']['sha256'])))
