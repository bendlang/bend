#!/usr/bin/env python3
"""Freeze independent C1 cases before any candidate or pinned probe."""
from pathlib import Path
import hashlib,json,shutil
R=Path(__file__).resolve().parents[4]
O=R/'selfhost/build/phase21/group-comma-controls-01';O.mkdir(parents=True)
F=O/'fixtures';F.mkdir();rows=[]
def case(name,body,accept,ty='Nat & Nat',prefix='',decl='main()'):
 source='import Base\n'+prefix+'def '+decl+' -> '+ty+':\n'+''.join('  '+s+'\n' for s in body.splitlines())
 p=F/(name+'.bend');p.write_text(source)
 rows.append({'id':'group-comma/'+name,'file':str(p),'lanes':['parse','check'],'accept':accept,**({} if accept else {'rejectPhase':'parse'})})
case('scalar-tuple','(0n, 1n)',True)
case('nested-scalar-tuple','((0n), 1n)',True)
case('completed-local-tuple','((x = {0n : Nat}; x), 1n)',True)
case('completed-nested-local-tuple','(((x = {0n : Nat}; x)), 1n)',True)
case('raw-parallel-comma','(x y = {0n : Nat} {1n : Nat}; Nat.add(x, y), 2n)',False)
case('completed-parallel-tuple','((x y = {0n : Nat} {1n : Nat}; Nat.add(x, y)), 2n)',True)
case('raw-typed-local-comma','(x : Nat = 0n; x, 1n)',False)
case('completed-typed-local-tuple','((x : Nat = 0n; x), 1n)',True)
case('invalid-type-pattern-comma','(Type = 0n; 0n, 1n)',False)
case('invalid-constructor-pattern-comma','(Succ{} = 0n; 0n, 1n)',False)
case('rhs-before-pattern-comma','(Type = return 0n; 0n, 1n)',False)
case('pattern-before-continuation-comma','(Type = 0n; return 0n, 1n)',False)
case('raw-comma-before-later-syntax','(x = {0n : Nat}; x, return 0n)',False)
case('completed-tuple-reaches-later-syntax','((x = {0n : Nat}; x), return 0n)',False)
case('ungrouped-valid-match','match n:\n  case Zero{}:\n    0n\n  case Succ{k}:\n    k',True,ty='Nat',decl='use(n: Nat)')
prior='def global() -> Nat:\n  0n\n\n'
case('match-global-before-comma','(\n  match global:\n    case x:\n      0n\n, 1n)',False,prefix=prior)
case('match-global-before-close','(\n  match global:\n    case x:\n      0n\n)',False,ty='Nat',prefix=prior)
case('completed-match-before-outer-comma','((\n  match global:\n    case x:\n      0n\n), 1n)',False,prefix=prior)
case('match-pattern-before-comma','(\n  match global:\n    case Type:\n      0n\n, 1n)',False,prefix=prior)
case('match-later-row-syntax-before-flatten','(\n  match global:\n    case Zero{}:\n      0n\n    case Succ{k}:\n      )\n, 1n)',False,prefix=prior)
case('match-parameter-before-comma','(\n  match n:\n    case x:\n      x\n, 1n)',False,decl='use(n: Nat)')
assert len(rows)==21
stage=R/'selfhost/build/phase16/rejected-stage-controls-01/selection.json'
shape=R/'selfhost/build/phase18/cursor-controls-01/selection.json'
old=json.loads(stage.read_text())['cases'];saved=[c for c in json.loads(shape.read_text())['cases'] if c['id']=='group/body-comma']
assert len(old)==8 and len(saved)==1
selection={'cases':saved+rows+old}
(O/'selection.json').write_text(json.dumps(selection,indent=2)+'\n')
shutil.copy2(__file__,O/'consumed-tool.py')
def identity(p):return {'file':str(p.resolve()),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
attempt=R/'selfhost/build/phase20/import-diagnostic-build-04/attempt.json';a=json.loads(attempt.read_text())
assert a['api']['sha256']=='40c8f7f3b7cd0e96aef57d7d574ebfd85607cd4e096909d083b450b4d973362c'
assert identity(Path(a['api']['file']))['sha256']==a['api']['sha256']
files=[Path(__file__),R/'design/phase21/group-boundaries.md',R/'design/phase21/group-comma-controls.md',stage,shape,O/'selection.json',attempt,Path(a['api']['file']),R/'selfhost/tools/performance/phase18/cursor-paired-run.mjs',R/'selfhost/.bootstrap/upstream-phase8/bend2/bend.ts',*[Path(c['file']) for c in selection['cases']]]
(O/'manifest.json').write_text(json.dumps({'kind':'phase21-group-comma-diagnostic-controls','frozen':True,'candidateAttempt':str(attempt.parent),'candidateApiSha256':a['api']['sha256'],'upstream':'b2111cf43244e65f76ddc278ee695e669f720cbf','newFixtures':21,'savedFixtures':9,'observations':60,'compilerSourceChanged':False,'inputs':[identity(p)for p in files]},indent=2)+'\n')
print(O)
