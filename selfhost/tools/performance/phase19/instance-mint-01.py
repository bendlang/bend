"""Replace contextual specialization with the shared live checker and output data."""
from pathlib import Path
import difflib,hashlib,json,re
ROOT=Path(__file__).resolve().parents[4];P=ROOT/'selfhost/build/phase19/instance-source-01/project';OUT=ROOT/'selfhost/build/phase19/instance-mint-edit-01'
def fn(s,name,new):
 m=re.search(r'^def '+name+r'\b',s,re.M);assert m,name
 e=re.search(r'^(?:@unsafe|def |law |type )',s[m.end():],re.M);end=m.end()+e.start() if e else len(s)
 return s[:m.start()]+new.strip()+'\n\n'+s[end:]
paths=['src/check/kernel.bend','src/check/specialize.bend','src/diagnostic/trace.bend'];before={n:(P/n).read_text()for n in paths};files=dict(before)
s=files[paths[0]]
s=fn(s,'infer_ref','''def infer_ref(e, ctx, t, dem, sp, d):
  kc(KChecking, String.eq(dk(d), "Absent"), u => bad(cw(e), "undefined name"),
   u => kc(KChecking, String.eq(dk(d), "ADT") && U32.is_gt(da(d), 0), u => bad(cw(e), "a family requires angle-bracket parameters"),
   u => kc(KChecking, U32.is_eq(dem, 0), u => ok(cw(e), t, dt(d), Nil{}),
   u => kc(KChecking, String.eq(dk(d), "Def") && String.eq(tg(dv(d)), "Absent") && Bool.not(String.eq(nm(t), cn(e))) && ((Bool.not(db(d)) && Bool.not(cu(e))) || (U32.is_gt(dx(d), 0) && U32.is_eq(dx(lookup(cb(e), cn(e))), 0))), u => bad(cw(e), "live use of an unfilled law"),
   u => ki_ref_result(e, t, sp, infer_template(e, ctx, t, dem, sp, d))))))''')
s=fn(s,'infer_template','''def infer_template(e, ctx, t, dem, sp, d):
  kc(KChecking, U32.is_eq(dem, 0) || U32.is_eq(dx(d), 0) || U32.is_gt(dx(lookup(cb(e), cn(e))), 0), u => ok(cw(e), t, dt(d), Nil{}), u => sp_live_checked(e, ctx, t, sp, d, dg_template_result(e, ctx, t, template_args(e, dt(d), sp, dx(d)))))''')
s=fn(s,'check_rwt_type','''def check_rwt_type(e, ctx, t, dem, ty, r, eq):
  kc(KChecking, String.eq(tg(eq), "Eql"), u => ki_rwt_bound(e, ctx, t, dem, ty, r, eq, kw_temp_floor(cw(e), [t, ty, cl(e)])), u => dg_trace(e, ctx, kid(t, 0), ty, kr_from(r, dg_bad_detail(rw(r), "rewrite requires equality evidence", dg_text("an equation {a == b : T}"), cy(r)))))''')
s=fn(s,'mat_lhs','''def mat_lhs(e, name, tel, n, avoid):
  kc(KEnv, U32.is_eq(cp(e), 0), u => e, u => ki_lhs(e, name, tel, n, U32.add(1, kw_temp_floor(cw(e), Con{cl(e), Con{tel, avoid}}))))''')
s=fn(s,'check_mat_filled','''def check_mat_filled(e, ctx, t, dem, ty, a, ctr, tel):
  ki_match_bound(e, ctx, t, dem, ty, a, ctr, tel, kw_temp_floor(cw(e), Con{cl(e), Con{tel, Con{t, Con{ty, ctx}}}}))''')
