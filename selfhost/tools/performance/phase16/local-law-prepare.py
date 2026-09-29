from pathlib import Path
import difflib,hashlib,json,shutil
root=Path(__file__).resolve().parents[4];phase=root/'selfhost/build/phase16'
base=phase/'wave6-source-01/project';out=phase/'local-law-source-01';out.mkdir();shutil.copytree(base,out/'project')
changes=[]
def replace_file(file,a,b):
 p=out/'project'/file;s=p.read_text();assert s.count(a)==1,(file,a);t=s.replace(a,b);p.write_text(t);changes.append((file,s,t))
old='      u => f_def_prior(f_tx(nameTokens), f_tele(f_tl(rest), ")", Nil{}), book, imports, unsafe, old, nameTokens),'
new='''      u => f_choose(FRawResult, f_def_fillable(old) && f_eq(f_tx(f_skip(f_tl(rest))), "~"),
        u => f_result(book, f_pn(fpe_name_error(f_skip(f_tl(rest)))), imports),
        u => f_def_prior(f_tx(nameTokens), f_tele(f_tl(rest), ")", Nil{}), book, imports, unsafe, old, nameTokens)),'''
replace_file('src/front/declarations.bend',old,new)
p=out/'project/src/front/validate.bend';s=p.read_text();start=s.index('def f_def_prior(');end=s.index('\n\nlaw ',start);old=s[start:end]
new='''def f_def_prior(name, p, book, imports, unsafe, old, nameTokens):
  f_choose(FRawResult, f_eq(tg(f_pn(p)), "Error"), u => f_result(book, f_pn(p), imports),
    u => f_choose(FRawResult, f_eq(dk(old), "Missing"),
      u => f_choose(FRawResult, Bool.not(f_eq(f_alias(name, imports), name)) && f_eq(f_tx(f_pr(p)), "->"),
        u => f_result(book, f_pn(fpe_word(nameTokens, "an import alias can only name a law fill without a return annotation", "a fresh name (" ++ f_import_alias_head(name) ++ " is an import's alias)")), imports),
        u => f_def_base(name, p, book, imports, unsafe)),
      u => f_choose(FRawResult, Bool.not(f_bare_params(ks(f_pn(p)))),
        u => f_result(book, f_pn(fpe_error(f_pr(p), "a law fill requires plain parameter names", "a name")), imports),
        u => f_choose(FRawResult, U32.is_lt(terms_len(ks(f_pn(p))), dx(old)),
          u => f_result(book, f_pn(fpe_error(f_pr(p), "a law fill requires its template parameters", "a name for each ~ clause of the law (" ++ U32.show(dx(old)) ++ ")")), imports),
          u => f_choose(FRawResult, f_eq(f_tx(f_pr(p)), ":"),
            u => f_def_base(name, p, book, imports, unsafe),
            u => f_result(book, f_pn(fpe_error(f_pr(p), "expected : (a definition filling a law has no return annotation)", "':'")), imports))))))'''
replace_file('src/front/validate.bend',old,new)
fixtures={
 'marked':'law F:\n  for ~A: Type\n  Type\ndef F(~A):\n  A\n',
 'short':'law F:\n  for ~A: Type\n  for ~B: Type\n  Type\ndef F(A):\n  A\n',
 'typed':'law F:\n  for ~A: Type\n  Type\ndef F(A: Type):\n  A\n',
 'malformed':'law F:\n  for ~A: Type\n  Type\ndef F(A:):\n  A\n',
 'correct':'law F:\n  for ~A: Type\n  Type\ndef F(A):\n  A\n',
 'trailing-comma':'law F:\n  for ~A: Type\n  Type\ndef F(A,):\n  A\n',
 'ordinary-template':'def F(~A: Type) -> Type:\n  A\n',
 'short-before-arrow':'law F:\n  for ~A: Type\n  for ~B: Type\n  Type\ndef F(A) -> Type:\n  A\n',
}
fd=out/'fixtures';fd.mkdir();cases=[{'id':f'comptime/{n}.bend','lanes':['parse','check']} for n in ['err_law','err_fill_short']]
for name,body in fixtures.items():
 p=fd/(name+'.bend');p.write_text('import Base\n'+body);positive=name in ['correct','trailing-comma','ordinary-template'];case={'id':'local-law/'+name,'file':str(p),'lanes':['parse','check'],'accept':positive}
 if not positive:case['rejectPhase']='parse'
 cases.append(case)
(out/'selection.json').write_text(json.dumps({'cases':cases},indent=2)+'\n')
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
patch=out/'local-law.patch';patch.write_text(''.join(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile=f,tofile=f)) for f,a,b in changes))
(out/'manifest.json').write_text(json.dumps({'parent':str(base),'plan':ident(root/'design/phase16/local-law-parameters.md'),'tool':ident(Path(__file__)),'patch':ident(patch),'changes':[{'path':f,'before':ident(base/f),'after':ident(out/'project'/f)} for f,a,b in changes],'fixtures':[ident(p) for p in sorted(fd.glob('*.bend'))]},indent=2)+'\n')
(out/'workflow.json').write_text(json.dumps({'project':str(out/'project'),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'0','jobs':1},indent=2)+'\n');shutil.copy2(__file__,out/'consumed-tool.py');print(out)
