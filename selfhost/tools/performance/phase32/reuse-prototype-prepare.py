#!/usr/bin/env python3
import hashlib,json,pathlib,sys
root=pathlib.Path(__file__).resolve().parents[4];out=pathlib.Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=pathlib.Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
parent=root/'selfhost/build/phase32/reuse-plan-01/plan.json';p=json.loads(parent.read_text());p['kind']='phase32-exact-prefix-and-compact-prototypes';p['parentPlan']=ident(parent)
worker=root/'selfhost/tools/performance/phase32/reuse-prototype-worker.mjs';(out/'worker.mjs').write_bytes(worker.read_bytes());(out/'consumed-prepare.py').write_bytes(pathlib.Path(__file__).read_bytes())
p['worker']=ident(out/'worker.mjs');p['inputs'] +=[p['parentPlan'],ident(worker),ident(__file__),p['worker'],ident(root/'design/phase32/reuse-prefix-prototype.md'),ident(root/'design/phase32/compact-memo-prototype.md')]
ed=next(x for x in p['cases'] if x['id']=='editdist');text=pathlib.Path(ed['source']['file']).read_text();assert text.count('U32.shln(x, 13n)')==1
for name,code in [('editdist-first',text),('editdist-unchanged',text),('editdist-body',text.replace('U32.shln(x, 13n)','U32.shln(x, 12n)')),('editdist-restored',text)]:
 f=out/(name+'.txt');f.write_text(code);item=ident(f);p['cases'].append(dict(id=name,text=item,path=str(out/'request.bend'),dependency=''));p['inputs'].append(item)
p['cases']=[{**c,**({'path':str(out/'request.bend')} if 'text' in c else {})} for c in p['cases']]
(out/'plan.json').write_text(json.dumps(p,indent=2)+'\n');print(out/'plan.json')
