from pathlib import Path
import difflib,hashlib,json,shutil
root=Path(__file__).resolve().parents[4];phase=root/'selfhost/build/phase16'
base=phase/'wave4-source-02/project';out=phase/'unbound-marker-source-01';out.mkdir();shutil.copytree(base,out/'project')
replacements={
 'src/front/fresh_work.bend':('ffw_done(kt_span("Var", nm(term), next, 1, Nil{}, kb(term), ke(term)), U32.add(next, 1), stack)', 'ffw_done(term, next, stack)'),
 'src/check/kernel.bend':('u => bad("cannot infer: annotation required")', 'u => bad(kc(String, String.eq(tg(t), "FUnboundVar"), u => "unbound variable", u => "cannot infer: annotation required"))'),
 'src/diagnostic/trace.bend':('String.eq(code, "unbound variable"), u => dg_pair(dg_text("a bound variable"), t)', 'String.eq(code, "unbound variable"), u => dg_pair(dg_text("a bound variable"), kc(KTerm, String.eq(tg(t), "FUnboundVar"), u => dg_text(nm(t) ++ "^-1"), u => t))'),
}
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
changes=[]
for relative,(old,new) in replacements.items():
 p=out/'project'/relative;s=p.read_text();assert s.count(old)==1,(relative,s.count(old));p.write_text(s.replace(old,new));patch=out/(relative.replace('/','_')+'.patch');patch.write_text(''.join(difflib.unified_diff(s.splitlines(True),p.read_text().splitlines(True),fromfile=relative,tofile=relative)));changes.append({'relative':relative,'before':ident(base/relative),'after':ident(p),'patch':ident(patch)})
fixtures={
 'same-name':'def f(x: U32) -> U32: +x\n',
 'shadowed':'def f(x: U32) -> U32:\n  x = 1\n  +x\n',
 'no-binding':'def main() -> U32: +x\n',
 'inferred-marker':'def main() -> U32:\n  y = +x\n  y\n',
 'closed-template':'def app(~f: Nat -> Nat, x: Nat) -> Nat: f(x)\ndef main() -> Nat: app(~(x => +x), 1n)\n',
 'open-template':'def app(~f: Nat -> Nat, x: Nat) -> Nat: f(x)\ndef g(x: Nat) -> Nat: app(~(y => +x), x)\n',
 'ordinary-variable':'def f(x: U32) -> U32: x\ndef main() -> U32: f(1)\n',
 'reusable-binder':'def f(+x: U32) -> U32: U32.add(x, x)\ndef main() -> U32: f(1)\n',
 'marked-datatype':'law t: Type\ndef t(): +Nat\ndef main() -> U32: 1\n',
}
fd=out/'fixtures';fd.mkdir();cases=[{'id':x,'lanes':['check']} for x in ['parse/plus_binder_term.bend','comptime/err_plus_term.bend']]
for name,text in fixtures.items():
 p=fd/(name+'.bend');p.write_text('import Base\n'+text);positive=name in ['ordinary-variable','reusable-binder','marked-datatype'];case={'id':'unbound-marker/'+name,'file':str(p),'lanes':['check'],'accept':positive}
 if not positive:case['rejectPhase']='check'
 cases.append(case)
(out/'selection.json').write_text(json.dumps({'cases':cases},indent=2)+'\n')
(out/'manifest.json').write_text(json.dumps({'parent':str(base),'changes':changes,'tool':ident(Path(__file__)),'plan':ident(root/'design/phase16/unbound-binder-marker.md'),'fixtures':[ident(p) for p in sorted(fd.glob('*.bend'))]},indent=2)+'\n')
(out/'workflow.json').write_text(json.dumps({'project':str(out/'project'),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'1','jobs':1},indent=2)+'\n');shutil.copy2(__file__,out/'consumed-tool.py');print(out)
