#!/usr/bin/env python3
"""Add the freshly checked statement compiler to frozen saved-output cohorts."""
from pathlib import Path
import hashlib,json,shutil,sys
source,actual,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
r=dict(kind='phase32-local-actual-statement-cohort',complete=False,inputs=[ident(Path(__file__)),ident(source/'derive.json')],cases={})
shutil.copyfile(Path(__file__),out/'consumed-bind.py')
try:
 d=json.loads((source/'derive.json').read_text());assert d['complete'] and d['pass']
 for entry in d['inputs']:assert ident(entry['file'])==entry
 for name in ['pair','fold']:
  emitted=actual/(name+'.mjs');receipt=Path(str(emitted)+'.json');a=json.loads(receipt.read_text());assert a['complete'] and a['observation']['checked'];assert a['output']['sha256']==ident(emitted)['sha256']
  baseline_receipt=json.loads(Path(d['cases'][name]['inputs']['receipt']).read_text());assert a['input']['sha256']==baseline_receipt['input']['sha256']
  r['inputs'] += [ident(emitted),ident(receipt)];target=out/name;target.mkdir();variants={}
  for role in ['baseline','statements','actual_statements','fusion','combined','typescript']:
   p=target/(role+'.mjs')
   if role=='actual_statements':
    text=emitted.read_text()
    if name=='pair':
     assert text.count('export default ')==1;text=text.replace('export default ','const $Pair_exports = ',1)+'\nexport default {...$Pair_exports,bench:p=>$Pair_exports.pair(p)};\n'
    p.write_text(text)
   else:
    entry=d['cases'][name]['variants'][role];assert ident(entry['file'])==entry;shutil.copyfile(entry['file'],p);r['inputs'].append(entry)
   variants[role]=ident(p)
  save(target/'derive.json',dict(complete=True,variants=variants));r['cases'][name]=dict(variants=variants)
  if name=='pair':shutil.copyfile(source/'pair/points.json',target/'points.json')
 r['complete']=True
except Exception as e:r['error']=repr(e);raise
finally:save(out/'derive.json',r)
print(json.dumps(dict(complete=True,out=str(out))))
