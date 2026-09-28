import pathlib,shutil,json
r=pathlib.Path.cwd();old=r/'selfhost/build/phase14/laws-controls-02';o=r/'selfhost/build/phase14/laws-controls-03';o.mkdir();f=o/'fixtures';shutil.copytree(old/'fixtures',f)
for p in f.glob('template-trust-*.bend'):p.write_text(p.read_text().replace('def bad?() -> Nat:\n  bad()','def bad?() -> Nat:\n  9n'))
cases=json.loads((old/'selection.json').read_text())
for c in cases:
 if 'file'in c and str(old/'fixtures')in c['file']:c['file']=str(f/pathlib.Path(c['file']).name)
(o/'selection.json').write_text(json.dumps(cases,indent=2)+'\n');(o/'plan.json').write_text(json.dumps({'scope':'Retain corrected controls, replacing divergent unsafe helper with finite marked-unsafe constant. Exact template trust/output agreement required; all previous failed prefix evidence preserved.'},indent=2)+'\n')
