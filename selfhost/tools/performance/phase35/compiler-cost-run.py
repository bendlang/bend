#!/usr/bin/env python3
"""Serial fresh-process normal-library measurements; maintained worker unchanged."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import sys
import time
HERE=Path(__file__).resolve().parent;PROGRAMS=HERE.parent/'programs'
sys.path.insert(0,str(PROGRAMS))
from support import ExecutionGuard,save
ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('config',type=Path);ap.add_argument('out',type=Path)
a=ap.parse_args();config_file=a.config.resolve();out=a.out.resolve();config=json.loads(config_file.read_text())
assert config['kind']=='phase35-normal-checked-library-cost-plan' and config['complete']
assert config['cpu']=='3' and config['samples']==3 and config['timeoutMs']==180000
assert config['heapMiB']==1024 and config['rssMiB']==config['availableMiB']==2048
assert config['order']==['typescript','baseline','candidate']
assert config['worker']['sha256']=='f0dea569bdb02df60ed1156b0cead389e197291f1c3a3c6775102c7a03790f42'
def identity(file):
 file=Path(file).resolve();h=hashlib.sha256()
 with file.open('rb') as stream:
  for chunk in iter(lambda:stream.read(2**20),b''):h.update(chunk)
 return dict(file=str(file),canonicalPath=str(file),sha256=h.hexdigest())
inputs=[*config['inputs'],identity(config_file),identity(__file__)]
def verify():
 for i in inputs:assert identity(i['file'])==i,i['file']
verify();out.mkdir(parents=True,exist_ok=False);(out/'consumed-run.py').write_bytes(Path(__file__).read_bytes())
report=dict(kind='phase35-normal-checked-library-cost',complete=False,pass_=False,inputs=inputs,config=identity(config_file),scope=config['scope'],rows=[],statistics={})
report['pass']=report.pop('pass_');save(out/'report.json',report);started=time.monotonic()
try:
 with ExecutionGuard(rss_mib=2048,available_mib=2048) as guard:
  for case in config['cases']:
   for sample in range(3):
    order=config['order'][sample:]+config['order'][:sample]
    for role in order:
     verify();v=config['variants'][role];prefix=out/(case['id']+'-'+str(sample)+'-'+role)
     request=dict(variant=role,typescript=v['typescript'],source=case['source'],expected=case['expected'][role],
        attempt=v['attempt'],api=v['api'],cache=v['cache'],verifier=v['verifier']['file'],driver=v['driver'],
        upstream=v['upstream'],inputs=inputs,output=str(prefix)+'.mjs')
     request_file=Path(str(prefix)+'.request.json');result_file=Path(str(prefix)+'.result.json');save(request_file,request)
     print(json.dumps(dict(start=case['id'],sample=sample,variant=role)),flush=True)
     execution=guard.run(['taskset','-c','3',config['node']['file'],'--stack-size=4096','--max-old-space-size=1024',config['worker']['file'],str(request_file),str(result_file)],Path(str(prefix)+'-process'),time.monotonic()+180)
     observation=json.loads(result_file.read_text()) if result_file.exists() else None
     row=dict(source=case['id'],sample=sample,variant=role,execution=execution,observation=observation)
     report['rows'].append(row);save(out/'report.json',report)
     assert execution['complete'],'Compilation failed or hit process resource bound'
     assert observation['complete'] and observation['pass'] and not observation.get('error')
     assert observation['affinity'].split(':',1)[1].strip()=='3'
     assert observation['output']['sha256']==case['expected'][role]['sha256']
     assert identity(observation['output']['file'])=={k:v for k,v in observation['output'].items() if k!='bytes'}
     verify();print(json.dumps(dict(case=case['id'],sample=sample,variant=role,requestMs=observation['requestMs'],hostImportMs=observation['hostImportMs'],processMs=execution['wallSeconds']*1000,peakTreeRssBytes=execution['peakTreeRssBytes'])),flush=True)
  def stats(values):return dict(median=statistics.median(values),min=min(values),max=max(values),samples=values)
  for case in config['cases']:
   report['statistics'][case['id']]={}
   for role in config['order']:
    rows=[r for r in report['rows'] if r['source']==case['id'] and r['variant']==role];assert len(rows)==3
    values={key:stats([r['observation'][key] for r in rows]) for key in ['requestMs','hostImportMs','importAndRequestMs','maxRssKiB']}
    values.update(processWallMs=stats([r['execution']['wallSeconds']*1000 for r in rows]),peakTreeRssBytes=stats([r['execution']['peakTreeRssBytes'] for r in rows]),outputBytes=stats([r['observation']['output']['bytes'] for r in rows]))
    report['statistics'][case['id']][role]=values
  verify();report['complete']=report['pass']=True
except Exception as error:
 report['error']=repr(error);raise
finally:
 report['wallSeconds']=time.monotonic()-started;save(out/'report.json',report)
print(json.dumps(dict(complete=True,rows=len(report['rows']),report=str(out/'report.json'))))
