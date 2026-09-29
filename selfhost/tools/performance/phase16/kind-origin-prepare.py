from pathlib import Path
import difflib,hashlib,json,shutil
root=Path(__file__).resolve().parents[4];phase=root/'selfhost/build/phase16'
base=phase/'unbound-marker-source-02/project';out=phase/'kind-origin-source-01';out.mkdir();shutil.copytree(base,out/'project')
p=out/'project/src/check/kernel.bend';s=p.read_text();old='  check_adt_kind_head(e, d, wnf(cb(e), tel), ctx)';new='  dg_trace(e, ctx, tel, atom("Absent"), check_adt_kind_head(e, d, wnf(cb(e), tel), ctx))';assert s.count(old)==1;p.write_text(s.replace(old,new))
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
patch=out/'kind-origin.patch';patch.write_text(''.join(difflib.unified_diff(s.splitlines(True),p.read_text().splitlines(True),fromfile='src/check/kernel.bend',tofile='src/check/kernel.bend')))
fixtures={
 'parameterized':'law F: Type -> Type\ntype Bad<A: Type> is F(A):\n  Bad{}\n',
 'bound-return':'type Bad<A: Type> is A:\n  Bad{}\n',
 'earlier-error':'def wrong() -> U32: True{}\nlaw F: Type -> Type\ntype Bad is F(Type):\n  Bad{}\n',
 'valid-ordinary':'type Good is Data:\n  Good{}\ndef main() -> Good: Good{}\n',
 'valid-quantified':'type Token<q> is Kind(q):\n  Token{}\ndef main() -> Token<&1>: Token{}\n',
}
fd=out/'fixtures';fd.mkdir();cases=[{'id':'check/error_window_stuck_app_kind.bend','lanes':['check']}]
for name,body in fixtures.items():
 p=fd/(name+'.bend');p.write_text('import Base\n'+body);positive=name.startswith('valid-');case={'id':'kind-origin/'+name,'file':str(p),'lanes':['check'],'accept':positive}
 if not positive:case['rejectPhase']='check'
 cases.append(case)
(out/'selection.json').write_text(json.dumps({'cases':cases},indent=2)+'\n')
(out/'manifest.json').write_text(json.dumps({'parent':str(base),'before':ident(base/'src/check/kernel.bend'),'after':ident(out/'project/src/check/kernel.bend'),'patch':ident(patch),'tool':ident(Path(__file__)),'plan':ident(root/'design/phase16/kind-origin-fallback.md'),'fixtures':[ident(p) for p in sorted(fd.glob('*.bend'))]},indent=2)+'\n')
(out/'workflow.json').write_text(json.dumps({'project':str(out/'project'),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'1','jobs':1},indent=2)+'\n');shutil.copy2(__file__,out/'consumed-tool.py');print(out)
