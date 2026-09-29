#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil
r=Path(__file__).resolve().parents[4];out=r/'selfhost/build/phase19/context-row-controls-01';out.mkdir();(out/'fixtures').mkdir();sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();selection=r/'selfhost/build/phase18/cursor-controls-01/selection.json';rows=[]
for x in json.loads(selection.read_text())['cases']:
 if not x['id'].startswith('rejected-stage/'):continue
 p=Path(x['file']);dest=out/'fixtures'/p.name;shutil.copy2(p,dest);assert sha(p)==sha(dest);rows.append(dict(id=x['id'],file=str(dest),original=dict(file=str(p),sha256=sha(p)),target='use',sourceBegin=1000001,originalLanes=x['lanes'],supported=True))
prefix='import Base\ndef global() -> Nat:\n  0n\n\n'
extra={
 'valid-rows':'  match n:\n    case Zero{}:\n      0n\n    case Succ{k}:\n      k\n',
 'valid-group':'  (0n)\n',
 'valid-group-local':'  (x = 0n; x)\n',
 'group-before-missing-close':'  (\n    match global:\n      case x:\n        0n\n',
 'qualified-head':'  match Foo.bar:\n    case x:\n      0n\n',
 'ordinary-global-head':'  match global:\n    case x:\n      0n\n',
 'constructor-argument-error-first':'  Unknown{return} = 0n; )\n',
 'constructor-arity-before-continuation':'  Succ{} = 0n; )\n',
 'literal-pattern':'  0n = 0n; 0n\n',
 'unsupported-group-lambda':'  (x => x)\n',
 'unsupported-group-redex':'  ((x => x)(n))\n',
 'unsupported-group-annotation':'  (n : Nat)\n',
}
for name,body in extra.items():
 p=out/'fixtures'/(name+'.bend');p.write_text(prefix+'def use(n:Nat) -> Nat:\n'+body);rows.append(dict(id='context-row/'+name,file=str(p),target='use',sourceBegin=1000001,originalLanes=[],supported=not name.startswith('unsupported-')))
assert len(rows)==20
data=dict(parentAttempt=str(r/'selfhost/build/phase19/context-body-build-03'),cases=rows,selection=dict(file=str(selection),sha256=sha(selection)),contract='Original saved8 fixtures/16 lanes plus12 independent controls; private block result is scoped syntax, not Core',seedProtocol=['Load pinned Base','Parse exact completed prefix','Run pinned parse_name, parse_tele and return parse_term at original header cursor','Run parse_body then body_flatten with exact header PVars','Compare diagnostic independently with pinned book_load of the full original fixture'],sourceView='Pinned book_load replaces each valid import-header line with empty text; retain original and exact parser view separately')
(out/'cases.json').write_text(json.dumps(data,indent=2)+'\n');shutil.copy2(__file__,out/'consumed-prepare.py');files=[Path(__file__),r/'design/phase19/saved-row-group-frontier.md',out/'cases.json',*[Path(x['file'])for x in rows]];(out/'manifest.json').write_text(json.dumps(dict(complete=True,inputs=[dict(file=str(p),sha256=sha(p))for p in files]),indent=2)+'\n');print(out)
