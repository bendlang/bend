#!/usr/bin/env python3
"""Run one maintained primitive/Nat regression gate on a new checked attempt."""
from pathlib import Path
import hashlib,json,os,shutil,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[4];TOOLS=ROOT/'selfhost/tools/performance/phase29'
NODE=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
attempt=Path(sys.argv[1]).resolve();mode=sys.argv[2];out=Path(sys.argv[3]).resolve();out.mkdir(parents=True,exist_ok=False)
assert mode in ['primitive','worker','nested','primitive-guards','worker-guards']
def ident(p):
 p=Path(p).resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
report={'kind':'phase30-inherited-control-gate','complete':False,'pass':False,'mode':mode,
 'scope':'Existing tests/oracles unchanged; one checked Phase30 candidate versus saved pinned TypeScript and pre-worker Phase27 where applicable. CPU4 acquisition only, no comparative timing.',
 'inputs':[ident(Path(__file__)),ident(NODE),ident(attempt/'attempt.json')],'steps':[]}
shutil.copyfile(Path(__file__),out/'consumed-gate.py')
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
def keep(p):
 report['inputs'].append(ident(p));return p
def child(args,name):
 command=['taskset','-c','4',str(NODE),'--stack-size=4096','--max-old-space-size=1024',*map(str,args)]
 row={'name':name,'command':command,'complete':False};report['steps'].append(row);save(out/'report.json',report)
 begin=time.monotonic()
 with (out/(name+'.stdout')).open('w') as stdout,(out/(name+'.stderr')).open('w') as stderr:
  result=subprocess.run(command,stdout=stdout,stderr=stderr,cwd=ROOT,env=env,timeout=120)
 row.update(exitCode=result.returncode,wallSeconds=time.monotonic()-begin,stdout=ident(out/(name+'.stdout')),stderr=ident(out/(name+'.stderr')))
 row['complete']=result.returncode==0;save(out/'report.json',report)
 assert row['complete'],name+' failed; retained outputs'
try:
 if mode in ['primitive','worker','nested']:
  configPath=ROOT/('selfhost/build/phase29/controls-final-04/'+mode+'/comparison.json')
  old=json.loads(keep(configPath).read_text());sources={'primitive':'controls-primitives.bend','worker':'controls-worker.bend','nested':'controls-worker-nested.bend'}
  source=keep(TOOLS/sources[mode]);module=out/'candidate.mjs'
  emit=keep(ROOT/'selfhost/tools/performance/phase26/emit.mjs')
  child([emit,attempt,source,module],'emit')
  modules={'candidate':str(module)}
  for side in ['baseline','upstream']:
   p=Path(old['modules'][side]);receipt=p.with_suffix('.mjs.json');r=json.loads(keep(receipt).read_text())
   assert r['complete'] and r['input']['sha256']==ident(source)['sha256'] and r['output']['sha256']==ident(keep(p))['sha256']
   modules[side]=str(p)
  config=out/'comparison.json';save(config,{'modules':modules})
  name={'primitive':'controls-run.mjs','worker':'controls-worker-run.mjs','nested':'controls-worker-nested-run.mjs'}[mode]
  check=keep(TOOLS/name);shutil.copyfile(check,out/('consumed-'+name))
  child([check,config,out/'comparison'],'check')
  report['observation']=json.loads((out/'comparison/report.json').read_text());assert report['observation'].get('pass')
 else:
  manifest=json.loads((attempt/'attempt.json').read_text());config=out/'config.json'
  bindings={key:manifest[key]['file'] for key in ['api','runtime','base']}
  bindings['driver']=str(attempt/'snapshot/tools/typed-driver.mjs')
  for p in bindings.values():keep(Path(p))
  save(config,bindings)
  name='controls-guards.mjs' if mode=='primitive-guards' else 'controls-worker-frontier.mjs'
  check=keep(TOOLS/name);shutil.copyfile(check,out/('consumed-'+name))
  if mode=='worker-guards':keep(TOOLS/'controls-worker-guards.mjs')
  child([check,config,out/'comparison'],'check')
  report['observation']=json.loads((out/'comparison/report.json').read_text());assert report['observation'].get('pass')
 for row in report['inputs']:assert ident(row['file'])==row
 report['complete']=True;report['pass']=True
except Exception as error:
 report['error']=repr(error)
finally:
 save(out/'report.json',report)
 print(json.dumps({'complete':report['complete'],'pass':report['pass'],'mode':mode,'error':report.get('error')}))
sys.exit(0 if report['pass'] else 1)
