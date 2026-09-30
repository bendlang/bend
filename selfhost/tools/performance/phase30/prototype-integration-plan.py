#!/usr/bin/env python3
"""Freeze maintained integration runners with CPU4 and explicit Phase30 labels."""
from pathlib import Path
import hashlib,json,sys
ROOT=Path(__file__).resolve().parents[4]
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
report={'kind':'phase30-maintained-integration-launcher-plan','complete':False,
 'scope':'Acquisition/validation only. Exact existing tests, oracles and limits. Changes only bind original tool root, move CPU6 children to CPU4 and update phase labels. HVM legacy comparisons remain pinned TypeScript and Phase27, not Phase29.',
 'tool':ident(Path(__file__)),'runners':{}}
for name in ['integration-corpus.py','integration-acquire.py']:
 source=ROOT/'selfhost/tools/performance/phase29'/name;text=source.read_text();changes=[]
 for old,new in [
  ('HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]','HERE=Path('+repr(str(source.parent))+');ROOT=HERE.parents[3]'),
  ("'6'","'4'"),
  ('CPU6','CPU4'),
  ('phase29-','phase30-'),
  ('checked Phase29 candidate','checked Phase30 candidate'),
 ]:
  count=text.count(old)
  if count:
   changes.append({'from':old,'to':new,'count':count});text=text.replace(old,new)
 path=out/name;path.write_text(text)
 (out/('original-'+name)).write_bytes(source.read_bytes())
 report['runners'][name]={'original':ident(source),'derived':ident(path),'transformations':changes}
(out/'consumed-plan.py').write_bytes(Path(__file__).read_bytes())
report['complete']=True;(out/'plan.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'complete':True,'out':str(out),'runners':list(report['runners'])}))
