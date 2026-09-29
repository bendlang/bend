#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,shutil
r=Path(__file__).resolve().parents[4];o=r/'selfhost/build/phase17/group-controls-03';o.mkdir();f=o/'fixtures';f.mkdir();h='import Base\n';cases=[]
def case(name,body,accept=True,phase='parse'):cases.append((name,h+body,accept,phase))
def main(name,body,ty='Nat',accept=True,phase='parse'):case(name,'def main() -> '+ty+':\n'+''.join('  '+x+'\n' for x in body.splitlines()),accept,phase)
main('scalar-literal','(0n)');main('nested-scalar','(((0n)))');main('scalar-tuple','(0n, 1n)','Nat & Nat');main('nested-tuple','((0n, 1n))','Nat & Nat')
main('local','(x = {0n : Nat}; x)');main('nested-local','((x = {0n : Nat}; x))');main('parallel','(x y = {0n : Nat} {1n : Nat}; Nat.add(x, y))');main('nested-parallel','((x y = {0n : Nat} {1n : Nat}; Nat.add(x, y)))')
main('local-argument','Nat.add((x = {0n : Nat}; x), 1n)');case('local-callee','def identity(x:Nat) -> Nat:\n  x\ndef main() -> Nat:\n  (f = identity; f)(0n)\n',False,'check');main('grouped-scalar-lambda','((x) => x)(0n)');main('local-lambda-body','(x => (y = {x : Nat}; y))(0n)')
main('local-namespace','(x = {1 : U32}; x + 2 : U32)','U32');main('nested-local-namespace','((x = {1 : U32}; x + 2 : U32))','U32');main('local-annotated','{(x = {0n : Nat}; x) : Nat}')
main('group-type','(Nat)','Type');main('local-type','(T = {Nat : Type}; T)','Type');main('family-arg','Nil{}','List<(Nat)>')
main('zero-head-match','(\n  match:\n    case:\n      0n\n)',accept=False);main('nested-zero-head-match','((\n  match:\n    case:\n      0n\n))',accept=False);main('zero-head-match-argument','Nat.add((\n  match:\n    case:\n      0n\n), 1n)',accept=False)
main('zero-head-match-lambda','(\n  match:\n    case:\n      x\n) => x','Nat -> Nat',False)
case('bound-pattern','def use(x:Nat) -> Nat:\n  (x) = {0n : Nat}\n  x\n');case('bound-marked','def use(x:Nat) -> Nat:\n  +(x) = {0n : Nat}\n  Nat.add(x, x)\n')
main('local-pattern','(x = {0n : Nat}; x) = 0n\n0n',accept=False);main('local-lambda-binder','(x = {0n : Nat}; x) => x','Nat -> Nat',False);main('local-marked','+(x = {0n : Nat}; x)',accept=False);main('local-bang','(x = {0n : Nat}; x)!()',accept=False)
main('body-comma','(x = {0n : Nat}; x, 1n)','Nat & Nat',False);main('missing-close','(x = {0n : Nat}; x',accept=False);main('rhs-error-before-close','(x = ); x)',accept=False)
case('match-error-before-close','def global() -> Nat:\n  0n\ndef main() -> Nat:\n  (\n    match global:\n      case x:\n        0n\n',False)
main('local-then-match','(\n  x = {0n : Nat}\n  match x:\n    case Zero{}:\n      0n\n    case Succ{k}:\n      k\n)',accept=False)
rows=[]
for name,source,accept,phase in cases:
 p=f/(name+'.bend');p.write_text(source)
 if not accept and phase=='check':rows += [{'id':'group/'+name+'-parse','file':str(p),'lanes':['parse'],'accept':True},{'id':'group/'+name,'file':str(p),'lanes':['check'],'accept':False,'rejectPhase':'check'}]
 else:rows.append({'id':'group/'+name,'file':str(p),'lanes':['parse','check'],'accept':accept,**({}if accept else{'rejectPhase':phase})})
parents=[r/'selfhost/build/phase16/rejected-stage-controls-01/selection.json',r/'selfhost/build/phase16/marked-pattern-controls-02/selection.json'];old=sum([json.loads(p.read_text())['cases']for p in parents],[])
for name,data in [('shape-selection.json',rows),('selection.json',old+rows)]: (o/name).write_text(json.dumps({'cases':data},indent=2)+'\n')
shutil.copy2(__file__,o/'consumed-tool.py');(o/'manifest.json').write_text(json.dumps({'plan':'design/phase17/group-boundary.md','parentSelections':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in parents],'files':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in sorted(f.iterdir())]},indent=2)+'\n');print(o)
