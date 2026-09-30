#!/usr/bin/env python3
"""Bind actual checked compiler output to the same immutable full-pair ladder."""
from pathlib import Path
import hashlib,json,shutil,sys
prior,actual,out=map(lambda x:Path(x).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
def ident(p):
 b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
r=dict(kind='phase31-full-pair-with-actual-emission',complete=False,inputs=[ident(p)for p in [Path(__file__),prior/'derive.json',prior/'points.json',actual,Path(str(actual)+'.json')]],variants={})
shutil.copyfile(Path(__file__),out/'consumed-bind.py');save(out/'derive.json',r)
try:
 d=json.loads((prior/'derive.json').read_text());a=json.loads(Path(str(actual)+'.json').read_text());assert d['complete'] and a['complete'] and a['observation']['checked']
 assert a['input']['sha256']=='3987479425f7bf0d5c9e7655bb22bae29ed0d44635fdbf50eff2bb3cd869dfb4'
 assert a['output']['sha256']==ident(actual)['sha256']
 for name in ['baseline','private_full','private_setup','private_dp']:
  p=Path(d['variants'][name]['file']);assert ident(p)==d['variants'][name];target=out/(name+'.mjs');shutil.copyfile(p,target);r['variants'][name]=ident(target)
 text=actual.read_text();assert text.count('export default ')==1;text=text.replace('export default ','const $Pair_exports = ',1)+'\nexport default {...$Pair_exports,bench:p=>$Pair_exports.pair(p)};\n'
 target=out/'actual.mjs';target.write_text(text);r['variants']['actual']=ident(target)
 p=Path(d['variants']['typescript']['file']);assert ident(p)==d['variants']['typescript'];target=out/'typescript.mjs';shutil.copyfile(p,target);r['variants']['typescript']=ident(target)
 shutil.copyfile(prior/'points.json',out/'points.json');r['complete']=True
except Exception as e:r['error']=repr(e);raise
finally:save(out/'derive.json',r)
print(json.dumps(dict(complete=True,out=str(out))))
