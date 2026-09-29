from pathlib import Path
import shutil,json,hashlib,difflib
root=Path.cwd();base=root/'selfhost';old=base/'build/phase16/checker-source-03/project';out=base/'build/phase16/checker-source-04';out.mkdir();shutil.copytree(old,out/'project');project=out/'project'
def replace(s,a,b):assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
p=project/'src/check/kernel.bend';s=p.read_text();s=replace(s,'dn(d) ++ "~" ++ nm(ty) ++ U32.show(ix(ty))','dn(d) ++ "~" ++ nm(ty)')
a='  check_template_definition(book_put(book, KDef{name, "Def", 0, 0, kid(ty, 0), atom("Absent"), Nil{}, True{}, False{}}), d, subst(kid(ty, 1), ix(ty), ref(name)), kapply(body, ref(name)), app(lhs, ref(name)), U32.sub(n, 1))'
s=replace(s,a,'  kc(KChecked, String.eq(dk(lookup(book, name)), "Absent"), u => '+a.strip()+', u => dg_trace(KEnv{book, "", ref(dn(d)), 0, Nil{}, du(d)}, Nil{}, ty, atom("Absent"), dg_bad_detail("duplicate comptime binder", dg_text("a fresh ~ binder name"), dg_text(nm(ty)))))')
start=s.index('def check_rwt_goal(');end=s.index('\n\n',start)
s=s[:start]+'''def check_rwt_goal(e, ctx, t, dem, ty, r, eq, fresh):
  +motive = check(e, ctx, kid(t, 1), 0, all(1, "_", fresh, kid(eq, 2), all(1, "e", U32.add(fresh, 1), kt("Eql", "", 0, 0, Con{kid(eq, 0), Con{var("_", fresh), Con{kid(eq, 2), Nil{}}}}), typ(1))))
  kc(KChecked, good(motive), u => kc(KChecked, compare(cb(e), kapply(kapply(kid(t, 1), kid(eq, 1)), kid(t, 0)), ty, True{}),
   u => both(r, both(motive, check(e, ctx, kid(t, 2), dem, kapply(kapply(kid(t, 1), kid(eq, 0)), atom("Rfl"))), t, ty, False{}), t, ty, False{}),
   u => dg_bad_detail("rewrite motive does not fit goal", ty, kapply(kapply(kid(t, 1), kid(eq, 1)), kid(t, 0)))), u => motive)'''+s[end:]
p.write_text(s)
name='src/check/kernel.bend';before=(old/name).read_bytes();after=(project/name).read_bytes();changes=[{'file':name,'beforeSha256':hashlib.sha256(before).hexdigest(),'afterSha256':hashlib.sha256(after).hexdigest(),'physicalLineDelta':len(after.splitlines())-len(before.splitlines()),'byteDelta':len(after)-len(before)}];(out/'src_check_kernel.bend.patch').write_text(''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile=name,tofile=name)))
(out/'manifest.json').write_text(json.dumps({'kind':'phase16-local-checker-order-candidate','parentSource':'checker-source-03','changes':changes,'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'plan':str(root/'design/phase16/checker-ordering.md')},indent=2)+'\n');(out/'config.json').write_text(json.dumps({'project':str(project),'upstream':str(base/'.bootstrap/upstream-phase8'),'profile':'equality','cpu':'1','jobs':1},indent=2)+'\n');print(out)
