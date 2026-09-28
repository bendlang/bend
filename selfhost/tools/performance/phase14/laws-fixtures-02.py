import pathlib,shutil,json
root=pathlib.Path.cwd();old=root/'selfhost/build/phase14/laws-controls-01';out=root/'selfhost/build/phase14/laws-controls-02';out.mkdir();f=out/'fixtures';shutil.copytree(old/'fixtures',f)
p=f/'laws.bend';p.write_text(p.read_text().replace('for ~A: Type','for ~A: Data'))
p=f/'safe-quantity.bend';p.write_text(p.read_text().replace('L.id(&T, x)','L.id(T, +x)'))
cases=json.loads((old/'selection.json').read_text())
for c in cases:
 if 'file'in c:c['file']=str(f/pathlib.Path(c['file']).name)
 if c['id'].startswith('import/alias_'):c.pop('accept',None);c.pop('rejectPhase',None);c['file']=str(root/'selfhost/.bootstrap/upstream-phase8/tests'/c['id']);c['id']='p14-existing-'+pathlib.Path(c['id']).stem;c['accept']=False;c['rejectPhase']='parse';c['lanes']=['check']
for n in [0,1]:
 name='template-trust-'+str(n);p=f/(name+'.bend');p.write_text('''import Base
def bad?() -> Nat:
  bad()
def choose(~n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      bad()
def main() -> Nat:
  choose('''+str(n)+'''n)
''');cases.append({'id':'p14-'+name,'file':str(p),'lanes':['parse','check'],'accept':True})
(out/'selection.json').write_text(json.dumps(cases,indent=2)+'\n');(out/'manifest.json').write_text(json.dumps({'kind':'phase14-laws-boundaries-corrected','supersedes':str(old/'manifest.json'),'corrections':['Type parameter changed to Data so +x has a duplicable type','invalid &T syntax replaced with admissible +x quantity on plain fill binder','existing alias fixtures use explicit path to apply acceptance oracle; id-only known inventory preserves original strict fixture expectation'],'scope':'Original failed controls preserved; add two template trust branch cases before execution.'},indent=2)+'\n')
