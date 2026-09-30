#!/usr/bin/env python3
"""Run one named frozen integration command under the shared resource guard."""
from pathlib import Path
import hashlib,json,subprocess,sys
planfile,name,out=sys.argv[1:]
planfile=Path(planfile).resolve();out=Path(out).resolve()
plan=json.loads(planfile.read_text());assert plan['complete']
for entry in plan.get('inputs',[]):
    assert hashlib.sha256(Path(entry['file']).read_bytes()).hexdigest()==entry['sha256'],entry['file']
row=next(x for x in plan['commands'] if x['name']==name)
command=row['command']
if row.get('environment'):command=['env',*[k+'='+v for k,v in row['environment'].items()],*command]
supervisor=Path(__file__).resolve().parent/'bounded-run.py'
cmd=[sys.executable,str(supervisor),'--seconds',str(row['outerTimeoutSeconds']),
     '--rss-mib','3072',str(out),'--',*command]
rc=subprocess.run(cmd).returncode
receipt=dict(plan=str(planfile),planSha256=hashlib.sha256(planfile.read_bytes()).hexdigest(),
    selection=row,producerSha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    returncode=rc,supervisedCommand=cmd)
(out/'planned-command.json').write_text(json.dumps(receipt,indent=2)+'\n')
raise SystemExit(rc)
