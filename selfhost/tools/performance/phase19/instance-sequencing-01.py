"""Owned semantic slice: ordered child worlds and direct checked-child output."""
from pathlib import Path
import difflib,hashlib,json,re
ROOT=Path(__file__).resolve().parents[4];P=ROOT/'selfhost/build/phase19/instance-source-01/project';OUT=ROOT/'selfhost/build/phase19/instance-sequencing-edit-01'
def fn(s,name,new):
 m=re.search(r'^def '+name+r'\b',s,re.M);assert m,name
 e=re.search(r'^(?:@unsafe|def |law |type )',s[m.end():],re.M);end=m.end()+e.start() if e else len(s)
 return s[:m.start()]+new.strip()+'\n\n'+s[end:]
path=P/'src/check/kernel.bend';old=path.read_text();s=old
replacements={
'infer_node':'''def infer_node(e, ctx, t, dem, sp):
  kc(KChecking, String.eq(tg(t), "Var"), u => infer_var(e, ctx, t, dem),
   u => kc(KChecking, String.eq(tg(t), "Ref"), u => infer_ref(e, ctx, t, dem, sp, lookup(cb(e), nm(t))),
   u => kc(KChecking, String.eq(tg(t), "Typ"), u => ki_one(t, typ(1), check(e, ctx, kid(t, 0), 0, atom("Qnt"))),
   u => kc(KChecking, String.eq(tg(t), "Qnt"), u => ok(cw(e), t, typ(1), Nil{}),
   u => kc(KChecking, String.eq(tg(t), "Qua"), u => ok(cw(e), t, atom("Qnt"), Nil{}),
   u => kc(KChecking, String.eq(tg(t), "Min"), u => ki_min(e, ctx, t, dem, check(e, ctx, kid(t, 0), dem, atom("Qnt"))),
   u => kc(KChecking, String.eq(tg(t), "All"), u => ki_all(e, ctx, t, dg_kind_check(e, ctx, kid(t, 0), qt(t), nm(t))),
   u => kc(KChecking, String.eq(tg(t), "App"), u => infer_app(e, ctx, t, dem, infer(e, ctx, kid(t, 0), dem, Con{kid(t, 1), sp})),
   u => kc(KChecking, String.eq(tg(t), "ADT"), u => infer_adt(e, ctx, t, dem, lookup(cb(e), nm(t))),
   u => kc(KChecking, String.eq(tg(t), "Eql"), u => ki_eql_type(e, ctx, t, check(e, ctx, kid(t, 2), 0, typ(1))),
   u => kc(KChecking, String.eq(tg(t), "Ann"), u => ki_ann(e, ctx, t, dem, check(e, ctx, kid(t, 1), 0, typ(1))),
   u => kc(KChecking, core_literal(t), u => bad(cw(e), "cannot infer: annotation required"), u => bad(cw(e), kc(String, String.eq(tg(t), "FUnboundVar"), u => "unbound variable", u => "cannot infer: annotation required"))))))))))))))''',
'infer_var':'''def infer_var(e, ctx, t, dem):
  +bound = ctx_get(ctx, ix(t))
  kc(KChecking, String.eq(tg(bound), "Absent"), u => bad(cw(e), "unbound variable"), u => ok(cw(e), k_with_children(t, Nil{}), kid(bound, 0), Con{kt("Use", "", ix(t), dem, Nil{}), Nil{}}))''',
'infer_app':'''def infer_app(e, ctx, t, dem, r):
  kc(KChecking, good(r), u => kc(KChecking, U32.is_gt(rx(r), 0), u => KChecking{ct(r), cy(r), cs(r), "", rw(r), U32.sub(rx(r), 1)}, u => infer_app_type(ke_world(e, rw(r)), ctx, t, dem, r, wnf(kw_book(rw(r)), cy(r)))), u => r)''',
'infer_app_type':'''def infer_app_type(e, ctx, t, dem, r, ty):
  kc(KChecking, String.eq(tg(ty), "All"), u => ki_pair(t, subst(kid(ty, 1), ix(ty), kid(t, 1)), r, check(ke_world(e, rw(r)), ctx, kid(t, 1), qdem(qt(ty), dem), kid(ty, 0)), False{}), u => kr_from(r, dg_bad_detail(rw(r), "application requires a function type", dg_text("a function type"), cy(r))))''',
'infer_adt_done':'''def infer_adt_done(t, r):
  ki_args(t, cy(r), r)''',
'tele_check':'''def tele_check(e, ctx, tel, args, dem):
  match args:
    case Nil{}: ok(cw(e), atom("Args"), tel, Nil{})
    case Con{h, t}: tele_check_cached_head(e, ctx, wnf(cb(e), tel), h, t, dem)''',
'tele_check_head':'''def tele_check_head(e, ctx, tel, h, rest, dem):
  tele_check_cached_head(e, ctx, tel, h, rest, dem)''',
'tele_check_done':'''def tele_check_done(a, b):
  both(a, b, k_with_children(atom("Args"), Con{ct(a), ks(ct(b))}), cy(b), False{})''',
'check_fits':'''def check_fits(e, r, ty):
  kc(KChecking, good(r), u => kc(KChecking, compare(kw_book(rw(r)), cy(r), ty, True{}), u => checked(r, ct(r), ty), u => kr_from(r, dg_bad_detail(rw(r), "type mismatch", ty, cy(r)))), u => r)''',
'check_lam_q':'''def check_lam_q(e, ctx, t, dem, ty, q):
  ki_lam_kind(e, ctx, t, dem, ty, q, kc(KChecking, k_quantity_present(t) && U32.is_eq(qt(t), 2) && U32.is_eq(qt(ty), 1), u => dg_kind_check(e, ctx, kid(ty, 0), q, nm(t)), u => ok(cw(e), t, ty, Nil{})))''',
'check_lam_done':'''def check_lam_done(t, ty, q, r):
  kc(KChecking, good(r), u => kc(KChecking, U32.is_gt(uses_get(cs(r), ix(t)), q), u => kr_from(r, dg_quant_error(rw(r), "affine variable consumed more than allowed", nm(t), q, uses_get(cs(r), ix(t)))), u => KChecking{k_with_children(t, Con{ct(r), Nil{}}), ty, uses_del(cs(r), ix(t)), "", rw(r), rx(r)}), u => r)''',
'check_ctr_found':'''def check_ctr_found(e, ctx, t, dem, ty, ctr):
  kc(KChecking, Bool.not(String.eq(dk(ctr), "Absent")) && Bool.not(has_name(rm(ty), nm(t))) && U32.is_eq(da(ctr), terms_len(ks(t))), u => ki_args(t, ty, tele_check(e, ctx, tele_fill(cb(e), dt(ctr), ks(ty)), ks(t), dem)), u => dg_ctor_error(e, t, ty, ctr))''',
'check_let':'''def check_let(e, outer, ctx, xs, dem, ty, bindings, us, site, out):
  match xs:
    case Nil{}: bad(cw(e), "let has no body")
    case Con{h, rest}:
      kc(KChecking, String.eq(tg(h), "Bind"), u => check_let_value(e, outer, ctx, h, rest, dem, ty, bindings, us, site, out, infer(e, outer, kid(h, 0), qdem(qt(h), dem), Nil{})), u => ki_let_finish(site, out, check_let_done(e, outer, check(e, ctx, let_cells(h, bindings), dem, ty), bindings, us)))''',
'check_let_value':'''def check_let_value(e, outer, ctx, h, rest, dem, ty, bindings, us, site, out, r):
  kc(KChecking, good(r), u => check_let_kind(ke_world(e, rw(r)), outer, ctx, h, rest, dem, ty, bindings, us, site, out, r, dg_kind_at(ke_world(e, rw(r)), outer, cy(r), qt(h), nm(h), h)), u => r)''',
'check_let_kind':'''def check_let_kind(e, outer, ctx, h, rest, dem, ty, bindings, us, site, out, r, k):
  kc(KChecking, good(k), u => check_let(ke_world(e, rw(k)), outer, ctx_bind(ctx, ix(h), qt(h), nm(h), cy(r)), rest, dem, ty, Con{h, bindings}, uses_merge(us, cs(r), False{}), site, Con{k_with_children(h, Con{ct(r), Nil{}}), out}), u => k)''',
'check_rwt':'''def check_rwt(e, ctx, t, dem, ty, r):
  kc(KChecking, good(r), u => check_rwt_type(ke_world(e, rw(r)), ctx, t, dem, ty, r, wnf(kw_book(rw(r)), cy(r))), u => r)''',
'check_rwt_goal':'''def check_rwt_goal(e, ctx, t, dem, ty, r, eq, fresh):
  +goal = all(1, "_", fresh, kid(eq, 2), all(1, "e", U32.add(fresh, 1), kt("Eql", "", 0, 0, Con{kid(eq, 0), Con{var("_", fresh), Con{kid(eq, 2), Nil{}}}}), typ(1)))
  +next = ke_world(e, kw_temporary(cw(e), goal, U32.add(fresh, 1)))
  ki_rwt_motive(next, ctx, t, dem, ty, r, eq, check(next, ctx, kid(t, 1), 0, goal))''',
'check_ctors_next':'''def check_ctors_next(e, d, rest, kind, err):
  kc(KChecking, good(err), u => check_ctors(ke_world(e, rw(err)), d, rest, kind), u => err)''',
'check_ctor_domain':'''def check_ctor_domain(e, d, tel, kind, params, fields, ctx, args, r):
  kc(KChecking, good(r), u => check_ctor_tel(ke_world(e, rw(r)), d, kid(tel, 1), kc(KTerm, U32.is_eq(params, 0), u => kind, u => subst(kid(wnf(kw_book(rw(r)), kind), 1), ix(wnf(kw_book(rw(r)), kind)), var(nm(tel), ix(tel)))), kc(U32, U32.is_eq(params, 0), u => 0, u => U32.sub(params, 1)), kc(U32, U32.is_eq(params, 0), u => U32.sub(fields, 1), u => fields), ctx_bind(ctx, ix(tel), qt(tel), nm(tel), kid(tel, 0)), kc(List<&2, KTerm>, U32.is_eq(params, 0), u => args, u => norm_join(args, Con{var(nm(tel), ix(tel)), Nil{}}))), u => r)''',
'template_arg_done':'''def template_arg_done(e, ty, h, rest, n, r):
  kc(KChecking, good(r), u => template_args(ke_world(e, rw(r)), subst(kid(ty, 1), ix(ty), h), rest, U32.sub(n, 1)), u => r)''',
'tele_check_static':'''def tele_check_static(e, ctx, tel, args, dem):
  match args:
    case Nil{}: ok(cw(e), atom("Args"), tel, Nil{})
    case Con{h, rest}:
      kc(KChecking, String.eq(tg(tel), "All"), u => ki_tele_static(e, ctx, tel, rest, dem, check(e, ctx, h, qdem(qt(tel), dem), kid(tel, 0))), u => tele_check(e, ctx, tel, args, dem))''',
'tele_check_legacy_head':'''def tele_check_legacy_head(e, ctx, tel, h, rest, dem):
  kc(KChecking, String.eq(tg(tel), "All"), u => ki_tele_legacy(e, ctx, tel, h, rest, dem, check(e, ctx, h, qdem(qt(tel), dem), kid(tel, 0))), u => bad(cw(e), "too many telescope arguments"))''',
'tele_check_after_head':'''def tele_check_after_head(e, ctx, tel, h, rest, dem, checked_head):
  kc(KChecking, good(checked_head), u => kc(KChecking, core_subst_stable(kid(tel, 1)),
    u => tele_check_done(checked_head, tele_check_static(ke_world(e, rw(checked_head)), ctx, kid(tel, 1), rest, dem)),
    u => tele_check_done(checked_head, tele_check_legacy(ke_world(e, rw(checked_head)), ctx, subst(kid(tel, 1), ix(tel), h), rest, dem))), u => checked_head)''',
'check_mat_filled':'''def check_mat_filled(e, ctx, t, dem, ty, a, ctr, tel):
  ki_match_arm(e, ctx, t, dem, ty, a, check(mat_lhs(e, nm(t), tel, da(ctr), Con{t, Con{ty, ctx}}), ctx, kid(t, 0), dem, mat_goal(cb(e), ty, tel, da(ctr), nm(t), Nil{})))''',
}
for name,new in replacements.items():s=fn(s,name,new)
s=s.replace('check_let(e, ctx, ctx, ks(t), dem, ty, Nil{}, Nil{})','check_let(e, ctx, ctx, ks(t), dem, ty, Nil{}, Nil{}, t, Nil{})')
for name in ['check_let','check_let_value','check_let_kind']:
 m=re.search(r'^law '+name+r':\n(?:(?:  .*|)\n)*?  KChecking\n',s,re.M);assert m,name
 b=m[0];at=b.index('  for +r:') if '  for +r:' in b else b.index('  KChecking')
 s=s[:m.start()]+b[:at]+'  for +site: KTerm\n  for +out: List<&2,KTerm>\n'+b[at:]+s[m.end():]
