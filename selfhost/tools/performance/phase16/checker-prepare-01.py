from pathlib import Path
import shutil,json,hashlib,difflib
root=Path.cwd();base=root/'selfhost';out=base/'build/phase16/checker-source-01';out.mkdir(parents=True);project=out/'project'
for name in ['src','tests/frontend/phase2-rules']:shutil.copytree(base/name,project/name)
for name in ['conformance','development']:
 for p in (base/'tools'/name).rglob('*.mjs'):
  q=project/p.relative_to(base);q.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,q)
for name in ['typed-driver','stage0-library','assemble','compiler-abi','native-build','node-resource-args']:shutil.copyfile(base/'tools'/f'{name}.mjs',project/'tools'/f'{name}.mjs')
(project/'dist').mkdir()
def replace(s,a,b):assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
p=project/'src/check/kernel.bend';s=p.read_text()
# Preserve the existing typed result instead of projecting it through String.
for name in ['check_foreign','check_adt_declaration','check_ctors','check_ctors_next','check_ctor_tel','check_ctor_head','check_ctor_domain']:
 start=s.index('law '+name+':');end=s.index('\n\n',start);part=s[start:end].replace('for +err: String','for +err: KChecked');assert part.endswith('  String');s=s[:start]+part[:-len('  String')]+'  KChecked'+s[end:]
s=replace(s,'  # Legacy ADT/foreign checks use empty ce as success; good(bad("")) is True.\n','')
s=replace(s,'u => bad(check_adt_declaration(e, d))','u => check_adt_declaration(e, d)')
s=replace(s,'u => bad(check_foreign(book, d))','u => check_foreign(book, d)')
s=replace(s,'  kc(String, U32.is_eq(dx(d), 0) && String.eq(tg(foreign_head(foreign_tip(dt(d)))), "Ref") && String.eq(nm(foreign_head(foreign_tip(dt(d)))), "IO") && String.eq(dk(lookup(book, "IO")), "Def") && db(lookup(book, "IO")), u => "", u => "foreign definition must return base IO directly")',
'''  kc(KChecked, U32.is_eq(dx(d), 0) && String.eq(tg(foreign_head(foreign_tip(dt(d)))), "Ref") && String.eq(nm(foreign_head(foreign_tip(dt(d)))), "IO") && String.eq(dk(lookup(book, "IO")), "Def") && db(lookup(book, "IO")), u => bad(""), u => dg_trace(KEnv{book, dn(d), ref(dn(d)), 0, Nil{}, du(d)}, Nil{}, foreign_tip(dt(d)), atom("Absent"), dg_bad_detail("foreign definition must return base IO directly", dg_text("a foreign definition returning base IO(...) directly (return type aliases are not unfolded)"), dg_text(dn(d)))))''')
s=replace(s,'  kc(String, String.eq(tg(tele_tip(cb(e), dt(d))), "Typ"), u => check_ctors(e, d, dc(d), dt(d)), u => "datatype declaration must return a kind")',
'''  check_adt_kind(e, d, dt(d), Nil{})

@unsafe
def check_adt_kind(+e: KEnv, +d: KDef, +tel: KTerm, +ctx: List<&2, KTerm>) -> KChecked:
  check_adt_kind_head(e, d, wnf(cb(e), tel), ctx)

@unsafe
def check_adt_kind_head(+e: KEnv, +d: KDef, +tel: KTerm, +ctx: List<&2, KTerm>) -> KChecked:
  kc(KChecked, String.eq(tg(tel), "All"), u => check_adt_kind(e, d, kid(tel, 1), ctx_bind(ctx, ix(tel), qt(tel), nm(tel), kid(tel, 0))), u => kc(KChecked, String.eq(tg(tel), "Typ"), u => check_ctors(e, d, dc(d), dt(d)), u => dg_trace(e, ctx, tel, atom("Absent"), dg_bad_detail("datatype declaration must return a kind", dg_text("a kind (type " ++ dn(d) ++ "<..> is Kind(g))"), tel))))''')
