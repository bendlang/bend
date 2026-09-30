#!/usr/bin/env python3
import sys,json,subprocess,time,hashlib,statistics,shutil
from pathlib import Path
planfile=Path(sys.argv[1]).resolve();p=json.loads(planfile.read_text());out=Path(sys.argv[2]).resolve();out.mkdir(parents=True,exist_ok=False)
report=dict(kind='phase32-checker-helper-timing-campaign',complete=False,**{'pass':False},plan=str(planfile),planSha256=hashlib.sha256(planfile.read_bytes()).hexdigest(),jobs=[])
shutil.copyfile(__file__,out/'consumed-run.py');start=time.monotonic()
try:
 for i in p['inputs']:assert hashlib.sha256(Path(i['file']).read_bytes()).hexdigest()==i['sha256']
 for trial,roles in enumerate(p['order']):
  for workload in p['workloads']:
   for role in roles:
    label=f'{trial:02}-{workload}-{role}';result=out/(label+'.json');cmd=['taskset','-c',str(p['cpu']),p['node'],*p['nodeArgs'],p['worker'],str(planfile),role,workload,str(result)]
    remaining=p['campaignTimeoutSeconds']-(time.monotonic()-start);assert remaining>0,'campaign deadline';t=time.monotonic();proc=subprocess.run(cmd,capture_output=True,timeout=min(20,remaining),text=True)
    (out/(label+'.stdout')).write_text(proc.stdout);(out/(label+'.stderr')).write_text(proc.stderr)
    j=dict(label=label,command=cmd,returncode=proc.returncode,seconds=time.monotonic()-t,result=str(result));report['jobs'].append(j)
    (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
    assert proc.returncode==0,j
    r=json.loads(result.read_text());assert r['complete'] and r['pass'];j['sha256']=hashlib.sha256(result.read_bytes()).hexdigest()
 report['summary']={}
 for workload in p['workloads']:
  rows={}
  for role in p['variants']:
   rs=[json.loads(Path(j['result']).read_text()) for j in report['jobs'] if j['label'].endswith('-'+workload+'-'+role)]
   values=[x['msPerBatch'] for r in rs for x in r['observations']];drifts=[x['halfDriftPercent'] for r in rs for x in r['observations']]
   rows[role]=dict(medianMs=statistics.median(values),rangeMs=[min(values),max(values)],halfDriftRange= [min(drifts),max(drifts)],samples=values,peakRssKb=max(r['resourceUsage']['maxRSS'] for r in rs))
  rows['baselineOverDirect']=rows['baseline']['medianMs']/rows['direct']['medianMs'];report['summary'][workload]=rows
 for i in p['inputs']:assert hashlib.sha256(Path(i['file']).read_bytes()).hexdigest()==i['sha256']
 report['complete']=True;report['pass']=True
except Exception as e:
 import traceback;report['error']=traceback.format_exc()
report['seconds']=time.monotonic()-start;(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:report[k] for k in ['complete','pass','seconds']},indent=2));sys.exit(0 if report['pass'] else 1)
