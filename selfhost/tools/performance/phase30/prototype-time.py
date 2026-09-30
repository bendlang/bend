#!/usr/bin/env python3
"""Record end-to-end timing-launcher receipt around the maintained paired harness."""
from pathlib import Path
import hashlib,json,subprocess,sys,time
HERE=Path(__file__).resolve().parent
config,out=map(lambda x:Path(x).resolve(),sys.argv[1:])
prefix=out.parent/(out.name+'-launcher')
for suffix in ['.json','.stdout','.stderr']:assert not Path(str(prefix)+suffix).exists()
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
command=[sys.executable,str(HERE.parent/'phase29/compare.py'),str(config),str(out)]
report={'kind':'phase30-clean-comparison-launcher','complete':False,'command':command,'inputs':[ident(p) for p in [Path(__file__),config,HERE.parent/'phase29/compare.py']]}
def save():Path(str(prefix)+'.json').write_text(json.dumps(report,indent=2)+'\n')
save();begin=time.monotonic()
with Path(str(prefix)+'.stdout').open('w') as stdout,Path(str(prefix)+'.stderr').open('w') as stderr:
    try:report['exitCode']=subprocess.run(command,stdout=stdout,stderr=stderr,timeout=600).returncode
    except subprocess.TimeoutExpired:report['timeout']=True
report['wallSeconds']=time.monotonic()-begin
report['stdout']=ident(Path(str(prefix)+'.stdout'));report['stderr']=ident(Path(str(prefix)+'.stderr'))
if (out/'report.json').exists():
    report['comparison']=ident(out/'report.json');summary=json.loads((out/'report.json').read_text());report['complete']=report.get('exitCode')==0 and summary.get('allCasesMeasured',False)
for p in report['inputs']:assert ident(Path(p['file']))==p
save();print(json.dumps(report));raise SystemExit(0 if report['complete'] else 1)