s=replace(s,'def check_ctors(e, d, ctrs, kind):\n  match ctrs:\n    case Nil{}:\n      ""','def check_ctors(e, d, ctrs, kind):\n  match ctrs:\n    case Nil{}:\n      bad("")')
s=replace(s,'check_ctor_tel(e, d, dt(h), kind, da(d), da(h), Nil{}, Nil{})','check_ctor_tel(KEnv{cb(e), dn(h), ref(dn(h)), 0, Nil{}, cu(e)}, d, dt(h), kind, da(d), da(h), Nil{}, Nil{})')
s=replace(s,'  kc(String, String.eq(err, ""), u => check_ctors(e, d, rest, kind), u => err)','  kc(KChecked, good(err), u => check_ctors(e, d, rest, kind), u => err)')
s=replace(s,'  kc(String, U32.is_eq(U32.add(params, fields), 0), u => kc(String, compare(cb(e), tel, kt("ADT", dn(d), 0, 0, args), False{}), u => "", u => "constructor result must apply family to its parameters"), u => check_ctor_head(e, d, wnf(cb(e), tel), kind, params, fields, ctx, args))','  kc(KChecked, U32.is_eq(U32.add(params, fields), 0), u => kc(KChecked, compare(cb(e), tel, kt("ADT", dn(d), 0, 0, args), False{}), u => bad(""), u => dg_trace(e, ctx, tel, atom("Absent"), dg_bad_detail("constructor result must apply family to its parameters", dg_text("a telescope tipped at " ++ dn(d) ++ " applied to its own parameters"), tel))), u => check_ctor_head(e, d, wnf(cb(e), tel), kind, params, fields, ctx, args))')
s=replace(s,'  kc(String, String.eq(tg(tel), "All"), u => check_ctor_domain(e, d, tel, kind, params, fields, ctx, args, check(e, ctx, kid(tel, 0), 0, kc(KTerm, U32.is_eq(params, 0) && U32.is_eq(qt(tel), 1), u => kind, u => typ(qt(tel))))), u => "constructor telescope missing a binder")','  kc(KChecked, String.eq(tg(tel), "All"), u => check_ctor_domain(e, d, tel, kind, params, fields, ctx, args, check(e, ctx, kid(tel, 0), 0, kc(KTerm, U32.is_eq(params, 0) && U32.is_eq(qt(tel), 1), u => kind, u => typ(qt(tel))))), u => bad("constructor telescope missing a binder"))')
start=s.index('def check_ctor_domain(');end=s.index('\n\n',start);part=s[start:end].replace('kc(String, good(r)','kc(KChecked, good(r)').replace('u => ce(r))','u => r)');s=s[:start]+part+s[end:]
# Caller context is needed only for the upstream captured-variable catch.
for name in ['infer_ref','infer_template']:
 start=s.index('law '+name+':');pos=s.index('  for +e: KEnv\n',start)+len('  for +e: KEnv\n');s=s[:pos]+'  for +ctx: List<&2, KTerm>\n'+s[pos:]
