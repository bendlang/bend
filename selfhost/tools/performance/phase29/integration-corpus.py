#!/usr/bin/env python3
"""Run the existing checked 23-library regression, frozen and relocated to CPU6.

No test/oracle/timeout changes. Original and derived launcher bytes are retained.
All wall times are descriptive validation costs, not performance comparisons.
"""
from pathlib import Path
import hashlib,json,subprocess,sys,time
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
attempt,baseline,out=[Path(p).resolve() for p in sys.argv[1:]]
launcher=out.with_name(out.name+'-launcher');launcher.mkdir(parents=True,exist_ok=False)
sourceCorpus=HERE.parent/'phase26/corpus.py';sourceCampaign=HERE.parent/'phase25/campaign.py'
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
sources=[sourceCorpus,sourceCampaign,HERE.parent/'phase26/emit.mjs',HERE.parent/'phase25/execute.mjs',Path(__file__)]
inputs=[ident(p) for p in sources]
for p in sources:
    prefix=p.parent.name+'-'
    (launcher/(prefix+p.name)).write_bytes(p.read_bytes())
corpus=sourceCorpus.read_text();campaign=sourceCampaign.read_text()
changes=[]
def replace_once(text,before,after,label):
    assert text.count(before)==1,(label,text.count(before))
    changes.append({'scope':label,'before':before,'after':after})
    return text.replace(before,after)
corpus=replace_once(corpus,'TOOLS=Path(__file__).resolve().parent','TOOLS=Path('+repr(str(sourceCorpus.parent))+')','corpus original tool root')
corpus=replace_once(corpus,"sys.path.insert(0,str(TOOLS.parent/'phase25'))",'sys.path.insert(0,'+repr(str(launcher))+')','corpus frozen campaign import')
campaign=replace_once(campaign,'ROOT=Path(__file__).resolve().parents[4]','ROOT=Path('+repr(str(ROOT))+')','campaign original project root')
campaign=replace_once(campaign,"SH=ROOT/'selfhost'; TOOLS=Path(__file__).resolve().parent","SH=ROOT/'selfhost'; TOOLS=Path("+repr(str(sourceCampaign.parent))+')','campaign original tool root')
campaign=replace_once(campaign,"command=['taskset','-c','3',str(NODE),*FLAGS,*map(str,args)]","command=['taskset','-c','6',str(NODE),*FLAGS,*map(str,args)]",'only resource change: child CPU')
(launcher/'corpus.py').write_text(corpus);(launcher/'campaign.py').write_text(campaign)
receipt={'kind':'phase29-frozen-integration-corpus-launcher','complete':False,'scope':'Existing corpus/oracles unchanged; only CPU3 to CPU6 and path bindings change.','inputs':inputs,'transformations':changes,'derived':[ident(launcher/'corpus.py'),ident(launcher/'campaign.py')],'attempt':ident(attempt/'attempt.json'),'baseline':ident(baseline/'manifest.json')}
command=[sys.executable,str(launcher/'corpus.py'),str(attempt),str(baseline),str(out)]
receipt['command']=command
(launcher/'derivation.json').write_text(json.dumps(receipt,indent=2)+'\n')
begin=time.monotonic()
with (launcher/'stdout.log').open('w') as stdout,(launcher/'stderr.log').open('w') as stderr:
    process=subprocess.run(command,cwd=ROOT,stdout=stdout,stderr=stderr)
receipt['exitCode']=process.returncode;receipt['validationWallSeconds']=time.monotonic()-begin
for entry in inputs:assert ident(Path(entry['file']))==entry,entry['file']
for entry in receipt['derived']:assert ident(Path(entry['file']))==entry,entry['file']
receipt['complete']=process.returncode==0 and json.loads((out/'report.json').read_text()).get('complete',False)
receipt['stdout']=ident(launcher/'stdout.log');receipt['stderr']=ident(launcher/'stderr.log')
(launcher/'derivation.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps({'complete':receipt['complete'],'exitCode':process.returncode,'validationWallSeconds':receipt['validationWallSeconds']}))
if not receipt['complete']:sys.exit(1)
