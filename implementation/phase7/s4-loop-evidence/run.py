#!/usr/bin/env python3
from pathlib import Path
import datetime, hashlib, json, os, re, subprocess, time, sys, resource, signal
if len(sys.argv)>1 and sys.argv[1]=='--worker':
 request=json.loads(Path(sys.argv[2]).read_text());started=time.monotonic()
 try:
  child=subprocess.Popen(request['argv'],stdout=sys.stdout,stderr=sys.stderr,start_new_session=True)
  try:code=child.wait(timeout=request['timeout'])
  except subprocess.TimeoutExpired:os.killpg(child.pid,signal.SIGKILL);child.wait();raise
  record={'wallSeconds':time.monotonic()-started,'maxRssKiB':resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,'exitCode':code,'method':'Fresh Python worker, one process tree, Linux wait/rusage children maxRSS in KiB.'}
  Path(request['resources']).write_text(json.dumps(record)+'\n');raise SystemExit(code)
 except Exception as error:
  Path(request['resources']).write_text(json.dumps({'error':repr(error)})+'\n');raise
root=Path(__file__).resolve().parents[3];area=root/'selfhost/build/phase7/s4-loop-02';area.mkdir()
node='/home/ai/.nvm/versions/node/v24.18.0/bin/node';workflow=root/'selfhost/tools/development/workflow.mjs'
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k!='NODE_OPTIONS'}
expected={'A':('baseline-project','ba121e4098044d9f106c4e7cb3e37b0e1ce1bc77f7e42f7e5418556b7f0f3e90','7e913551460ac736f1af35e19049d712765291255a0e579482f2e7179dcadbc6'),'B':('candidate-b02-project','f201bdea7ea4041483b40704f622703945858e981c404a4d7e50979b74370110','9826ac8f2cb2ad17ab07d7a1f3fcefc701c64cd44d3c50333b3410d761d98b7f')}
report={'kind':'S4-final-development-loop-ABBA','complete':False,'pass':False,'started':datetime.datetime.now(datetime.timezone.utc).isoformat(),'rows':[],'pairs':[],'guards':{'wallRatio':1.05,'rssRatio':1.10},'scope':'Four fresh full checked/equality/focused development attempts; serial CPU0, same source functionality and21-case selection. No source-versus-TypeScript ratio.'}
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(): (area/'report.json').write_text(json.dumps(report,indent=2)+'\n')
report['runner']={'file':str(Path(__file__).resolve()),'sha256':sha(__file__)}
report['workflow']={'file':str(workflow),'sha256':sha(workflow)};save();deadline=time.monotonic()+720
try:
 for i,label in enumerate(['A','B','B','A']):
  project,checked,api=expected[label];out=area/f'{i}-{label}';out.mkdir();config={'project':str(root/'selfhost/build/phase7/s4'/project),'upstream':str(root/'selfhost/.bootstrap/upstream'),'profile':'equality','jobs':1,'cpu':'0','heapMb':4096};(out/'config.json').write_text(json.dumps(config,indent=2)+'\n')
  args=['taskset','-c','0',node,'--stack-size=4096','--max-old-space-size=4096',str(workflow),'run',str(out/'config.json'),str(out/'attempt')]
  row={'index':i,'variant':label,'argv':args,'started':datetime.datetime.now(datetime.timezone.utc).isoformat()};report['rows'].append(row);save();start=time.monotonic()
  request={'argv':args,'resources':str(out/'resources.json'),'timeout':min(180,max(1,deadline-start))};(out/'request.json').write_text(json.dumps(request,indent=2)+'\n')
  with (out/'stdout').open('x') as stdout,(out/'stderr').open('x') as stderr:row['exitCode']=subprocess.run([sys.executable,str(Path(__file__).resolve()),'--worker',str(out/'request.json')],cwd=root,env=env,stdout=stdout,stderr=stderr,timeout=request['timeout']+5).returncode
  row['wallSeconds']=time.monotonic()-start;row['resources']=json.loads((out/'resources.json').read_text());save();assert row['exitCode']==0
  row['focused']=json.loads((out/'stdout').read_text().splitlines()[-1]);assert row['focused']['complete'] and row['focused']['pass'] and row['focused']['exactDifferences']==7
  m=json.loads((out/'attempt/attempt.json').read_text());assert m['checkedApi']['sha256']==checked and m['api']['sha256']==api;assert sha(m['checkedApi']['file'])==checked and sha(m['api']['file'])==api
  row['api']=m['api'];row['checkedApi']=m['checkedApi'];row['exports']=len(re.findall(r'^  "[^"]+": run_lib',Path(m['checkedApi']['file']).read_text(),re.M));assert row['exports']==55
  row['phaseSeconds']={}
  for key,file in [('build','build.json'),('validation','validation-001/report.json')]:
   d=json.loads((out/'attempt'/file).read_text());assert d['complete'];row['phaseSeconds'][key]=(datetime.datetime.fromisoformat(d['finished'].replace('Z','+00:00'))-datetime.datetime.fromisoformat(d['started'].replace('Z','+00:00'))).total_seconds()
  row['pass']=True;save();assert time.monotonic()<deadline
 for a,b in [(0,1),(3,2)]:
  x,y=report['rows'][a],report['rows'][b];report['pairs'].append({'control':a,'candidate':b,'wallRatio':y['wallSeconds']/x['wallSeconds'],'rssRatio':y['resources']['maxRssKiB']/x['resources']['maxRssKiB']})
 assert sha(workflow)==report['workflow']['sha256'] and sha(__file__)==report['runner']['sha256']
 report['complete']=True;report['pass']=all(p['wallRatio']<=1.05 and p['rssRatio']<=1.10 for p in report['pairs'])
except Exception as error:report['error']=repr(error)
report['finished']=datetime.datetime.now(datetime.timezone.utc).isoformat();save();print(json.dumps({k:v for k,v in report.items() if k!='rows'}));raise SystemExit(0 if report['pass'] else 1)
