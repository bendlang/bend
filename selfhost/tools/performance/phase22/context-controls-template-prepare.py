#!/usr/bin/env python3
"""Freeze unchanged existing public cases for the dx-only index lookup screen."""
from pathlib import Path
import json,hashlib
R=Path.cwd();out=R/'selfhost/build/phase22/context-controls-template-inputs-01';out.mkdir()
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
selection=R/'selfhost/build/phase16/wave9-source-01/selection.json'
header=R/'selfhost/build/phase22/context-header-controls-01/selection.json'
main=R/'selfhost/build/phase22/context-frontend-04/acquisition/candidate.json'
ids=['p16-import/ordinary-fill','p16-import/annotated-fill','alias-binding/family-and-template','alias-binding/template-shadow','alias-binding/applied','local-law/correct','local-law/ordinary-template','comptime/err_fill_short.bend']
by={c['id']:c for c in json.loads(selection.read_text())['cases']};cases=[by[i] for i in ids]
h={c['id']:c for c in json.loads(header.read_text())['cases']};cases += [h['context-header/law-self'],h['context-header/template-self']]
m=json.loads(main.read_text());requested={(x['id'],x['lane']) for x in m['selection']['requested']};inventory={x['id']:x for x in m['inventory']['tests']}
for i in ['base/bytes_ops.bend','comptime/err_arg_type.bend']:
 assert all((i,l) in requested for l in ['parse','check']);cases.append({'id':i,'lanes':['parse','check']})
assert len(cases)==12 and sum(len(x['lanes']) for x in cases)==24
files=[c.get('file') or inventory[c['id']]['file'] for c in cases]
inputs=[ident(__file__),ident(selection),ident(header),ident(main),*[ident(f) for f in files]]
plan={'kind':'phase22-dx-index-public24','complete':True,'frozenBeforeCandidateAcquisition':True,'observations':24,'scope':'Existing12 fixtures only; unchanged integration/header case objects and two main inventory parse/check requests. Run source13 parent and source15 candidate against the pinned oracle. No fixture or expectation changes; exact return diagnostics, error phases, raw statuses and host results compared through unchanged run-v7.','coverage':['Imported ordinary and rejected annotated law fill','Aliased template calls and lexical shadowing','Local law fill and ordinary template call','Missing referenced call head','Wrong-type template argument and insufficient fill binders','Recursive local-law and explicit template self-calls'],'inputs':inputs}
(out/'selection.json').write_text(json.dumps({'cases':cases},indent=2)+'\n');(out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n');print(json.dumps({'observations':24,'plan':ident(out/'plan.json')}))
