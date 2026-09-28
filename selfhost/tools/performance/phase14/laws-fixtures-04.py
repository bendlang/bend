import pathlib,shutil,json
r=pathlib.Path.cwd();old=r/'selfhost/build/phase14/laws-controls-03';o=r/'selfhost/build/phase14/laws-controls-04';o.mkdir();f=o/'fixtures';shutil.copytree(old/'fixtures',f)
(f/'quantity-law.bend').write_text('import Base\nlaw double:\n  for +x: Nat\n  Nat\n');(f/'safe-quantity.bend').write_text('import Base\nimport ./quantity-law.bend as Q\ndef Q.double(renamed):\n  Nat.add(renamed, renamed)\n')
for n in [0,1]:(f/('template-trust-'+str(n)+'.bend')).write_text('import Base\ndef bad?() -> Nat:\n  9n\ndef choose(~n: Nat) -> Nat:\n  (Bool.pick(Nat, Nat.is_eq(n, 0n), 0n, bad()) : Nat)\ndef main() -> Nat:\n  choose(~'+str(n)+'n)\n')
cases=json.loads((old/'selection.json').read_text())
for c in cases:
 if 'file'in c and str(old/'fixtures')in c['file']:c['file']=str(f/pathlib.Path(c['file']).name)
(o/'selection.json').write_text(json.dumps(cases,indent=2)+'\n');(o/'plan.json').write_text(json.dumps({'scope':'Plain fill parameters inherit + quantity from law; finite explicitly annotated template body with Bool.pick allows type inference and tests erased-branch dependencies. Prior malformed annotated-parameter and unannotated matcher controls retained as invalid positive fixtures.'},indent=2)+'\n')
