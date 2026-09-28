import pathlib,json
r=pathlib.Path.cwd();o=r/'selfhost/build/phase14/laws-extra-controls-01';o.mkdir();f=o/'fixtures';f.mkdir();
(f/'law.bend').write_text('import Base\nlaw value:\n  Nat\n');(f/'fill.bend').write_text('import ./law.bend as L\ndef L.value():\n  7n\n');(f/'consumer.bend').write_text('import Base\nimport ./law.bend as L\ndef use() -> Nat:\n  L.value()\n')
(f/'foreign-law.bend').write_text('import Base\nlaw value:\n  U32\n');(f/'host.js').write_text('exports.value = () => 7;\n')
cases=[]
def add(n,s,a,p=None):
 q=f/(n+'.bend');q.write_text(s);cases.append({'id':'p14-'+n,'file':str(q),'lanes':['check'],'accept':a,**({'rejectPhase':p}if p else{})})
add('chronology-before','import Base\nimport ./consumer.bend as C\nimport ./fill.bend as F\ndef main() -> Nat:\n  C.use()\n',False,'check')
add('chronology-after','import Base\nimport ./fill.bend as F\nimport ./consumer.bend as C\ndef main() -> Nat:\n  C.use()\n',True)
add('foreign-law-fill','import Base\nimport ./foreign-law.bend as L\ndef L.value():\n  import "host.js"\n',False,'verdict')
add('bad-fill-body','import Base\nimport ./law.bend as L\ndef L.value():\n  Unit{}\n',False,'check')
(o/'selection.json').write_text(json.dumps(cases,indent=2)+'\n')
(o/'plan.json').write_text(json.dumps({'scope':'Additional fixed chronology, foreign trust, and checked body-type boundaries before execution.'},indent=2)+'\n')