s=s.replace('infer_ref(e, t, dem, sp,','infer_ref(e, ctx, t, dem, sp,').replace('infer_template(e, t, dem, sp,','infer_template(e, ctx, t, dem, sp,')
s=replace(s,'u => checked(template_args(e, dt(d), sp, dx(d)), t, dt(d))','u => checked(dg_template_result(e, ctx, t, template_args(e, dt(d), sp, dx(d))), t, dt(d))')
s=replace(s,'u => bad("template argument is open or ill-typed"))','u => r)')
# Shared kind wrapper is the same check; it annotates only a direct mismatch.
s=replace(s,'check(e, ctx, kid(t, 0), 0, typ(kindq(e, qt(t))))','dg_kind_check(e, ctx, kid(t, 0), qt(t), nm(t))')
s=replace(s,'check(e, ctx, kid(ty, 0), 0, typ(kindq(e, q)))','dg_kind_check(e, ctx, kid(ty, 0), q, nm(t))')
p.write_text(s)
p=project/'src/diagnostic/trace.bend';s=p.read_text();start=s.index('@unsafe\ndef dg_typeless(');end=s.index('@unsafe\ndef dg_trace(',start);s=s[:start]+s[end:]
s=s.replace('dg_typeless(cb(e), ctx, t)','dg_text("non-inferrable term")')
s=replace(s,'kt("DTrail", "", 0, 0, norm_join(ks(kid(ct(r), 4)), [t]))]','kt("DTrail", "", 0, 0, norm_join(ks(kid(ct(r), 4)), [t])), kid(ct(r), 5)]')
s=replace(s,'kt("DTrail", "", 0, 0, [t])]','kt("DTrail", "", 0, 0, [t]), dg_text(kc(String, String.eq(ce(r), "constructor requires a datatype goal") && String.eq(dk(lookup(cb(e), nm(t))), "ADT"), u => nm(t) ++ " is a datatype: write its arguments as <>", u => ""))]')
s=replace(s,'nm(ct(r)), DNoSpan{}, "", ks(kid(ct(r), 4))','nm(ct(r)), DNoSpan{}, nm(kid(ct(r), 5)), ks(kid(ct(r), 4))')
s+='''
# Keep the original closed-argument error, except an actual caller variable.
@unsafe
def dg_template_result(+e: KEnv, +ctx: List<&2, KTerm>, +t: KTerm, +r: KChecked) -> KChecked:
  kc(KChecked, String.eq(ce(r), "unbound variable") && String.eq(tg(ct(r)), "DTrace") && String.eq(tg(kid(ct(r), 1)), "Var") && Bool.not(String.eq(tg(ctx_get(ctx, ix(kid(ct(r), 1)))), "Absent")), u => dg_trace(e, ctx, t, atom("Absent"), dg_bad_detail(ce(r), dg_text("a template applied to closed ~ arguments (" ++ nm(kid(ct(r), 1)) ++ " is a variable here, not comptime: pass it at run time)"), t)), u => r)

@unsafe
def dg_kind_check(+e: KEnv, +ctx: List<&2, KTerm>, +t: KTerm, +q: U32, +name: String) -> KChecked:
  dg_kind_result(t, q, name, typ(kindq(e, q)), check(e, ctx, t, 0, typ(kindq(e, q))))

@unsafe
def dg_kind_result(+t: KTerm, +q: U32, +name: String, +kind: KTerm, +r: KChecked) -> KChecked:
  kc(KChecked, U32.is_eq(q, 2) && String.eq(ce(r), "type mismatch") && String.eq(tg(ct(r)), "DTrace") && norm_exact(kid(ct(r), 0), kind) && norm_exact(kid(ct(r), 3), t), u => KChecked{kt("DTrace", nm(ct(r)), ix(ct(r)), qt(ct(r)), [kid(ct(r), 0), kid(ct(r), 1), kid(ct(r), 2), kid(ct(r), 3), kid(ct(r), 4), dg_text("+" ++ name ++ " can be used many times, so its type must be Data.")]), cy(r), cs(r), ce(r)}, u => r)
'''
p.write_text(s)
changes=[]
for name in ['src/check/kernel.bend','src/diagnostic/trace.bend']:
 before=(base/name).read_bytes();after=(project/name).read_bytes();changes.append({'file':name,'beforeSha256':hashlib.sha256(before).hexdigest(),'afterSha256':hashlib.sha256(after).hexdigest(),'physicalLineDelta':len(after.splitlines())-len(before.splitlines()),'byteDelta':len(after)-len(before)});(out/(name.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile=name,tofile=name)))
(out/'manifest.json').write_text(json.dumps({'kind':'phase16-checker-diagnostic-candidate','changes':changes,'plan':str(root/'design/phase16/checker-diagnostics.md'),'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n')
(out/'config.json').write_text(json.dumps({'project':str(project),'upstream':str(base/'.bootstrap/upstream-phase8'),'profile':'equality','cpu':'2','jobs':1},indent=2)+'\n')
print(out)
