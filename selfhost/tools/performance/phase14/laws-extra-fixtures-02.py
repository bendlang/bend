import pathlib,shutil,json
r=pathlib.Path.cwd();old=r/'selfhost/build/phase14/laws-extra-controls-01';o=r/'selfhost/build/phase14/laws-extra-controls-02';o.mkdir();f=o/'fixtures';shutil.copytree(old/'fixtures',f);p=f/'foreign-law.bend';p.write_text(p.read_text().replace('  U32','  IO(U32)'))
cases=json.loads((old/'selection.json').read_text())
for c in cases:c['file']=str(f/pathlib.Path(c['file']).name)
(o/'selection.json').write_text(json.dumps(cases,indent=2)+'\n');(o/'plan.json').write_text(json.dumps({'scope':'Foreign law corrected to return base IO directly, as pinned checker requires. Original U32 foreign law is preserved as matching checker refusal, not a trust test.'},indent=2)+'\n')
