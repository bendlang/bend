#!/usr/bin/env python3
"""Freeze attested-reference frontend renewal commands without running them."""
from pathlib import Path
import hashlib, json, sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
attempt,out=(Path(x).resolve() for x in sys.argv[1:])
m=json.loads((attempt/'attempt.json').read_text());assert m['checked']
out.mkdir(parents=True,exist_ok=False)
NODE=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
tool=HERE.parent/'phase23/frontend-gate-v2.mjs'
selection=ROOT/'selfhost/build/phase22/context-group196-05/selection.json'
def identity(p):
 p=Path(p).resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
inputs=[identity(x)for x in [Path(__file__),tool,NODE,attempt/'attempt.json',selection,
 ROOT/'design/phase30/frontend-renewal.md',*[m[k]['file']for k in ['api','runtime','base']]]]
commands=[]
for scope,expected in [('main',3026),('broader',196)]:
 reference=ROOT/('selfhost/build/phase23/frontend-'+scope+'-01')
 report=json.loads((reference/'report.json').read_text())
 assert report['complete'] and report['pass'] and report['healthPass'] and report['scope']==scope
 assert report['referencePin']=='018751270e800bc222a93dad7f257083ee53a5f7'
 inputs.extend(identity(x)for x in [reference/'report.json',reference/'selection.json',report['reference']['file']])
 args=[str(NODE),'--stack-size=4096','--max-old-space-size=4096',str(tool),str(attempt),str(out/scope),scope,str(reference)]
 if scope=='broader':args.append(str(selection))
 commands.append({'scope':scope,'expected':expected,'command':args,
  'environment':{'PHASE23_FRONTEND_CPU':'4,5,6,7'},'executed':False,
  'scopeNote':'Fresh candidate; exact explicitly attested reference reused with full identity checks.'})
(out/'consumed-tool.mjs').write_bytes(tool.read_bytes())
(out/'consumed-plan.py').write_bytes(Path(__file__).read_bytes())
(out/'plan.json').write_text(json.dumps({'kind':'phase30-frontend-renewal-plan','complete':True,
 'executed':False,'attempt':str(attempt),'inputs':inputs,'commands':commands,
 'runPolicy':'After final image selection and timing release. Serial main/broader;4workers on4,5,6,7; unchanged30s request and30min outer limits. Preserve shared raw failures.'},indent=2)+'\n')
print(json.dumps({'complete':True,'executed':False,'out':str(out)}))