s+='''@unsafe
def ki_ref_result(+e: KEnv, +t: KTerm, +sp: List<&2,KTerm>, +r: KChecking) -> KChecking:
  kc(KChecking, good(r), u => kc(KChecking, String.eq(nm(ct(r)), cn(e)) && Bool.not(cu(e)) && Bool.not(descend_spine(cq(e), sp_drop(sp, rx(r)), unargs(cl(e), Nil{}))), u => kr_from(r, bad(rw(r), "nondecreasing self-call")), u => r), u => r)

@unsafe
def kw_floor_fresh(+world: KWorld, +fresh: KWorldFresh, +roots: List<&2,KTerm>) -> U32:
  match fresh:
    case KFreshKnown{next}: norm_max_walk(roots, U32.sub(next, 1))
    case KFreshDeferred{saved}: norm_max_walk(roots, norm_max_walk(saved, norm_book_bound(kw_book(world))))

@unsafe
def kw_mint_floor(+world: KWorld, +roots: List<&2,KTerm>) -> U32:
  kw_floor_fresh(world, kw_fresh(world), roots)

@unsafe
def kw_temp_floor(+world: KWorld, +roots: List<&2,KTerm>) -> U32:
  kw_temp_fresh(world, kw_fresh(world), roots)

@unsafe
def kw_temp_fresh(+world: KWorld, +fresh: KWorldFresh, +roots: List<&2,KTerm>) -> U32:
  match fresh:
    case KFreshKnown{next}: norm_max_walk(roots, U32.sub(next, 1))
    case KFreshDeferred{saved}: norm_max_walk(roots, norm_book_bound(kw_book(world)))

@unsafe
def kw_bound_book(+book: List<&2,KDef>, +bound: U32) -> List<&2,KDef>:
  match book:
    case Nil{}: book_cached(book, bound)
    case Con{h, rest}:
      kc(List<&2,KDef>, String.eq(dk(h), "BookCache"), u => Con{KDef{dn(h), dk(h), norm_max(da(h), bound), dx(h), dt(h), dv(h), dc(h), db(h), du(h)}, rest}, u => book_cached(book, bound))

@unsafe
def kw_temporary(+world: KWorld, +root: KTerm, +bound: U32) -> KWorld:
  kw_temporary_fresh(world, root, bound, kw_fresh(world))

@unsafe
def kw_temporary_fresh(+world: KWorld, +root: KTerm, +bound: U32, +fresh: KWorldFresh) -> KWorld:
  match fresh:
    case KFreshKnown{next}: KWorld{kw_bound_book(kw_book(world), bound), kw_memo(world), KFreshKnown{norm_max(next, U32.add(bound, 1))}, kw_checked(world)}
    case KFreshDeferred{roots}: KWorld{kw_book(world), kw_memo(world), KFreshDeferred{Con{root, roots}}, kw_checked(world)}

@unsafe
def ki_rwt_bound(+e: KEnv, +ctx: List<&2,KTerm>, +t: KTerm, +dem: U32, +ty: KTerm, +r: KChecking, +eq: KTerm, +bound: U32) -> KChecking:
  kc(KChecking, U32.is_le(bound, 4294967292), u => check_rwt_goal(e, ctx, t, dem, ty, r, eq, U32.add(bound, 1)), u => kr_from(r, bad(rw(r), "fresh binder space exhausted")))

@unsafe
def ki_lhs(+e: KEnv, +name: String, +tel: KTerm, +n: U32, +fresh: U32) -> KEnv:
  +lhs = lhs_ext(cl(e), name, tel, n, Nil{}, fresh)
  KEnv{kc(KWorld, U32.is_eq(n, 0), u => cw(e), u => kw_temporary(cw(e), lhs, U32.sub(U32.add(fresh, n), 1))), cn(e), lhs, U32.add(U32.sub(cp(e), 1), n), cq(e), cu(e), cd(e)}

@unsafe
def ki_match_bound(+e: KEnv, +ctx: List<&2,KTerm>, +t: KTerm, +dem: U32, +ty: KTerm, +a: KTerm, +ctr: KDef, +tel: KTerm, +bound: U32) -> KChecking:
  kc(KChecking, U32.is_eq(cp(e), 0) || U32.is_eq(da(ctr), 0) || (U32.is_lt(da(ctr), 4294967295) && U32.is_le(bound, U32.sub(4294967294, da(ctr)))),
    u => ki_match_arm(e, ctx, t, dem, ty, a, check(mat_lhs(e, nm(t), tel, da(ctr), Con{t, Con{ty, ctx}}), ctx, kid(t, 0), dem, mat_goal(cb(e), ty, tel, da(ctr), nm(t), Nil{}))),
    u => bad(cw(e), "fresh binder space exhausted"))
'''
files[paths[0]]=s

oldspec=files[paths[1]];lines=oldspec.splitlines(True);starts=[]
for i,line in enumerate(lines):
 m=re.match(r'^(type|law|def)\s+([^\s(:]+)',line)
 if m: starts.append((i,m[1],m[2]))
