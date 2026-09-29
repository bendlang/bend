"""Freeze small public-boundary inputs before running either compiler."""
from pathlib import Path
import hashlib,json,sys
root=Path(__file__).resolve().parents[4]
out=Path(sys.argv[1]).resolve();out.mkdir();(out/'fixtures').mkdir()
unit='type Unit is Data:\n  Unit{}\n'
bits=unit+'type Bit is Data:\n  Zero{}\n  One{}\n'
first='def first(~key: Bit, x: Unit) -> Unit:\n  x\n'
apply='def consume(x: Unit, y: Unit) -> Unit:\n  x\ndef apply(~f: Unit -> Unit, x: Unit) -> Unit:\n  f(x)\n'
cases=[
 ('prefix-reuse',bits+first+'def before() -> Unit:\n  first(~Zero{}, Unit{})\ndef main() -> Unit:\n  a = first(~Zero{}, Unit{})\n  first(~One{}, a)\n',4,True),
 ('prefix-nested',bits+first+'def outer(~key: Bit, x: Unit) -> Unit:\n  first(~key, x)\ndef before() -> Unit:\n  outer(~Zero{}, Unit{})\ndef main() -> Unit:\n  outer(~One{}, Unit{})\n',5,True),
 ('law-fill',unit+'law value: Unit\ndef value():\n  Unit{}\ndef main() -> Unit:\n  value()\n',2,True),
 ('future-body-before',unit+'law Alias: Type\ndef early() -> Alias:\n  Unit{}\ndef Alias():\n  Unit\n',2,False),
 ('future-body-after',unit+'law Alias: Type\ndef Alias():\n  Unit\ndef main() -> Alias:\n  Unit{}\n',2,True),
 ('instance-failure',unit+apply+'def main() -> Unit:\n  apply(~(x => consume(x, x)), Unit{})\n',3,False),
 ('generic-private-failure',unit+'def bad(~A: Type, x: A) -> Unit:\n  x\n',1,False),
 ('generic-success',unit+'def identity(~A: Type, x: A) -> A:\n  x\ndef main() -> Unit:\n  identity(~Unit, Unit{})\n',2,True),
 ('todo-body',unit+'def main() -> Unit:\n  ?TODO\n',1,True),
 ('open-law',unit+'law missing: Unit\n',1,True),
]
rows=[]
for name,text,prefix,accept in cases:
 p=out/'fixtures'/(name+'.bend');p.write_text(text)
 rows.append({'id':name,'file':str(p),'prefixEvents':prefix,'checkerAccept':accept,'completion':name in ['todo-body','open-law'],'privateFailure':name=='generic-private-failure','instanceFailure':name=='instance-failure'})
lit=lambda kind,number=0,text='':{'kind':'literal','literalKind':kind,'number':number,'text':text}
lam=lambda q,present,legacy=False:{'kind':'lambda','quantity':q,'present':present,'legacy':legacy}
direct=[
 ('literal-identical',lit('Nat',1),lit('Nat',1),True),
 ('nat-payload',lit('Nat',1),lit('Nat',2),False),
 ('u32-payload',lit('U32',1),lit('U32',2),False),
 ('string-payload',lit('String',text='a'),lit('String',text='b'),False),
 ('string-astral-identical',lit('String',text='a😀\t'),lit('String',text='a😀\t'),True),
 ('literal-kind',lit('Nat',1),lit('U32',1),False),
 ('compact-vs-expanded-nat',lit('Nat',0),{'kind':'constructor','name':'Zero'},False),
 ('compact-vs-expanded-string',lit('String'),{'kind':'constructor','name':'SNil'},False),
 ('lambda-affine-presence',lam(1,False),lam(1,True),False),
 ('lambda-many-presence',lam(2,False),lam(2,True),False),
 ('lambda-legacy-explicit',lam(1,True,True),lam(1,True),True),
 ('origin-only',dict(lit('Nat',1),begin=1,end=2),dict(lit('Nat',1),begin=91,end=92),True),
]
identity=lambda p:{'file':str(p.resolve()),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
plan={'kind':'phase19-instance-public-boundary-inputs','parentAttempt':str(root/'selfhost/build/phase18/instance-world-build-06'),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'pin':'b2111cf43244e65f76ddc278ee695e669f720cbf','cases':rows,'exactCases':[{'id':n,'left':a,'right':b,'expected':e} for n,a,b,e in direct],'scope':'Public exact-prefix syntax identity and program/source/diagnostic boundaries. No oracle is derived from candidate output. Prefix resume compares to full pinned checking; no synthetic TypeScript partial-check interpreter.','intendedDelta':'Immediate live-instance validation moves instance-failure into check_book; old public18 pre-specialization acceptance is intentionally not preserved. Stable KSpecialized/KChecked4 projection and demand contracts remain independent gates.','inputs':[identity(Path(__file__)),*[identity(Path(r['file'])) for r in rows]]}
(out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n')
print(json.dumps({'plan':str(out/'plan.json'),'fixtures':len(rows),'exactCases':len(direct)}))
