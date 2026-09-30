#!/usr/bin/env python3
"""Freeze the rejected two-line default-API optimization and its counterexample."""
import hashlib,json,pathlib,sys
root=pathlib.Path(__file__).resolve().parents[4];out=pathlib.Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=pathlib.Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
parent=root/'selfhost/build/phase32/compact-scoped-plan-02/plan.json';p=json.loads(parent.read_text());original=pathlib.Path(p['baseline']['driver']['file']);text=original.read_text();changes=[]
def replace(a,b):
 global text
 assert text.count(a)==1,(a,text.count(a));text=text.replace(a,b);changes.append(dict(old=a,new=b))
for name in ['assemble.mjs','native-build.mjs','node-resource-args.mjs','compiler-abi.mjs']:
 replace("from './"+name+"';",'from '+json.dumps((original.parent/name).as_uri())+';')
replace("export const project=path.resolve(import.meta.dirname,'..');",'export const project='+json.dumps(str(original.parent.parent))+';')
needle="async function inspectWithMemo(input,{mode='check',api,args=[],timeoutMs=5000,combinedOutput=false,withReport=false,proofOnly=false}={},memo=null) {\n  api??=await loadApi();"
replace(needle,needle.replace('  api??=', '  const ownsApi=api==null;\n  api??='))
replace('api.annotate_selected(contextBook,book,api.j_stops(contextBook))','api.annotate_selected(contextBook,book,ownsApi?stops:api.j_stops(contextBook))')
(out/'conditional-driver.mjs').write_text(text);(out/'changes.json').write_text(json.dumps(changes,indent=2)+'\n')
worker=pathlib.Path(__file__).with_name('compact-stop-boundary-worker.mjs');(out/'worker.mjs').write_bytes(worker.read_bytes());(out/'consumed-prepare.py').write_bytes(pathlib.Path(__file__).read_bytes())
small=next(c for c in p['cases'] if c['id']=='small');(out/'positive.bend').write_bytes(pathlib.Path(small['text']['file']).read_bytes())
p.update(kind='phase32-stop-reuse-owned-api-counterexample',drivers={'original':p['baseline']['driver'],'conditional':ident(out/'conditional-driver.mjs')},worker=ident(out/'worker.mjs'),source=ident(out/'positive.bend'))
p['inputs'] +=[ident(parent),p['drivers']['conditional'],p['worker'],p['source'],ident(out/'changes.json'),ident(worker),ident(__file__)]+[ident(original.parent/n) for n in ['assemble.mjs','native-build.mjs','node-resource-args.mjs','compiler-abi.mjs']]
(out/'plan.json').write_text(json.dumps(p,indent=2)+'\n');print(out/'plan.json')
