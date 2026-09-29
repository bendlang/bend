from pathlib import Path
import json,hashlib,shutil
root=Path.cwd();out=root/'selfhost/build/phase17/instance-controls-02';out.mkdir();fixtures=out/'fixtures';fixtures.mkdir();rows=[];copied=[]
header='import Base\ndef app(~f: Nat -> Nat, x: Nat) -> Nat:\n  f(x)\n'
dup='n => Nat.add(n, n)';identity='n => n'
owned={
 'instance-before-type':header+'def main() -> Nat:\n  y = app(~('+dup+'), 1n)\n  True{}\n',
 'type-before-instance':header+'def main() -> Nat:\n  y: Nat = True{}\n  app(~('+dup+'), 1n)\n',
 'valid-instance-before-type':header+'def main() -> Nat:\n  y = app(~('+identity+'), 1n)\n  True{}\n',
 'nested-ordinary-before-instance':header+'def outer(~f: Nat -> Nat, x: Nat) -> Nat:\n  a = f(x)\n  app(~('+dup+'), 1n)\ndef main() -> Nat:\n  outer(~('+dup+'), 1n)\n',
 'nested-instance-before-ordinary':header+'def outer(~f: Nat -> Nat, x: Nat) -> Nat:\n  a = app(~('+dup+'), 1n)\n  f(x)\ndef main() -> Nat:\n  outer(~('+dup+'), 1n)\n',
 'nested-valid-before-ordinary':header+'def outer(~f: Nat -> Nat, x: Nat) -> Nat:\n  a = app(~('+identity+'), 1n)\n  f(x)\ndef main() -> Nat:\n  outer(~('+dup+'), 1n)\n'}
for name,source in owned.items():
 p=fixtures/(name+'.bend');p.write_text(source);rows.append({'id':'p17-instance/'+name,'file':str(p),'lanes':['check'],'accept':False,'rejectPhase':'check'})
controls=[('checker-name-controls-01','repeat-key',True),('checker-name-controls-01','interleaved-keys',True),('checker-name-controls-01','nested-templates',True),('checker-name-controls-01','decreasing-reuse',True),('checker-name-controls-01','erased-call',True),('checker-key-controls-01','same-lambda',True),('checker-key-controls-01','renamed-lambda',True),('checker-key-controls-01','lambda-quantities',True),('checker-controls-01','template-captured',False)]
for parent,name,accept in controls:
 old=root/'selfhost/build/phase16'/parent/'fixtures'/(name+'.bend');p=fixtures/(name+'.bend');shutil.copyfile(old,p);copied.append({'source':str(old),'target':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()});row={'id':'p17-instance/'+name,'file':str(p),'lanes':['check'],'accept':accept}
 if not accept:row['rejectPhase']='check'
 rows.append(row)
for group,name in [('check','template_inst_cycle'),('comptime','err_grow'),('comptime','err_grow_double')]:
 p=root/'selfhost/.bootstrap/upstream-phase8/tests'/group/(name+'.bend')
 assert p.is_file(),p
 rows.append({'id':group+'/'+name+'.bend','lanes':['check']})
(out/'selection.json').write_text(json.dumps({'cases':rows},indent=2)+'\n');(out/'manifest.json').write_text(json.dumps({'kind':'phase17-instance-chronology-controls','design':str(root/'design/phase17/instance-chronology.md'),'designSha256':hashlib.sha256((root/'design/phase17/instance-chronology.md').read_bytes()).hexdigest(),'owned':list(owned),'copied':copied,'observations':len(rows),'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n');print(len(rows))