keep={'KChecked','KSpecialized','KSpecMemo','specialized_book','specialized_error','specialized_diagnostic','sp_payload_error','sp_payload_term','sp_mtemplate','sp_mkey','sp_mname','sp_active','sp_len','term_key','sp_keys','sp_find','sp_ordinal','sp_done_memo','sp_take','sp_take_next','sp_drop','sp_drop_next','sp_shift','sp_shifts','sp_apply_template'}
out=['import Base\n\n# Live instances use the ordinary checker. Output assembly only selects completed data.\n\n']
retired=[]
for j,(start,kind,name) in enumerate(starts):
 end=starts[j+1][0] if j+1<len(starts) else len(lines)
 while end>start and (not lines[end-1].strip() or lines[end-1].startswith('#') or lines[end-1].strip()=='@unsafe'):end-=1
 if name in keep or name.startswith('sk_'):
  if kind=='def':out.append('@unsafe\n')
  out.append(''.join(lines[start:end]).rstrip()+'\n\n')
 else:retired.append({'kind':kind,'name':name,'lines':end-start})
s=''.join(out)
s+='''@unsafe
def sp_assembled(+world: KWorld) -> List<&2,KDef>:
  book_final_reverse(kw_checked(world), Nil{})

@unsafe
def specialize_book(+book: List<&2,KDef>) -> KSpecialized:
  sp_public(dg_checking_result(dg_check_world(book)))

@unsafe
def sp_public(+r: KChecking) -> KSpecialized:
  KSpecialized{kc(List<&2,KDef>, good(r), u => sp_assembled(rw(r)), u => sp_source_book(kw_book(rw(r)))), KChecked{ct(r), cy(r), cs(r), ce(r)}}

@unsafe
def sp_source_book(+book: List<&2,KDef>) -> List<&2,KDef>:
  match book:
    case Nil{}: Nil{}
    case Con{h, rest}: kc(List<&2,KDef>, String.eq(dk(h), "BookCache") || String.eq(dk(h), "BookBound"), u => sp_source_book(rest), u => Con{h, sp_source_book(rest)})

@unsafe
def sp_live_checked(+e: KEnv, +ctx: List<&2,KTerm>, +head: KTerm, +sp: List<&2,KTerm>, +d: KDef, +r: KChecking) -> KChecking:
  kc(KChecking, good(r), u => sp_live_key(ke_world(e, rw(r)), ctx, head, sp, d, sp_take(sp, dx(d)), sp_keys(sp_take(sp, dx(d)))), u => r)

@unsafe
def sp_live_key(+e: KEnv, +ctx: List<&2,KTerm>, +head: KTerm, +sp: List<&2,KTerm>, +d: KDef, +xs: List<&2,KTerm>, +key: String) -> KChecking:
  kc(KChecking, U32.is_gt(sp_len(key), 32768), u => sp_live_error(e, ctx, head, "a comptime argument must stop growing", "a ~ argument that stops growing"), u => sp_live_memo(e, ctx, head, sp, d, xs, key, sp_find(kw_memo(cw(e)), dn(d), key)))

@unsafe
def sp_live_error(+e: KEnv, +ctx: List<&2,KTerm>, +head: KTerm, +message: String, +expected: String) -> KChecking:
  dg_trace(e, ctx, head, atom("Absent"), dg_bad_detail(cw(e), message, dg_text(expected), head))

@unsafe
def sp_live_memo(+e: KEnv, +ctx: List<&2,KTerm>, +head: KTerm, +sp: List<&2,KTerm>, +d: KDef, +xs: List<&2,KTerm>, +key: String, +memo: KSpecMemo) -> KChecking:
  kc(KChecking, Bool.not(String.eq(sp_mname(memo), "")),
    u => kc(KChecking, sp_active(memo) && Bool.not(String.eq(sp_mname(memo), cn(e))), u => sp_live_error(e, ctx, head, "nondecreasing cross-instance template recursion", "a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)"), u => sp_live_ref(cw(e), head, sp_mname(memo), dx(d))),
    u => kc(KChecking, U32.is_ge(cd(e), 64), u => sp_live_error(e, ctx, head, "template instantiation exceeds 64 levels", "a template that stops instantiating itself (64 levels at most)"), u => sp_live_fresh(e, ctx, head, d, xs, key, dn(d) ++ "~" ++ U32.show(sp_ordinal(kw_memo(cw(e)), dn(d))), kw_mint_floor(cw(e), Con{cl(e), norm_join(ctx, sp)}), norm_max(norm_max_term(dt(d)), norm_max_term(dv(d))))))

@unsafe
def sp_live_ref(+world: KWorld, +head: KTerm, +name: String, +consumed: U32) -> KChecking:
  KChecking{KTerm{"Ref", name, ix(head), qt(head), ks(head), rm(head), kb(head), ke(head)}, dt(lookup(kw_book(world), name)), Nil{}, "", world, consumed}

@unsafe
def sp_live_fresh(+e: KEnv, +ctx: List<&2,KTerm>, +head: KTerm, +d: KDef, +xs: List<&2,KTerm>, +key: String, +name: String, +bound: U32, +width: U32) -> KChecking:
  kc(KChecking, U32.is_lt(width, 4294967294) && U32.is_le(bound, U32.sub(4294967293, width)),
    u => sp_live_body(e, head, d, key, name, tele_fill(cb(e), sp_shift(dt(d), U32.add(bound, 1)), xs), sp_apply_template(sp_shift(dv(d), U32.add(bound, 1)), xs), U32.add(U32.add(bound, width), 2)),
    u => sp_live_error(e, ctx, head, "fresh binder space exhausted", "a representable fresh binder identity"))

@unsafe
def sp_live_body(+e: KEnv, +head: KTerm, +d: KDef, +key: String, +name: String, +ty: KTerm, +body: KTerm, +next: U32) -> KChecking:
  +inst: KDef = KDef{name, "Def", U32.sub(da(d), dx(d)), 0, ty, body, Nil{}, False{}, du(d)}
  +world: KWorld = KWorld{book_put(kw_bound_book(cb(e), U32.sub(next, 1)), declared(inst)), Con{KSpecMemo{dn(d), key, name, True{}}, kw_memo(cw(e))}, KFreshKnown{next}, kw_checked(cw(e))}
  sp_live_done(head, inst, dx(d), check_definition_body(world, inst, U32.add(cd(e), 1)))

@unsafe
def sp_live_done(+head: KTerm, +inst: KDef, +consumed: U32, +r: KChecking) -> KChecking:
  kc(KChecking, good(r), u => sp_live_ref(KWorld{book_put(kw_book(rw(r)), inst), sp_done_memo(kw_memo(rw(r)), dn(inst)), kw_fresh(rw(r)), Con{KDef{dn(inst), dk(inst), da(inst), dx(inst), dt(inst), ct(r), dc(inst), db(inst), du(inst)}, kw_checked(rw(r))}}, head, dn(inst), consumed), u => r)
'''
files[paths[1]]=s
s=files[paths[2]]
s=fn(s,'dg_trace', '''def dg_trace(e, ctx, t, ty, r):
  kc(KChecking, good(r), u => r, u => kc(KChecking, String.eq(tg(ct(r)), "DTrace"), u => KChecking{kt("DTrace", nm(ct(r)), ix(ct(r)), qt(ct(r)), [kid(ct(r), 0), kid(ct(r), 1), kid(ct(r), 2), kid(ct(r), 3), kt("DTrail", "", 0, 0, norm_join(ks(kid(ct(r), 4)), [t])), kid(ct(r), 5)]), cy(r), cs(r), ce(r), rw(r), rx(r)}, u => dg_trace_detail(ke_world(e, rw(r)), ctx, t, r, kc(KTerm, String.eq(tg(ct(r)), "DDetail"), u => ct(r), u => dg_reason(ke_world(e, rw(r)), ctx, t, ty, ce(r))))))''')
files[paths[2]]=s
OUT.mkdir();rows=[]
for name,text in files.items():
 old=before[name];(P/name).write_text(text);(OUT/(name.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(old.splitlines(True),text.splitlines(True),fromfile='before/'+name,tofile='after/'+name)))
 rows.append({'file':name,'before':hashlib.sha256(old.encode()).hexdigest(),'after':hashlib.sha256(text.encode()).hexdigest(),'deltaLines':len(text.splitlines())-len(old.splitlines())})
(OUT/'manifest.json').write_text(json.dumps({'kind':'phase19-direct-live-instance-edit','complete':True,'files':rows,'retiredDeclarations':retired,'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'scope':'Intermediate source; static review and genuine checked build are still required.'},indent=2)+'\n');print(json.dumps({'complete':True,'files':rows,'retired':len(retired)}))
