from pathlib import Path
import json
root=Path.cwd();out=root/'selfhost/build/phase16/checker-literal-memo-controls-01';out.mkdir();fixtures=out/'fixtures';fixtures.mkdir()
cases={
'repeated-u32':('U32','1','1',1),
'equivalent-string':('String','"a"','"\\u{61}"',1),
'different-string':('String','"a"','"b"',2),
'positive-negative-zero':('F32','0.0','(-0.0)',2),
'repeated-negative-zero':('F32','(-0.0)','(-0.0)',2),
'nat-constructor':('Nat','1n','Succ{Zero{}}',2),
'string-constructor':('String','"a"','SCon{Chr{97}, SNil{}}',2),
}
rows=[]
for name,(typ,a,b,count) in cases.items():
 text=f'import Base\ndef keep(~n: {typ}, x: Nat) -> Nat:\n  x\ndef main() -> Nat:\n  a = keep(~{a}, 0n)\n  keep(~{b}, a)\n'
 p=fixtures/(name+'.bend');p.write_text(text);rows.append({'name':name,'file':str(p),'expectedInstances':count,'note':'Expected counts must be checked against pinned parser/lowering; repeated negative zero may expose existing source-position Ref identity.' if name=='repeated-negative-zero' else ''})
# Reuse the exact saved U32 literal-versus-written-constructor counterexample.
p=root/'selfhost/build/phase16/checker-key-controls-03/fixtures/u32-literal-vs-ctor.bend'
if not p.exists():
 p=next((root/'selfhost/build/phase16/checker-key-controls-03/fixtures').glob('*u32*'))
rows.append({'name':'u32-constructor','file':str(p),'expectedInstances':2})
(out/'direct.json').write_text(json.dumps(rows,indent=2)+'\n')
(out/'selection.json').write_text(json.dumps([{'id':'p16-literal-memo/'+r['name'],'file':r['file'],'lanes':['check'],'accept':True} for r in rows],indent=2)+'\n')
print(out)
