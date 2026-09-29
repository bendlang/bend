from pathlib import Path
import json, hashlib
root=Path.cwd();phase=root/'selfhost/build/phase16';api='35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315'
def ident(p):
 b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
def read(p):return json.loads(p.read_text())
rows=[]
for name,n in [('checker-compact-final-backend-01',41),('checker-compact-final-execution-01',20),('checker-compact-final-growth-01',2),('checker-compact-final-literals-01',176)]:
 p=phase/name/'report.json';r=read(p);assert r['complete'] and r['pass'] and r['api']['sha256']==api;assert r['selected']['candidate']['probes']==n and r['selected']['exactDifferences']==0
 rows.append({'gate':name,'observations':n,'exact':n,'report':ident(p),'paired':r['selected']['file']})
p=phase/'checker-compact-final-instances-01/report.json';r=read(p);assert r['complete'] and r['pass'] and len(r['rows'])==29 and not r['differences'];assert any(x['sha256']==api for x in r['inputs']);rows.append({'gate':'checker-compact-final-instances-01','observations':29,'exact':29,'report':ident(p)})
report={'kind':'phase16-final-compact-same-image-gates','complete':True,'pass':True,'apiSha256':api,'attempt':ident(phase/'compact-final-build-01/attempt.json'),'cpu':1,'gates':rows,'nativeEnvironment':ident(phase/'wave6-backend-environment-01.json'),'runner':ident(root/'selfhost/tools/performance/phase16/checker-compact-final-backend.mjs'),'scope':'Backend41, literal JS/native20, parsed memo instances29, saved growth refusals2, and literal frontend176 on the same checked final image. No source changes, no compiler rebuild, no speed or full-corpus conformance inference. Root owns final full frontend, histories and controlled timing.'}
(root/'implementation/phase16/checker-compact-final-gates.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'complete':True,'pass':True,'groups':len(rows),'api':api}))
