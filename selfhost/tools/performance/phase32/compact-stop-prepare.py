#!/usr/bin/env python3
"""Bind one private host-call reuse experiment and the exact full-check oracle."""
import hashlib,json,pathlib,sys
root=pathlib.Path(__file__).resolve().parents[4];out=pathlib.Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=pathlib.Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
parent=root/'selfhost/build/phase32/compact-scoped-plan-02/plan.json';p=json.loads(parent.read_text())
gate=root/'selfhost/build/phase32/compact-scoped-correctness-02/report.json';g=json.loads(gate.read_text());assert g['complete'] and g['pass'] and g['plan']['sha256']==ident(parent)['sha256']
baseline=next(x for x in g['rows'] if x['role']=='baseline')['result'];assert ident(baseline['file'])['sha256']==baseline['sha256']
worker=pathlib.Path(__file__).with_name('compact-stop-worker.mjs');(out/'worker.mjs').write_bytes(worker.read_bytes())
runner=pathlib.Path(__file__).with_name('compact-cap-run.py');code=runner.read_text();old=" and p['worker']==prior['worker']";assert code.count(old)==1;code=code.replace(old,'')
(out/'run.py').write_text(code);(out/'original-run.py').write_bytes(runner.read_bytes());(out/'consumed-prepare.py').write_bytes(pathlib.Path(__file__).read_bytes())
p.update(kind='phase32-reuse-emission-stop-set',api=p['baseline']['api'],worker=ident(out/'worker.mjs'),priorCorrectness=ident(gate),baselineOracle=baseline,parentPlan=ident(parent),scope='One request-local reuse of j_stops under exact immutable actual07 API; no public injected-API behavior claim.')
p['inputs'] +=[p['priorCorrectness'],p['baselineOracle'],p['parentPlan'],p['worker'],ident(worker),ident(runner),ident(out/'run.py'),ident(__file__),ident(root/'design/phase32/compact-stop-reuse.md')]
(out/'plan.json').write_text(json.dumps(p,indent=2)+'\n');print(out/'plan.json')