s+='''@unsafe
def ki_one(+t: KTerm, +ty: KTerm, +r: KChecking) -> KChecking:
  kc(KChecking, good(r), u => checked(r, k_with_children(t, [ct(r)]), ty), u => r)

@unsafe
def ki_pair(+t: KTerm, +ty: KTerm, +a: KChecking, +b: KChecking, +join: Bool) -> KChecking:
  both(a, b, k_with_children(t, [ct(a), ct(b)]), ty, join)

@unsafe
def ki_args(+t: KTerm, +ty: KTerm, +r: KChecking) -> KChecking:
  kc(KChecking, good(r), u => checked(r, k_with_children(t, ks(ct(r))), ty), u => r)

@unsafe
def ki_min(+e: KEnv, +ctx: List<&2,KTerm>, +t: KTerm, +dem: U32, +a: KChecking) -> KChecking:
  kc(KChecking, good(a), u => ki_pair(t, atom("Qnt"), a, check(ke_world(e, rw(a)), ctx, kid(t, 1), dem, atom("Qnt")), False{}), u => a)

@unsafe
def ki_all(+e: KEnv, +ctx: List<&2,KTerm>, +t: KTerm, +a: KChecking) -> KChecking:
  kc(KChecking, good(a), u => ki_pair(t, typ(1), a, check(ke_world(e, rw(a)), ctx_bind(ctx, ix(t), qt(t), nm(t), kid(t, 0)), kid(t, 1), 0, typ(1)), False{}), u => a)

@unsafe
def ki_eql_type(+e: KEnv, +ctx: List<&2,KTerm>, +t: KTerm, +a: KChecking) -> KChecking:
  kc(KChecking, good(a), u => ki_eql_left(ke_world(e, rw(a)), ctx, t, a, check(ke_world(e, rw(a)), ctx, kid(t, 0), 0, kid(t, 2))), u => a)

@unsafe
def ki_eql_left(+e: KEnv, +ctx: List<&2,KTerm>, +t: KTerm, +a: KChecking, +b: KChecking) -> KChecking:
  kc(KChecking, good(b), u => ki_eql_done(t, a, b, check(ke_world(e, rw(b)), ctx, kid(t, 1), 0, kid(t, 2))), u => b)

@unsafe
def ki_eql_done(+t: KTerm, +a: KChecking, +b: KChecking, +c: KChecking) -> KChecking:
  both(a, both(b, c, t, typ(2), False{}), k_with_children(t, [ct(b), ct(c), ct(a)]), typ(2), False{})

@unsafe
def ki_ann(+e: KEnv, +ctx: List<&2,KTerm>, +t: KTerm, +dem: U32, +a: KChecking) -> KChecking:
  kc(KChecking, good(a), u => ki_ann_done(t, a, check(ke_world(e, rw(a)), ctx, kid(t, 0), dem, kid(t, 1))), u => a)

@unsafe
def ki_ann_done(+t: KTerm, +a: KChecking, +b: KChecking) -> KChecking:
  both(a, b, k_with_children(t, [ct(b), kid(t, 1)]), kid(t, 1), False{})

@unsafe
def ki_lam_kind(+e: KEnv, +ctx: List<&2,KTerm>, +t: KTerm, +dem: U32, +ty: KTerm, +q: U32, +r: KChecking) -> KChecking:
  kc(KChecking, good(r), u => check_lam_done(t, ty, q, check(lhs_step(ke_world(e, rw(r)), var(nm(t), ix(t))), ctx_bind(ctx, ix(t), q, nm(t), kid(ty, 0)), kid(t, 0), dem, subst(kid(ty, 1), ix(ty), var(nm(t), ix(t))))), u => r)

@unsafe
def ki_reverse_terms(+xs: List<&2,KTerm>, +out: List<&2,KTerm>) -> List<&2,KTerm>:
  match xs:
    case Nil{}: out
    case Con{h, rest}: ki_reverse_terms(rest, Con{h, out})

@unsafe
def ki_let_finish(+site: KTerm, +out: List<&2,KTerm>, +r: KChecking) -> KChecking:
  kc(KChecking, good(r), u => checked(r, k_with_children(site, ki_reverse_terms(out, [ct(r)])), cy(r)), u => r)

@unsafe
def ki_tele_static(+e: KEnv, +ctx: List<&2,KTerm>, +tel: KTerm, +rest: List<&2,KTerm>, +dem: U32, +r: KChecking) -> KChecking:
  kc(KChecking, good(r), u => tele_check_done(r, tele_check_static(ke_world(e, rw(r)), ctx, kid(tel, 1), rest, dem)), u => r)

@unsafe
def ki_tele_legacy(+e: KEnv, +ctx: List<&2,KTerm>, +tel: KTerm, +h: KTerm, +rest: List<&2,KTerm>, +dem: U32, +r: KChecking) -> KChecking:
  kc(KChecking, good(r), u => tele_check_done(r, tele_check_legacy(ke_world(e, rw(r)), ctx, subst(kid(tel, 1), ix(tel), h), rest, dem)), u => r)

@unsafe
def ki_match_arm(+e: KEnv, +ctx: List<&2,KTerm>, +t: KTerm, +dem: U32, +ty: KTerm, +a: KTerm, +r: KChecking) -> KChecking:
  kc(KChecking, good(r), u => ki_pair(t, ty, r, check(ke_world(e, rw(r)), ctx, mat_rest(kw_book(rw(r)), t, a), dem, all(qt(ty), nm(ty), ix(ty), KTerm{tg(a), nm(a), ix(a), qt(a), ks(a), Con{nm(t), rm(a)}, kb(a), ke(a)}, kid(ty, 1))), True{}), u => r)

@unsafe
def ki_rwt_motive(+e: KEnv, +ctx: List<&2,KTerm>, +t: KTerm, +dem: U32, +ty: KTerm, +r: KChecking, +eq: KTerm, +motive: KChecking) -> KChecking:
  kc(KChecking, good(motive), u => kc(KChecking, compare(kw_book(rw(motive)), kapply(kapply(kid(t, 1), kid(eq, 1)), kid(t, 0)), ty, True{}),
    u => ki_rwt_done(t, ty, r, motive, check(ke_world(e, rw(motive)), ctx, kid(t, 2), dem, kapply(kapply(kid(t, 1), kid(eq, 0)), atom("Rfl")))),
    u => kr_from(motive, dg_bad_detail(rw(motive), "rewrite motive does not fit goal", ty, kapply(kapply(kid(t, 1), kid(eq, 1)), kid(t, 0))))), u => motive)

@unsafe
def ki_rwt_done(+t: KTerm, +ty: KTerm, +r: KChecking, +motive: KChecking, +body: KChecking) -> KChecking:
  both(r, body, k_with_children(t, [ct(r), ct(motive), ct(body)]), ty, False{})
'''
OUT.mkdir();(OUT/'kernel.patch').write_text(''.join(difflib.unified_diff(old.splitlines(True),s.splitlines(True),fromfile='before/src/check/kernel.bend',tofile='after/src/check/kernel.bend')));path.write_text(s)
(OUT/'manifest.json').write_text(json.dumps({'kind':'phase19-sequencing-edit','complete':True,'file':str(path),'before':hashlib.sha256(old.encode()).hexdigest(),'after':hashlib.sha256(s.encode()).hexdigest(),'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'scope':'Intermediate shared source; mint/fresh helpers are still pending. No build.'},indent=2)+'\n')
print(json.dumps({'complete':True,'deltaLines':len(s.splitlines())-len(old.splitlines())}))
