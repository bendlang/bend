#!/usr/bin/env python3
"""Small current/previous/17/TS cohort for later checked full-pair iterations."""
from pathlib import Path
import hashlib,json,shutil,sys
reference,previous,actual,out=map(lambda x:Path(x).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=p.resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
r=dict(kind='phase31-small-full-pair-cohort',complete=False,inputs=[ident(p)for p in[Path(__file__),reference/'derive.json',reference/'points.json',previous/'derive.json',actual,Path(str(actual)+'.json')]],variants={})
shutil.copyfile(Path(__file__),out/'consumed-bind.py');save(out/'derive.json',r)
try:
 ref=json.loads((reference/'derive.json').read_text());old=json.loads((previous/'derive.json').read_text());a=json.loads(Path(str(actual)+'.json').read_text());assert ref['complete']and old['complete']and a['complete']and a['observation']['checked'];assert a['input']['sha256']=='3987479425f7bf0d5c9e7655bb22bae29ed0d44635fdbf50eff2bb3cd869dfb4';assert a['output']['sha256']==ident(actual)['sha256']
 for name,entry in [('baseline',ref['variants']['baseline']),('previous',old['variants']['actual'])]:
  p=Path(entry['file']);assert ident(p)==entry;target=out/(name+'.mjs');shutil.copyfile(p,target);r['variants'][name]=ident(target)
 text=actual.read_text();assert text.count('export default ')==1;text=text.replace('export default ','const $Pair_exports = ',1)+'\nexport default {...$Pair_exports,bench:p=>$Pair_exports.pair(p)};\n';target=out/'actual.mjs';target.write_text(text);r['variants']['actual']=ident(target)
 entry=ref['variants']['typescript'];p=Path(entry['file']);assert ident(p)==entry;target=out/'typescript.mjs';shutil.copyfile(p,target);r['variants']['typescript']=ident(target);shutil.copyfile(reference/'points.json',out/'points.json');r['complete']=True
except Exception as e:r['error']=repr(e);raise
finally:save(out/'derive.json',r)
print(json.dumps(dict(complete=True,out=str(out))))
