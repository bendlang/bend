import hashlib,json,sys
from pathlib import Path
root=Path(__file__).resolve().parents[4];out=Path(sys.argv[1]).resolve();out.mkdir();fixtures=out/'fixtures';fixtures.mkdir()
header='import Base\ndef app(~f: Nat -> Nat, x: Nat) -> Nat:\n  f(x)\ndef outer(~f: Nat -> Nat, x: Nat) -> Nat:\n'
dup='n => Nat.add(n, n)';ident='n => n'
cases={
'local-before-instance':('  g: Nat -> Nat = n => f(n)\n  app(~('+dup+'), x)\n',dup),
'instance-before-local':('  a = app(~('+dup+'), 1n)\n  g: Nat -> Nat = n => f(n)\n  x\n',dup),
'local-before-valid-instance':('  g: Nat -> Nat = n => f(n)\n  app(~('+ident+'), x)\n',dup),
'valid-local-before-instance':('  g: Nat -> Nat = n => f(n)\n  app(~('+dup+'), x)\n',ident)}
rows=[]
for name,(body,arg) in cases.items():
 p=fixtures/(name+'.bend');p.write_text(header+body+'def main() -> Nat:\n  outer(~('+arg+'), 1n)\n');rows.append({'id':'p17-nested/'+name,'file':str(p),'lanes':['check'],'accept':False,'rejectPhase':'check'})
(out/'selection.json').write_text(json.dumps({'cases':rows},indent=2)+'\n')
def identity(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
(out/'manifest.json').write_text(json.dumps({'kind':'phase17-corrected-nested-witness','design':identity(root/'design/phase17/instance-nested-witness.md'),'tool':identity(Path(__file__)), 'fixtures':[identity(Path(r['file'])) for r in rows]},indent=2)+'\n')
