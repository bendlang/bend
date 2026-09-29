from pathlib import Path
import json
root=Path.cwd();out=root/'selfhost/build/phase16/checker-key-controls-01';out.mkdir();f=out/'fixtures';f.mkdir()
unit='type Unit is Data:\n  Unit{}\n'
app=unit+'def apply(~f: Unit -> Unit, x: Unit) -> Unit:\n  f(x)\n'
carry=unit+'def carry(~f: Unit -> Unit -> Unit, x: Unit) -> Unit:\n  f(x)(Unit{})\n'
fixtures={
 'same-lambda':(app+'def main() -> Unit:\n  a = apply(~(x => x), Unit{})\n  apply(~(x => x), a)\n',['apply~0']),
 'renamed-lambda':(app+'def main() -> Unit:\n  a = apply(~(x => x), Unit{})\n  apply(~(y => y), a)\n',['apply~0','apply~1']),
 'nested-shadow':(carry+'def main() -> Unit:\n  a = carry(~(x => x => x), Unit{})\n  carry(~(x => x => x), a)\n',['carry~0']),
 'capture-distinct':(carry+'def main() -> Unit:\n  a = carry(~(x => y => x), Unit{})\n  carry(~(x => y => y), a)\n',['carry~0','carry~1']),
 'parallel-let':(app+'''def main() -> Unit:
  a = apply(~(x =>
    u v = x Unit{}
    u
  ), Unit{})
  apply(~(x =>
    u v = x Unit{}
    u
  ), a)
''',['apply~0']),
 'lambda-quantities':(app+'def main() -> Unit:\n  a = apply(~(x => x), Unit{})\n  apply(~(+x => x), a)\n',['apply~0','apply~1']),
 'ref-values':(app+'''def one(x: Unit) -> Unit:
  x
def two(x: Unit) -> Unit:
  x
def main() -> Unit:
  a = apply(~one, Unit{})
  b = apply(~two, a)
  apply(~one, b)
''',['apply~0','apply~1']),
 'adt-values':(unit+'''type Bit is Data:
  Zero{}
  One{}
def pick(~A: Type, x: Unit) -> Unit:
  x
def main() -> Unit:
  a = pick(~Unit, Unit{})
  b = pick(~Bit, a)
  pick(~Unit, b)
''',['pick~0','pick~1']),
 'nat-values':(unit+'''type Nat is Data:
  Zero{}
  Succ{pred: Nat}
def lit(~n: Nat, x: Unit) -> Unit:
  x
def main() -> Unit:
  a = lit(~0n, Unit{})
  b = lit(~1n, a)
  lit(~0n, b)
''',['lit~0','lit~1']),
 'u32-values':(unit+'''type Bool is Data:
  False{}
  True{}
type Word is Data:
  WNil{}
  WCon{bit: Bool, rest: Word}
type U32 is Data:
  U32{word: Word}
def lit(~n: U32, x: Unit) -> Unit:
  x
def main() -> Unit:
  a = lit(~1, Unit{})
  b = lit(~2, a)
  lit(~1, b)
''',['lit~0','lit~1']),
}
previous=root/'selfhost/build/phase16/checker-name-controls-01'
selection=json.loads((previous/'selection.json').read_text());direct=json.loads((previous/'direct.json').read_text())
for name,(source,names) in fixtures.items():
 p=f/(name+'.bend');p.write_text(source)
 selection.append({'id':'p16-checker-keys/'+p.name,'file':str(p),'lanes':['check'],'accept':True})
 direct.append({'name':name,'file':str(p),'expectedInstances':names})
(out/'selection.json').write_text(json.dumps(selection,indent=2)+'\n');(out/'direct.json').write_text(json.dumps(direct,indent=2)+'\n');print(out)
