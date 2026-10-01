#!/usr/bin/env python3
"""Freeze an explicit owner-only retry; preserve prior successes and failed evidence."""
import argparse
import copy
import hashlib
import json
from pathlib import Path

ap=argparse.ArgumentParser(description=__doc__)
ap.add_argument('plan_directory',type=Path)
ap.add_argument('new_retry',type=Path)
ap.add_argument('--launch',type=Path,required=True,help='Failed serial-launcher report.json')
ap.add_argument('--start',required=True,help='Exact first failed owner command')
ap.add_argument('--reroute',type=Path,required=True,help='Failed output directory; retry gets NEW_RETRY/retry-output')
ap.add_argument('--report',action='append',default=[],help='Explicit GROUP=EXISTING_REPORT metadata repair; assertions remain unchanged')
a=ap.parse_args();base=a.plan_directory.resolve();out=a.new_retry.resolve()
planfile=base/'plan.json';launchfile=a.launch.resolve();failed=a.reroute.resolve()
assert not out.exists(),'Retry plan directory must be new'
def identity(file):
 file=Path(file).resolve();h=hashlib.sha256()
 with file.open('rb') as stream:
  for chunk in iter(lambda:stream.read(2**20),b''):h.update(chunk)
 return dict(file=str(file),sha256=h.hexdigest(),bytes=file.stat().st_size)
def save(file,data):file.write_text(json.dumps(data,indent=2)+'\n')
def verify(row):
 actual=identity(row.get('file',row.get('path')))
 assert actual['sha256']==row['sha256'],actual['file']
 if 'bytes' in row:assert actual['bytes']==row['bytes'],actual['file']
 return actual
plan=json.loads(planfile.read_text());launch=json.loads(launchfile.read_text())
assert plan['kind']=='phase35-final-integration-plan' and plan['complete'] and not plan['executed']
assert launch['kind']=='phase35-serial-final-gate-launch' and not launch['complete']
assert launch['stage'] in ['owner','preinstall'] and verify(launch['plan'])==identity(planfile)
for row in plan['inputs']:verify(row)
owners=[row for row in plan['commands'] if row['stage']=='owner']
names=[row['name'] for row in owners];assert names.count(a.start)==1
start=names.index(a.start);steps=launch['steps'];assert steps
assert steps[-1]['name']==a.start and not steps[-1]['complete'] and steps[-1]['returncode']!=0
assert all(s['complete'] and s['returncode']==0 for s in steps[:-1])
executed=[s['name'] for s in steps]
assert executed==names[start-len(steps)+1:start+1],'Launcher is not an exact owner prefix ending at failure'
assert failed.is_dir() and str(failed) in owners[start]['command'],'Failed directory must be an exact command argument'
close=next(row for row in owners if row['name']=='owner-close')
configfile=Path(close['command'][-2]);config=json.loads(configfile.read_text())
assert config['attempt']['sha256']==plan['attempt']['sha256'] and config['api']['sha256']==plan['api']['sha256']
assert sorted(config['cases'])==sorted(plan['ownerGates'])
repairs=[]
for arg in a.report:
 name,value=arg.split('=',1);file=Path(value).resolve();assert name in config['cases']
 doc=json.loads(file.read_text());assert doc['complete'] and doc['pass'] and not doc.get('error')
 repairs.append(dict(group=name,previous=config['cases'][name],replacement=[str(file)],receipt=identity(file)))
 config['cases'][name]=[str(file)]
out.mkdir(parents=True);newfailed=out/'retry-output';newconfig=out/'reports.json';newaggregate=out/'owner-report.json'
def move(value):
 if isinstance(value,str):
  if value==str(failed):return str(newfailed)
  if value.startswith(str(failed)+'/'):return str(newfailed)+value[len(str(failed)):]
  return value
 if isinstance(value,list):return [move(x) for x in value]
 if isinstance(value,dict):return {k:move(v) for k,v in value.items()}
 return value
config=move(config);save(newconfig,config)
selected=[]
for original in owners[start:]:
 row=move(copy.deepcopy(original))
 # Every resumed supervisor writes a fresh receipt even if its previous child
 # failed before creating the semantic output. Keep executable/tool arguments.
 if not row['selfSupervised']:
  command=row['supervisedCommand'];marker=command.index('--');oldreceipt=command[marker-1]
  assert Path(oldreceipt).name=='run-'+row['name']
  command[marker-1]=str(out/('run-'+row['name']))
 if row['name']=='owner-close':
  previous=[str(planfile),str(configfile),str(Path(close['command'][-1]))]
  replacements=[str(out/'plan.json'),str(newconfig),str(newaggregate)]
  for key in ['command','supervisedCommand']:
   row[key]=[replacements[previous.index(v)] if v in previous else v for v in row[key]]
 selected.append(row)
assert selected and selected[0]['name']==a.start and selected[-1]['name']=='owner-close'
retained=[identity(p) for p in sorted(failed.rglob('*')) if p.is_file()]
assert retained,'Failure directory must retain evidence'
extra=[identity(__file__),identity(planfile),identity(launchfile),identity(configfile),identity(newconfig),*retained]
for step in steps:
 for key in ['stdout','stderr']:
  if key in step:extra.append(verify(step[key]))
extra += [r['receipt'] for r in repairs]
new=copy.deepcopy(plan);new['commands']=selected
new['inputs']=list({r['file']:r for r in [*plan['inputs'],*extra]}.values())
new['retry']=dict(kind='phase35-owner-retry-v1',parentPlan=identity(planfile),failedLaunch=identity(launchfile),
 start=a.start,oldOutput=str(failed),newOutput=str(newfailed),preservedFailure=retained,
 reportPointerRepairs=repairs,inheritedSuccesses=executed[:-1],
 auditPlanDirectory=plan.get('retry',{}).get('auditPlanDirectory',str(base)),ownerAggregate=str(newaggregate),
 scope='Owner commands only. Identical tools, assertions, selected API and resource limits; failed-output paths and collector bindings change explicitly.')
save(out/'plan.json',new)
(out/'consumed-retry-plan.py').write_bytes(Path(__file__).read_bytes())
print(json.dumps(dict(complete=True,executed=False,commands=len(selected),retryPlan=str(out),ownerAggregate=str(newaggregate),
 auditPlanDirectory=new['retry']['auditPlanDirectory'],resumeStage='owner')))
