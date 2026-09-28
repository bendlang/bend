"""Final maintained derivation tests and historical replay; no production edits."""
import hashlib,json,os,subprocess,sys
from pathlib import Path
root=Path.cwd();run=root/'selfhost/build/phase12/final-derivation-tests-02';replay=root/'selfhost/build/phase12/final-replay-02';attempt=root/'selfhost/build/phase12/integrated-02';node=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
assert not run.exists() and not replay.exists();run.mkdir()
def ident(p):
 p=Path(p);return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
inputs=[ident(p) for p in [__file__,node,attempt/'attempt.json',attempt/'validation-001/report.json',attempt/'api.mjs',attempt/'api.mjs.bootstrap.json',root/'selfhost/tools/development/equality.mjs',root/'selfhost/tools/development/equality.test.mjs',root/'selfhost/tools/performance/phase12/call-replay.mjs']]
validation=json.loads((attempt/'validation-001/report.json').read_text());assert validation['complete'] and validation['pass'];assert validation['selected']['candidate']['statuses']['pass']==22
for name in ['equality.mjs','equality.test.mjs']:assert ident(root/'selfhost/tools/development'/name)['sha256']==ident(attempt/'snapshot/tools/development'/name)['sha256']
report={'kind':'phase12-final-derivation-gates','complete':False,'pass':False,'inputs':inputs,'steps':[],'scope':'Live maintained leaf-only v5 helper/tests against final integrated02 checked B1;16 groups plus exact current/historical replay;22focused gate precondition. No performance claim.'};out=run/'launcher.json'
def save():out.write_text(json.dumps(report,indent=2)+'\n')
def execute(label,argv,env):
 row={'label':label,'argv':list(map(str,argv)),'env':{k:v for k,v in env.items() if k.startswith('EQUALITY_TEST_')}};report['steps'].append(row);save()
 try:
  r=subprocess.run(row['argv'],env=env,cwd=root,capture_output=True,text=True,timeout=120);row.update({'returncode':r.returncode,'stdout':str(run/(label+'.stdout')),'stderr':str(run/(label+'.stderr'))});(run/(label+'.stdout')).write_text(r.stdout);(run/(label+'.stderr')).write_text(r.stderr);save();assert r.returncode==0,(label,r.returncode,r.stderr)
 except BaseException as e:row['error']=repr(e);save();raise
try:
 env={k:v for k,v in os.environ.items() if not(k.startswith('BEND_') or k in ['NODE_OPTIONS','NODE_PATH'])};env.update({'EQUALITY_TEST_API':str(attempt/'api.mjs'),'EQUALITY_TEST_BOOTSTRAP':str(attempt/'api.mjs.bootstrap.json'),'EQUALITY_TEST_REPORT':str(run/'report.json')})
 execute('tests',['taskset','-c','3',node,'--stack-size=4096','--max-old-space-size=4096','--test',root/'selfhost/tools/development/equality.test.mjs'],env)
 tests=json.loads((run/'report.json').read_text());assert tests['pass'] and len(tests['completed'])==16 and not tests['failures'];report['tests']=ident(run/'report.json')
 execute('replay',['taskset','-c','3',node,'--stack-size=4096','--max-old-space-size=4096',root/'selfhost/tools/performance/phase12/call-replay.mjs',root/'selfhost',attempt,replay],env)
 replay_report=json.loads((replay/'report.json').read_text());assert replay_report['complete'] and replay_report['pass'] and len(replay_report['checks'])==5;report['replay']=ident(replay/'report.json')
 for r in inputs:assert ident(r['file'])==r
 report.update({'complete':True,'pass':True,'inputsVerified':True})
except BaseException as e:report['error']=repr(e);raise
finally:save();print(json.dumps({'complete':report['complete'],'pass':report['pass'],'steps':len(report['steps'])}))
