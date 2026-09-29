#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path.cwd();out=R/'selfhost/build/phase22/context-controls-ctor-index-public-inputs-01';out.mkdir()
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
s=R/'selfhost/build/phase16/wave9-source-01/selection.json';g=R/'selfhost/build/phase22/context-controls-inputs-01/selection.json';m=R/'selfhost/build/phase22/context-frontend-04/acquisition/candidate.json';by={c['id']:c for c in json.loads(s.read_text())['cases']}
ids=['alias-binding/bound-pattern','alias-binding/unbound-pattern','alias-binding/constructor-pattern','qualified-pattern/fresh','qualified-pattern/canonical-reference','qualified-pattern/canonical-bound','module-names/aliased-datatype','module-names/aliased-constructor'];cases=[by[n] for n in ids]
cases += [c for c in json.loads(g.read_text())['cases'] if c['id'].startswith('group-range-positive/constructor-')]
main=json.loads(m.read_text());requested={(c['id'],c['lane']) for c in main['selection']['requested']};inventory={c['id']:c for c in main['inventory']['tests']}
for name in ['check/nat_literal_pattern_arity.bend','check/nat_literal_pattern_empty.bend','page/ctor_list_mismatch_001.bend']:
 assert all((name,l) in requested for l in ['parse','check']);cases.append({'id':name,'lanes':['parse','check']})
assert sum(len(c['lanes']) for c in cases)==24
inputs=[ident(__file__),ident(s),ident(g),ident(m),*[ident(c.get('file') or inventory[c['id']]['file']) for c in cases]]
(out/'selection.json').write_text(json.dumps({'cases':cases},indent=2)+'\n');(out/'plan.json').write_text(json.dumps({'kind':'phase22-ctor-index-public24','complete':True,'frozenBeforeCandidateAcquisition':True,'observations':24,'scope':'Unchanged frozen cases/expectations: constructor alias/namespace/bound pattern distinctions, grouped constructor scrutinees, literal-pattern arity and unknown constructor. Parent source16 and candidate source17 actual parse/check results.','inputs':inputs},indent=2)+'\n');print('Frozen24')
