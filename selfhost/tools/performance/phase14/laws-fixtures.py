import pathlib,json
root=pathlib.Path.cwd();out=root/'selfhost/build/phase14/laws-controls-01';out.mkdir();f=out/'fixtures';f.mkdir();(f/'laws.bend').write_text('''import Base
law id:
  for ~A: Type
  for +x: A
  A
law one:
  {1n == 1n : Nat}
law add:
  for a: Nat
  for b: Nat
  Nat
''')
(f/'filled.bend').write_text('import Base\nimport ./laws.bend as L\ndef L.one():\n  {==}\n')
(f/'native.bend').write_text('import Base\ndef one() -> U32:\n  1\n')
(f/'foreign.bend').write_text('import Base\ndef one() -> U32:\n  import "host.js"\n')
(f/'host.js').write_text('exports.one = () => 1;\n')
prefix='import Base\nimport ./laws.bend as L\n';cases=[]
def add(n,src,accept=True,phase=None):
 p=f/(n+'.bend');p.write_text(src);cases.append({'id':'p14-'+n,'file':str(p),'lanes':['parse','check'] if accept else ['check'],'accept':accept,**({'rejectPhase':phase}if phase else {})})
add('safe-renamed-dependent',prefix+'def L.id(T, renamed):\n  renamed\ndef L.one():\n  {==}\ndef L.add(x, y):\n  Nat.add(x, y)\ndef main() -> Nat:\n  L.id(Nat, L.add(2n, 3n))\n')
add('safe-quantity',prefix+'def L.id(&T, x):\n  x\ndef L.one():\n  {==}\ndef L.add(a, b):\n  Nat.add(a, b)\n')
add('missing-law',prefix+'def L.missing():\n  0\n',False,'parse')
add('duplicate-local',prefix+'def L.one():\n  {==}\ndef L.one():\n  {==}\n',False,'parse')
add('duplicate-alias',prefix+'import ./laws.bend as M\ndef L.one():\n  {==}\ndef M.one():\n  {==}\n',False,'parse')
add('already-filled',prefix+'import ./filled.bend as F\ndef L.one():\n  {==}\n',False,'parse')
add('return-annotation',prefix+'def L.one() -> {1n == 1n : Nat}:\n  {==}\n',False,'parse')
add('typed-parameter',prefix+'def L.add(x: Nat, y):\n  Nat.add(x, y)\n',False,'parse')
add('template-marker',prefix+'def L.id(~A, x):\n  x\n',False,'parse')
add('template-missing',prefix+'def L.id():\n  0\n',False,'parse')
add('late-import','import Base\ndef L.one():\n  {==}\nimport ./laws.bend as L\n',False,'parse')
add('alias-ambiguity','import Base\nimport ./laws.bend as Nat\ndef Nat.add(a, b):\n  0n\n',False,'parse')
add('filled-def','import Base\nimport ./native.bend as L\ndef L.one():\n  1\n',False,'parse')
add('foreign-def','import Base\nimport ./foreign.bend as L\ndef L.one():\n  1\n',False,'parse')
add('foreign-template',prefix+'def L.id(A, x):\n  import "host.js"\n',False,'parse')
ref=json.loads((root/'selfhost/build/phase8/reference-frontend-01/reference.json').read_text())
trust=[{'id':r['id'],'lanes':['parse','check']}for r in ref['results']if r['lane']=='check' and r.get('result',{}).get('phase')=='verdict'];assert len(trust)==11,len(trust)
extra=[{'id':'import/'+n+'.bend','lanes':['parse','check'],'accept':False,'rejectPhase':'parse'} for n in ['alias_decl','alias_shadow','alias_twice']]
(out/'selection.json').write_text(json.dumps(cases+trust+extra,indent=2)+'\n')
(out/'manifest.json').write_text(json.dumps({'custom':len(cases),'trust':len(trust),'existingAliasNegatives':len(extra),'scope':'Fixed before executing candidate03; positive controls fill every law, preserve dependent renamed/template/quantity semantics; negative phase and trust exact output separate.'},indent=2)+'\n')
