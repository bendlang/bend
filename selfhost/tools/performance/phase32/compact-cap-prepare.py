#!/usr/bin/env python3
"""Change only the saved API's memo capacity and bind the prior full oracle."""
import hashlib,json,pathlib,sys
root=pathlib.Path(__file__).resolve().parents[4];out=pathlib.Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=pathlib.Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
parent=root/'selfhost/build/phase32/compact-scoped-plan-02/plan.json';p=json.loads(parent.read_text())
gate=root/'selfhost/build/phase32/compact-scoped-correctness-02/report.json';g=json.loads(gate.read_text());assert g['complete'] and g['pass'];assert g['plan']['sha256']==ident(parent)['sha256']
baseline=next(x for x in g['rows'] if x['role']=='baseline')['result'];assert ident(baseline['file'])['sha256']==baseline['sha256']
api=pathlib.Path(p['api']['file']).read_text();old='const p32Limit=4096;';new='const p32Limit=16384;';assert api.count(old)==1
(out/'api.mjs').write_text(api.replace(old,new));(out/'appendix.mjs').write_text(pathlib.Path(p['api']['file']).with_name('appendix.mjs').read_text().replace(old,new))
runner=pathlib.Path(__file__).with_name('compact-cap-run.py');(out/'run.py').write_bytes(runner.read_bytes());(out/'consumed-prepare.py').write_bytes(pathlib.Path(__file__).read_bytes())
p['kind']='phase32-emitter-scoped-query-memo-16k';p['api']=ident(out/'api.mjs');p['priorCorrectness']=ident(gate);p['baselineOracle']=baseline;p['parentPlan']=ident(parent)
p['inputs'] +=[p['api'],p['priorCorrectness'],p['baselineOracle'],p['parentPlan'],ident(out/'appendix.mjs'),ident(runner),ident(out/'run.py'),ident(__file__),ident(root/'design/phase32/compact-capacity.md')]
(out/'plan.json').write_text(json.dumps(p,indent=2)+'\n');print(out/'plan.json')
