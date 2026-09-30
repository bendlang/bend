#!/usr/bin/env python3
import hashlib,json,pathlib,sys
root=pathlib.Path(__file__).resolve().parents[4];out=pathlib.Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=pathlib.Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
source=root/'selfhost/build/phase32/reuse-prototype-plan-01/plan.json';oracle=root/'selfhost/build/phase32/reuse-prototype-plan-01/report.json';p=json.loads(source.read_text());r=json.loads(oracle.read_text());assert r['pass'] and r['complete']
selected=[next(x for x in p['cases'] if x['id']==name) for name in ['small','mandelbrot','editdist']];p['cases']=selected+selected
p['kind']='phase32-compact-clean-screen';p['order']=['baseline','compact','compact','baseline'];p['node']=ident('/home/ai/.nvm/versions/node/v24.18.0/bin/node');p['oracle']=ident(oracle)
p['expected']={name:next({k:x[k] for k in ['observation','output']} for x in r['rows'] if x['id']==name and x['variant']=='compact') for name in ['small','mandelbrot','editdist']}
p['inputs'] +=[ident(source),p['oracle'],p['node'],ident(__file__),ident(root/'design/phase32/compact-clean-screen.md')]
launch=root/'selfhost/tools/performance/phase32/compact-screen-run.py';(out/'launch.py').write_bytes(launch.read_bytes());(out/'consumed-prepare.py').write_bytes(pathlib.Path(__file__).read_bytes());p['inputs'] +=[ident(launch),ident(out/'launch.py')]
(out/'plan.json').write_text(json.dumps(p,indent=2)+'\n');print(out/'plan.json')
