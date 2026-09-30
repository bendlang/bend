#!/usr/bin/env python3
"""Add one request-local V8 profile to the successful attribution worker."""
import pathlib
import hashlib
import json
import difflib
import sys

root=pathlib.Path(__file__).resolve().parents[3]
out=pathlib.Path(sys.argv[1]).resolve()
out.mkdir()
def identity(p):
    p=pathlib.Path(p).resolve(); data=p.read_bytes()
    return dict(file=str(p),sha256=hashlib.sha256(data).hexdigest(),bytes=len(data))
source_plan=root/'build/phase31/h-attribution-plan-01/plan.json'
plan=json.loads(source_plan.read_text())
source=pathlib.Path(plan['worker']['file'])
original=source.read_text(); worker=original; changes=[]
def replace(before,after):
    global worker
    assert worker.count(before)==1,(before,worker.count(before))
    worker=worker.replace(before,after);changes.append(dict(before=before,after=after,count=1))
replace("// Receipt-bound small compiler request; H is an output, never a fake attempt.","// Receipt-bound small compiler request; H is an output, never a fake attempt.\nimport inspector from 'node:inspector';")
replace("const event=(kind,data={})=>traceEvents.push({ms:performance.now(),kind,...data});", """const event=(kind,data={})=>traceEvents.push({ms:performance.now(),hrUs:Number(process.hrtime.bigint()/1000n),kind,...data});
const session=new inspector.Session();session.connect();
const post=(method,params={})=>new Promise((resolve,reject)=>session.post(method,params,(error,result)=>error?reject(error):resolve(result)));""")
replace("event('request-start',{index:i});", """if(i===1){
   await post('Profiler.enable');await post('Profiler.setSamplingInterval',{interval:1000});
   report.profileClock={beforeStartHrUs:Number(process.hrtime.bigint()/1000n)};
   await post('Profiler.start');report.profileClock.afterStartHrUs=Number(process.hrtime.bigint()/1000n);
  }
  event('request-start',{index:i});""")
replace("event('request-end',{index:i});", """event('request-end',{index:i});
  if(i===1){
   report.profileClock.beforeStopHrUs=Number(process.hrtime.bigint()/1000n);
   const {profile}=await post('Profiler.stop');report.profileClock.afterStopHrUs=Number(process.hrtime.bigint()/1000n);
   const profileFile=path.join(path.dirname(resultFile),'profile.cpuprofile');
   fs.writeFileSync(profileFile,JSON.stringify(profile)+'\\n',{flag:'wx'});report.cpuProfile=identity(profileFile);
   session.disconnect();
  }""")
(out/'original-worker.mjs').write_text(original)
(out/'worker.mjs').write_text(worker)
(out/'worker.patch').write_text(''.join(difflib.unified_diff(original.splitlines(True),worker.splitlines(True),fromfile='attribution-worker.mjs',tofile='profile-worker.mjs')))
(out/'consumed-derive.py').write_bytes(pathlib.Path(__file__).read_bytes())
plan['worker']=identity(out/'worker.mjs')
plan['profileDesign']=identity(root.parent/'design/phase31/h-checker-profile.md')
plan['profileScope']='One V8 sample profile of second H17 request, 1000 us; diagnostic only.'
plan['inputs'] += [identity(source_plan),plan['worker'],plan['profileDesign'],identity(__file__)]
(out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n')
(out/'derivation.json').write_text(json.dumps(dict(complete=True,**{'pass':True},original=identity(source),derivative=identity(out/'worker.mjs'),patch=identity(out/'worker.patch'),changes=changes),indent=2)+'\n')
print(json.dumps({'plan':str(out/'plan.json'),'replacements':len(changes)}))
