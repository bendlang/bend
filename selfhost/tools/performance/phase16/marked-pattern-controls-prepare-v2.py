#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil
r=Path(__file__).resolve().parents[4];o=r/'selfhost/build/phase16/marked-pattern-controls-02';o.mkdir();f=o/'fixtures';f.mkdir();head='import Base\n';cases=[]
def case(name,body,accept,phase='parse'):cases.append((name,head+body,accept,phase))
def local(name,params,pat,accept=True):case(name,'def use('+params+') -> Nat:\n  '+pat+' = {0n : Nat}\n  Nat.add('+('fresh' if 'fresh' in pat else 'x')+', '+('fresh' if 'fresh' in pat else 'x')+')\n',accept)
local('bare-unbound','','+fresh');local('bare-bound','x:Nat','+x');local('empty-bound','x:Nat','+x()');local('nested-bound','x:Nat','+x()()');local('empty-unbound','','+fresh()',False)
case('qualified-bound','def use(Foo.bar:Nat) -> Nat:\n  +Foo.bar() = {0n : Nat}\n  Nat.add(Foo.bar, Foo.bar)\n',True)
case('qualified-unbound','def main() -> Nat:\n  +Foo.bar() = {0n : Nat}\n  0n\n',False)
(f/'lib.bend').write_text(head+'def id(x:Nat) -> Nat:\n  x\n')
case('alias-bound','import ./lib.bend as M\ndef use(M.id:Nat) -> Nat:\n  +M.id() = {0n : Nat}\n  Nat.add(M.id, M.id)\n',True)
case('alias-unbound','import ./lib.bend as M\ndef main() -> Nat:\n  +M.id() = {0n : Nat}\n  0n\n',False)
case('nonempty-bound','def use(x:Nat -> Nat) -> Nat:\n  +x(0n) = {0n : Nat}\n  0n\n',False)
case('datatype-shadow','def use(List:Nat) -> Nat:\n  +List() = {0n : Nat}\n  0n\n',False)
case('datatype-bare','def main() -> Nat:\n  +List = {0n : Nat}\n  0n\n',False)
case('datatype-explicit','def main() -> Nat:\n  +List<Nat> = {0n : Nat}\n  0n\n',False)
case('term-remains-unbound','def use(x:Nat) -> Nat:\n  +x()\n',False,'check')
case('quantity-requires-data','type Token is Type:\n  Mk{}\ndef use(t:Token) -> Token:\n  +t() = {Mk{} : Token}\n  t\n',False,'check')
case('ordinary-affine-control','type Token is Type:\n  Mk{}\ndef use(t:Token) -> Token:\n  t() = {Mk{} : Token}\n  t\n',True)
rows=[]
for name,s,a,phase in cases:
 p=f/(name+'.bend');p.write_text(s)
 if not a and phase=='check':
  rows.append({'id':'marked-pattern/'+name+'-parse','file':str(p),'lanes':['parse'],'accept':True})
  rows.append({'id':'marked-pattern/'+name,'file':str(p),'lanes':['check'],'accept':False,'rejectPhase':'check'})
 else:rows.append({'id':'marked-pattern/'+name,'file':str(p),'lanes':['parse','check'],'accept':a,**({}if a else{'rejectPhase':phase})})
prior=r/'selfhost/build/phase16/empty-call-pattern-controls-02/selection.json';(o/'selection.json').write_text(json.dumps({'cases':json.loads(prior.read_text())['cases']+rows},indent=2)+'\n');(o/'boundary-selection.json').write_text(json.dumps({'cases':rows},indent=2)+'\n');shutil.copy2(__file__,o/'consumed-tool.py');(o/'manifest.json').write_text(json.dumps({'plan':'experiments/phase16/P16-marked-pattern-quantity.md','parentSelection':str(prior),'parentSelectionSha256':hashlib.sha256(prior.read_bytes()).hexdigest(),'files':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in sorted(f.iterdir())]},indent=2)+'\n');print(o)
