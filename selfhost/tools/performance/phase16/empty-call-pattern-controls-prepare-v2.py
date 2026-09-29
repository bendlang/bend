#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,shutil
root=Path(__file__).resolve().parents[4];out=root/'selfhost/build/phase16/empty-call-pattern-controls-02';out.mkdir();f=out/'fixtures';f.mkdir();head='import Base\n';box='type Box is Type:\n  Mk{value:Nat}\n';cases=[]
def case(name,body,accept):cases.append((name,head+body,accept))
case('nested-bound','def use(x:Nat) -> Nat:\n  x()() = {0n : Nat}\n  x\n',True)
case('nested-unbound','def main() -> Nat:\n  x()() = 0n\n  x\n',False)
case('lambda-bound','def use() -> Nat -> Nat:\n  x =>\n    x() = {0n : Nat}\n    x\n',True)
case('local-bound','def main() -> Nat:\n  x = {1n : Nat}\n  x() = {0n : Nat}\n  x\n',True)
case('field-bound',box+'def use(x:Nat,box:Box) -> Nat:\n  match box:\n    case Mk{x()} :\n      x\n',True)
case('field-unbound',box+'def use(box:Box) -> Nat:\n  match box:\n    case Mk{x()} :\n      0n\n',False)
case('row-bound','def use(x:Nat,n:Nat) -> Nat:\n  match n:\n    case x():\n      x\n',True)
case('row-unbound','def use(n:Nat) -> Nat:\n  match n:\n    case x():\n      0n\n',False)
case('qualified-bound','def use(Foo.bar:Nat) -> Nat:\n  Foo.bar()() = {0n : Nat}\n  Foo.bar\n',True)
case('qualified-unbound','def main() -> Nat:\n  Foo.bar() = 0n\n  0n\n',False)
(f/'lib.bend').write_text(head+'def id(x:Nat) -> Nat:\n  x\n')
case('alias-bound','import ./lib.bend as M\ndef use(M.id:Nat) -> Nat:\n  M.id()() = {0n : Nat}\n  M.id\n',True)
case('alias-unbound','import ./lib.bend as M\ndef main() -> Nat:\n  M.id()() = 0n\n  0n\n',False)
case('nonempty-bound','def use(x:Nat -> Nat) -> Nat:\n  x(0n) = 0n\n  0n\n',False)
case('nonempty-unbound','def main() -> Nat:\n  x(0n) = 0n\n  0n\n',False)
case('marked-bound','def use(x:Nat) -> Nat:\n  +x() = {0n : Nat}\n  x\n',True)
case('offload-bound','def use(x:Nat) -> Nat:\n  x!() = 0n\n  0n\n',False)
rows=[];inventory=[]
for name,source,accept in cases:
 p=f/(name+'.bend');p.write_text(source);rows.append({'id':'empty-call-pattern/'+name,'file':str(p),'lanes':['parse','check'],'accept':accept,**({}if accept else{'rejectPhase':'parse'})});inventory.append({'id':name,'accept':accept,'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
prior=json.loads((root/'selfhost/build/phase16/parser-checkpoint-controls-03/selection.json').read_text())['cases'];(out/'selection.json').write_text(json.dumps({'cases':prior+rows},indent=2)+'\n');(out/'boundary-selection.json').write_text(json.dumps({'cases':rows},indent=2)+'\n');shutil.copy2(__file__,out/'consumed-tool.py');(out/'manifest.json').write_text(json.dumps({'plan':'experiments/phase16/P16-empty-call-patterns.md','baseline':'selfhost/build/phase16/wave9-build-01','retainedSelection':str(root/'selfhost/build/phase16/parser-checkpoint-controls-03/selection.json'),'cases':inventory,'support':{'file':str(f/'lib.bend'),'sha256':hashlib.sha256((f/'lib.bend').read_bytes()).hexdigest()}},indent=2)+'\n');print(out)
