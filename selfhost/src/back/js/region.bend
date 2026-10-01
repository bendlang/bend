# Bounded private first-order regions. Analysis reads original terms; private
# positional/call/match nodes are emitter plans and are never reduced.
type JRegion is Data:
  JRegion{+zero: KTerm, +succ: KTerm, +helpers: List<&2,KDef>}

type JRegionBuild is Data:
  JRegionBuild{+term: KTerm, +helpers: List<&2,KDef>, +fuel: U32, +valid: Bool}

@unsafe
def j_region_term(+s: JRegionBuild) -> KTerm:
  match s:
    case JRegionBuild{t, ds, fuel, valid}: t

@unsafe
def j_region_helpers(+s: JRegionBuild) -> List<&2,KDef>:
  match s:
    case JRegionBuild{t, ds, fuel, valid}: ds

@unsafe
def j_region_fuel(+s: JRegionBuild) -> U32:
  match s:
    case JRegionBuild{t, ds, fuel, valid}: fuel

@unsafe
def j_region_valid(+s: JRegionBuild) -> Bool:
  match s:
    case JRegionBuild{t, ds, fuel, valid}: valid

@unsafe
def j_region_result(+s: JRegionBuild, +t: KTerm) -> JRegionBuild:
  JRegionBuild{t, j_region_helpers(s), j_region_fuel(s), j_region_valid(s)}

@unsafe
def j_region_fail(+s: JRegionBuild) -> JRegionBuild:
  JRegionBuild{atom("Absent"), j_region_helpers(s), 0, False{}}

@unsafe
def j_region_tick(+s: JRegionBuild) -> JRegionBuild:
  JRegionBuild{j_region_term(s), j_region_helpers(s), U32.sub(j_region_fuel(s), 1), j_region_valid(s)}

@unsafe
def j_region_scalar(+book: List<&2,KDef>, +ty: KTerm) -> Bool:
  +head = wnf(book, ty)
  String.contains("|U32|Bool|Nat|F32|", "|" ++ nm(head) ++ "|") && j_primitive_type(book, head, nm(head))

# Public record results remain inert flat terminal constructors. The separate
# local-type proof admits internal containers without changing this boundary.
@unsafe
def j_region_result_type(+book: List<&2,KDef>, +ty: KTerm) -> Bool:
  kc(Bool, j_region_scalar(book, ty), u => True{}, u => j_region_record(book, wnf(book, ty)))

@unsafe
def j_region_record(+book: List<&2,KDef>, +ty: KTerm) -> Bool:
  +owner = lookup(book, nm(ty))
  +kind = wnf(book, dt(owner))
  kc(Bool, String.eq(tg(ty), "ADT") && U32.is_eq(terms_len(ks(ty)), 0) && List.is_empty(&2, String, rm(ty)) &&
    String.eq(dk(owner), "ADT") && Bool.not(db(owner)) && U32.is_eq(da(owner), 0) && U32.is_eq(dx(owner), 0) &&
    String.eq(tg(kind), "Typ") && U32.is_eq(terms_len(ks(kind)), 1) && String.eq(tg(kid(kind, 0)), "Qua") && U32.is_eq(qt(kid(kind, 0)), 2),
    u => j_region_record_ctor(book, ty, dc(owner)), u => False{})

@unsafe
def j_region_record_ctor(+book: List<&2,KDef>, +ty: KTerm, +ctors: List<&2,KDef>) -> Bool:
  match ctors:
    case Con{c, Nil{}}:
      kc(Bool, String.eq(dk(c), "Ctr") && Bool.not(db(c)) && U32.is_eq(dx(c), 0) && U32.is_le(da(c), 32),
        u => j_region_record_fields(book, dt(c), nm(ty), da(c)), u => False{})
    case other: False{}

@unsafe
def j_region_record_fields(+book: List<&2,KDef>, +ty: KTerm, +owner: String, +left: U32) -> Bool:
  +head = wnf(book, ty)
  kc(Bool, U32.is_eq(left, 0), u => String.eq(tg(head), "ADT") && String.eq(nm(head), owner) &&
    U32.is_eq(terms_len(ks(head)), 0) && List.is_empty(&2, String, rm(head)), u =>
    kc(Bool, String.eq(tg(head), "All") && Bool.not(U32.is_eq(qt(head), 0)) && j_region_scalar(book, kid(head, 0)),
      u => j_region_record_fields(book, kid(head, 1), owner, U32.sub(left, 1)), u => False{}))

# Deferred constructor fields contain only inert values or proved scalar
# comparisons. Ordinary build thunks retain their original forcing order.
@unsafe
def j_region_field_values(+book: List<&2,KDef>, +xs: List<&2,KTerm>, +left: U32) -> Bool:
  match xs:
    case Nil{}: U32.is_eq(left, 0)
    case Con{h, rest}:
      +t = j_strip(h)
      kc(Bool, U32.is_gt(left, 0) && (j_region_field_atom(t) || j_region_field_compare(book, t)),
        u => j_region_field_values(book, rest, U32.sub(left, 1)), u => False{})

@unsafe
def j_region_signature(+book: List<&2,KDef>, +ty: KTerm, +left: U32) -> Bool:
  +head = wnf(book, ty)
  kc(Bool, U32.is_eq(left, 0), u => j_region_scalar(book, head), u =>
    kc(Bool, String.eq(tg(head), "All") && Bool.not(U32.is_eq(qt(head), 0)) &&
      j_region_signature(book, kid(head, 0), 0),
      u => j_region_signature(book, kid(head, 1), U32.sub(left, 1)), u => False{}))

@unsafe
def j_region_capture_eligible(+book: List<&2,KDef>, +d: KDef) -> Bool:
  kc(Bool, String.eq(dk(d), "Def") && Bool.not(db(d)) && U32.is_eq(dx(d), 0) &&
    U32.is_gt(da(d), 0) && U32.is_le(da(d), 32), u =>
    kc(Bool, String.eq(tg(j_strip(dv(d))), "Lam") || String.eq(tg(j_strip(dv(d))), "Mat"),
      u => j_region_local_signature(book, dt(d), da(d)) || j_pure_signature(book, dt(d), da(d)), u => False{}), u => False{})

@unsafe
def j_region_annotate(+t: KTerm, +ty: KTerm) -> KTerm:
  kt("Ann", "", 0, 0, [t, ty])

@unsafe
def j_region_type(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm) -> KTerm:
  kc(KTerm, String.eq(tg(t), "Lit"), u => kt("ADT", nm(t), 0, 0, Nil{}), u =>
    kc(KTerm, String.eq(tg(t), "Ctr") && (String.eq(nm(t), "True") || String.eq(nm(t), "False")),
      u => kt("ADT", "Bool", 0, 0, Nil{}), u => wnf(book, j_type(book, env, t))))

@unsafe
def j_region_variable(+env: List<&2,KTerm>, +t: KTerm) -> KTerm:
  match env:
    case Nil{}: atom("Absent")
    case Con{h, rest}:
      kc(KTerm, U32.is_eq(ix(h), ix(t)), u =>
        kc(KTerm, String.eq(tg(h), "JEnv"), u => kt("JSlot", "", qt(h), 0, Nil{}), u =>
          kc(KTerm, String.eq(tg(h), "JEnvNat"), u => kt("JNatRest", nm(h), qt(h), 0, Nil{}), u => t)),
        u => j_region_variable(rest, t))

@unsafe
def j_region_def_count(+ds: List<&2,KDef>) -> U32:
  match ds:
    case Nil{}: 0
    case Con{h, rest}: U32.inc(j_region_def_count(rest))

# Ordinary roots reuse the same analysis. Require a nested countdown so trivial
# scalar wrappers do not pay a closure guard without measured useful work.
@unsafe
def j_region_root(+book: List<&2,KDef>, +d: KDef) -> String:
  kc(String, j_region_capture_eligible(book, d) && j_fold_root_signature(book, dt(d), da(d)) && String.eq(tg(j_strip(dv(d))), "Lam"), u =>
    kc(String, j_u32_bounded([dv(d)], 8192) && U32.is_eq(j_nat_loop_count(dv(d), 0), da(d)), u =>
      kc(String, j_nat_loop_distinct(dv(d), Nil{}) && Bool.not(j_l_deep(dv(d), 0)), u =>
        j_region_root_done(book, d, j_region_prefix(book, Nil{}, dv(d), dt(d), 0, da(d), True{}, "@root-return", [dn(d)], 0,
          JRegionBuild{atom("Absent"), Nil{}, 32768, True{}})), u => ""), u => ""), u => "")

@unsafe
def j_region_has_loop(+helpers: List<&2,KDef>) -> Bool:
  match helpers:
    case Nil{}: False{}
    case Con{d, rest}: kc(Bool, Bool.not(db(d)) && (String.eq(tg(dv(d)), "Mat") || String.eq(tg(dv(d)), "JFold") || String.eq(tg(dv(d)), "JProducer")), u => True{}, u => j_region_has_loop(rest))

@unsafe
def j_region_root_done(+book: List<&2,KDef>, +d: KDef, +s: JRegionBuild) -> String:
  kc(String, j_region_valid(s) && j_region_has_loop(j_region_helpers(s)), u =>
    "(()=>{" ++ j_region_declarations(book, j_region_helpers(s)) ++ "const $guards=[" ++ j_quote(dn(d)) ++ "," ++ j_region_names(j_region_helpers(s)) ++ "];return " ++
    "fn(" ++ U32.show(da(d)) ++ ",exactCode(function(a,$entered){/* private scalar root */" ++ j_nat_loop_slots(da(d), 0) ++
    "if($entered&&" ++ j_fold_root_guard(book, d, j_region_helpers(s)) ++ j_region_inputs(book, dt(d), 0, da(d), False{}) ++ "&&localGuard($guards)){" ++
    j_nat_loop_generic(book, Nil{}, j_region_term(s), dt(d), 0) ++ "}" ++
    j_nat_loop_generic(book, Nil{}, dv(d), dt(d), 0) ++ "}));})()", u => "")

@unsafe
def j_region_global(+book: List<&2,KDef>, +d: KDef) -> String:
  +worker = j_region_root(book, d)
  kc(String, String.eq(worker, ""), u => j_u32_global(book, d, j_u32_worker(book, d)),
    u => j_l_global_worker(book, d, dv(d), worker))

@unsafe
def j_region_plan(+book: List<&2,KDef>, +d: KDef, +zero: KTerm, +succ: KTerm, +total: U32) -> Maybe<&2,JRegion>:
  j_region_plan_zero(book, d, succ, total,
    j_region_prefix(book, Nil{}, zero, j_arm_type(book, wnf(book, dt(d)), "Zero"), 0, U32.sub(total, 1), True{}, "", [dn(d)], 0,
      JRegionBuild{atom("Absent"), Nil{}, 32768, True{}}))

@unsafe
def j_region_plan_zero(+book: List<&2,KDef>, +d: KDef, +succ: KTerm, +total: U32, +s: JRegionBuild) -> Maybe<&2,JRegion>:
  kc(Maybe<&2,JRegion>, j_region_valid(s), u => j_region_plan_done(j_region_term(s),
    j_region_prefix(book, Nil{}, succ, j_arm_type(book, wnf(book, dt(d)), "Succ"), 0, total, True{}, dn(d), [dn(d)], 0, s)), u => None{})

@unsafe
def j_region_plan_done(+zero: KTerm, +s: JRegionBuild) -> Maybe<&2,JRegion>:
  kc(Maybe<&2,JRegion>, j_region_valid(s),
    u => Some{JRegion{zero, j_region_term(s), j_region_helpers(s)}}, u => None{})

# Consume helper prefixes into positional slots, but preserve the owner's
# lambda spine so the existing worker remains responsible for tail transfers.
@unsafe
def j_region_prefix(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +at: U32, +left: U32, +keep: Bool, +tail: String, +active: List<&2,String>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s) && U32.is_gt(j_region_fuel(s), 0), u =>
    kc(JRegionBuild, U32.is_eq(left, 0), u => j_region_expr(book, env, t, ty, tail, active, depth, 0, s), u =>
      j_region_prefix_on(book, env, j_strip(t), wnf(book, ty), at, left, keep, tail, active, depth, j_region_tick(s))), u => j_region_fail(s))

@unsafe
def j_region_prefix_on(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +at: U32, +left: U32, +keep: Bool, +tail: String, +active: List<&2,String>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, String.eq(tg(ty), "All") && Bool.not(U32.is_eq(qt(ty), 0)) && j_region_local_type(book, kid(ty, 0)), u =>
    kc(JRegionBuild, String.eq(tg(t), "Lam") && String.eq(j_l_name(t), ""), u =>
      j_region_prefix_lam(t, keep, j_region_prefix(book,
        Con{kt(kc(String, keep, u => "Env", u => "JEnv"), "", ix(t), at, [wnf(book, kid(ty, 0))]), env},
        kid(t, 0), subst(kid(ty, 1), ix(ty), var(nm(t), ix(t))), U32.inc(at), U32.sub(left, 1), keep, tail, active, depth, s)), u =>
      kc(JRegionBuild, Bool.not(keep) && String.eq(tg(t), "Mat") && j_primitive_type(book, wnf(book, kid(ty, 0)), "Bool"),
        u => j_region_match(book, env, t, ty, at, left, active, depth, s), u =>
        kc(JRegionBuild, Bool.not(keep) && String.eq(tg(t), "Mat"),
          u => kc(JRegionBuild, j_primitive_type(book, wnf(book, kid(ty, 0)), "Nat") &&
            (U32.is_eq(left, 1) || has_name(active, "@producer")),
            u => j_region_nat_select(book, env, t, ty, at, left, 0, active, depth, s),
            u => kc(JRegionBuild, U32.is_eq(left, 1), u => j_region_unpack(book, env, t, ty, at, active, depth, s),
              u => j_region_fail(s))), u => j_region_fail(s)))), u => j_region_fail(s))

@unsafe
def j_region_prefix_lam(+t: KTerm, +keep: Bool, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, keep, u => j_region_result(s, k_with_children(t, [j_region_term(s)])), u => s)

@unsafe
def j_region_match(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +at: U32, +left: U32, +active: List<&2,String>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  +rest = j_strip(kid(t, 1))
  kc(JRegionBuild, U32.is_eq(terms_len(ks(t)), 2) && String.eq(tg(rest), "Mat") && U32.is_eq(terms_len(ks(rest)), 2) &&
    ((String.eq(nm(t), "True") && String.eq(nm(rest), "False")) || (String.eq(nm(t), "False") && String.eq(nm(rest), "True"))) &&
    String.eq(tg(j_strip(kid(rest, 1))), "Efq"), u =>
    j_region_match_first(book, env, t, ty, at, left, active, depth,
      j_region_prefix(book, env, kid(t, 0), j_arm_type(book, ty, nm(t)), U32.inc(at), U32.sub(left, 1), False{}, "", active, depth, s)), u => j_region_fail(s))

@unsafe
def j_region_match_first(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +at: U32, +left: U32, +active: List<&2,String>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s), u =>
    j_region_match_done(nm(t), at, j_region_term(s), j_region_prefix(book, env, kid(j_strip(kid(t, 1)), 0),
      j_arm_type(book, ty, nm(j_strip(kid(t, 1)))), U32.inc(at), U32.sub(left, 1), False{}, "", active, depth, s)), u => s)

@unsafe
def j_region_match_done(+tag: String, +at: U32, +first: KTerm, +s: JRegionBuild) -> JRegionBuild:
  +cond = j_region_annotate(kt("JSlot", "", at, 0, Nil{}), kt("ADT", "Bool", 0, 0, Nil{}))
  +yes = kc(KTerm, String.eq(tag, "True"), u => first, u => j_region_term(s))
  +no = kc(KTerm, String.eq(tag, "True"), u => j_region_term(s), u => first)
  j_region_result(s, j_region_annotate(kt("JIf", "", 0, 0, [cond, yes, no]), kid(first, 1)))

# Finite Nat decisions inside an already guarded private region. Each branch
# is analyzed normally, retaining live helper dependencies and leaf demand.
# Remainder binders denote the original input minus the matched Succ depth.
@unsafe
def j_region_nat_select(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +at: U32, +left: U32, +offset: U32, +active: List<&2,String>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s) && U32.is_gt(j_region_fuel(s), 0) && U32.is_le(offset, 64), u =>
    j_region_nat_select_on(book, env, j_strip(t), wnf(book, ty), at, left, offset, active, depth, j_region_tick(s)), u => j_region_fail(s))

@unsafe
def j_region_nat_select_on(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +at: U32, +left: U32, +offset: U32, +active: List<&2,String>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, String.eq(tg(ty), "All") && Bool.not(U32.is_eq(qt(ty), 0)) && j_primitive_type(book, wnf(book, kid(ty, 0)), "Nat"), u =>
    kc(JRegionBuild, String.eq(tg(t), "Lam") && String.eq(j_l_name(t), ""), u =>
      j_region_prefix(book, Con{kt("JEnvNat", U32.show(offset), ix(t), at, [wnf(book, kid(ty, 0))]), env},
        kid(t, 0), subst(kid(ty, 1), ix(ty), var(nm(t), ix(t))), U32.inc(at), U32.sub(left, 1), False{}, "", active, depth, s), u =>
      j_region_nat_match(book, env, t, ty, at, left, offset, active, depth, s)), u => j_region_fail(s))

@unsafe
def j_region_nat_match(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +at: U32, +left: U32, +offset: U32, +active: List<&2,String>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  +rest = j_strip(kid(t, 1))
  kc(JRegionBuild, String.eq(tg(t), "Mat") && String.eq(nm(t), "Zero") && U32.is_eq(terms_len(ks(t)), 2) &&
    String.eq(tg(rest), "Mat") && String.eq(nm(rest), "Succ") && U32.is_eq(terms_len(ks(rest)), 2) &&
    String.eq(tg(j_strip(kid(rest, 1))), "Efq") && U32.is_eq(terms_len(ks(j_strip(kid(rest, 1)))), 0), u =>
      j_region_nat_first(book, env, t, ty, at, left, offset, active, depth,
        j_region_prefix(book, env, kid(t, 0), j_arm_type(book, ty, "Zero"), U32.inc(at), U32.sub(left, 1), False{}, "", active, depth, s)), u => j_region_fail(s))

@unsafe
def j_region_nat_first(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +at: U32, +left: U32, +offset: U32, +active: List<&2,String>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s), u =>
    j_region_nat_done(at, offset, j_region_term(s), j_region_nat_select(book, env, kid(j_strip(kid(t, 1)), 0),
      j_arm_type(book, ty, "Succ"), at, left, U32.inc(offset), active, depth, s)), u => s)

@unsafe
def j_region_nat_done(+at: U32, +offset: U32, +first: KTerm, +s: JRegionBuild) -> JRegionBuild:
  j_region_result(s, j_region_annotate(kt("JNatCase", "", at, offset, [first, j_region_term(s)]), kid(first, 1)))

@unsafe
def j_region_expr(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +tail: String, +active: List<&2,String>, +depth: U32, +level: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s) && U32.is_gt(j_region_fuel(s), 0) && U32.is_lt(level, 128), u =>
    kc(JRegionBuild, j_region_local_type(book, ty), u =>
      j_region_expr_on(book, env, t, wnf(book, ty), tail, active, depth, U32.inc(level), j_region_tick(s)), u => j_region_fail(s)), u => j_region_fail(s))

@unsafe
def j_region_expr_on(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +tail: String, +active: List<&2,String>, +depth: U32, +level: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, String.eq(tg(t), "Ann"), u =>
    kc(JRegionBuild, j_region_local_type(book, kid(t, 1)) && String.eq(nm(wnf(book, kid(t, 1))), nm(ty)),
      u => j_region_expr(book, env, kid(t, 0), ty, tail, active, depth, level, s), u => j_region_fail(s)), u =>
  kc(JRegionBuild, String.eq(tg(t), "Var"), u =>
    kc(JRegionBuild, j_region_local_type(book, j_env(env, ix(t))) && String.eq(nm(wnf(book, j_env(env, ix(t)))), nm(ty)),
      u => j_region_result(s, j_region_annotate(j_region_variable(env, t), ty)), u => j_region_fail(s)), u =>
  kc(JRegionBuild, String.eq(tg(t), "Lit"), u =>
    kc(JRegionBuild, String.eq(nm(t), nm(ty)) && (String.eq(nm(t), "U32") || String.eq(nm(t), "Nat") || String.eq(nm(t), "F32")),
      u => j_region_result(s, j_region_annotate(t, ty)), u => j_region_fail(s)), u =>
  kc(JRegionBuild, String.eq(tg(t), "Ctr"), u =>
    kc(JRegionBuild, String.eq(nm(ty), "Bool") && U32.is_eq(terms_len(ks(t)), 0) && (String.eq(nm(t), "True") || String.eq(nm(t), "False")),
      u => j_region_result(s, j_region_annotate(t, ty)), u => j_region_constructor(book, env, t, ty, String.eq(tail, "@root-return"), active, depth, level, s)), u =>
  kc(JRegionBuild, String.eq(tg(t), "Let"), u =>
    j_region_let_done(t, ty, j_region_bindings(book, env, j_context(book, env, ks(t)), ks(t), ty, tail, active, depth, level, 0, s)), u =>
  kc(JRegionBuild, String.eq(tg(t), "App"), u =>
    j_region_call(book, env, j_call_spine(t, Nil{}), ty, tail, active, depth, level, s), u => j_region_fail(s)))))))

@unsafe
def j_region_constructor(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +root: Bool, +active: List<&2,String>, +depth: U32, +level: U32, +s: JRegionBuild) -> JRegionBuild:
  +c = j_producer_ctor(book, ty, nm(t), active)
  kc(JRegionBuild, j_region_local_type(book, ty) && String.eq(dk(c), "Ctr") && String.eq(dn(c), nm(t)) &&
    U32.is_eq(terms_len(ks(t)), da(c)) &&
    kc(Bool, j_fold_type(book, ty), u => j_fold_terminal_fields(book, ks(t), da(c)), u =>
      kc(Bool, j_region_record(book, ty), u => kc(Bool, root, u => j_fold_terminal_fields(book, ks(t), da(c)),
        u => j_region_field_values(book, ks(t), da(c))), u => True{})), u =>
    j_region_constructor_done(book, t, ty, j_region_args(book, env, ks(t), j_specialize(book, dt(c), ks(ty)), active, depth, level, s)), u => j_region_fail(s))

@unsafe
def j_region_constructor_done(+book: List<&2,KDef>, +t: KTerm, +ty: KTerm, +s: JRegionBuild) -> JRegionBuild:
  j_region_result(s, j_region_annotate(kc(KTerm, j_region_local_vector(book, ty),
    u => kt("JVector", nm(t), 0, 0, ks(j_region_term(s))),
    u => k_with_children(t, ks(j_region_term(s)))), ty))

@unsafe
def j_region_let_done(+t: KTerm, +ty: KTerm, +s: JRegionBuild) -> JRegionBuild:
  j_region_result(s, j_region_annotate(k_with_children(t, ks(j_region_term(s))), ty))

# Each parallel RHS sees the old environment. Only the final body receives the
# extended environment; immutable binder identities and evaluation order stay.
@unsafe
def j_region_bindings(+book: List<&2,KDef>, +env: List<&2,KTerm>, +bodyEnv: List<&2,KTerm>, +xs: List<&2,KTerm>, +ty: KTerm, +tail: String, +active: List<&2,String>, +depth: U32, +level: U32, +count: U32, +s: JRegionBuild) -> JRegionBuild:
  match xs:
    case Nil{}: j_region_fail(s)
    case Con{body, Nil{}}:
      j_region_list_one(j_region_expr(book, bodyEnv, body, ty, tail, active, depth, level, s))
    case Con{bind, rest}:
      kc(JRegionBuild, j_region_valid(s) && U32.is_lt(count, 128) && String.eq(tg(bind), "Bind") &&
        Bool.not(U32.is_eq(qt(bind), 0)) && U32.is_eq(terms_len(ks(bind)), 1) && j_region_local_type(book, j_region_type(book, env, kid(bind, 0))), u =>
        j_region_binding_first(book, env, bodyEnv, bind, rest, ty, tail, active, depth, level, count,
          j_region_expr(book, env, kid(bind, 0), j_region_type(book, env, kid(bind, 0)), "", active, depth, level, s)), u => j_region_fail(s))

@unsafe
def j_region_binding_first(+book: List<&2,KDef>, +env: List<&2,KTerm>, +bodyEnv: List<&2,KTerm>, +bind: KTerm, +rest: List<&2,KTerm>, +ty: KTerm, +tail: String, +active: List<&2,String>, +depth: U32, +level: U32, +count: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s), u => j_region_list_prepend(k_with_children(bind, [j_region_term(s)]),
    j_region_bindings(book, env, bodyEnv, rest, ty, tail, active, depth, level, U32.inc(count), s)), u => s)

@unsafe
def j_region_list_one(+s: JRegionBuild) -> JRegionBuild:
  j_region_result(s, kt("JList", "", 0, 0, [j_region_term(s)]))

@unsafe
def j_region_list_prepend(+t: KTerm, +s: JRegionBuild) -> JRegionBuild:
  j_region_result(s, kt("JList", "", 0, 0, Con{t, ks(j_region_term(s))}))

@unsafe
def j_region_call(+book: List<&2,KDef>, +env: List<&2,KTerm>, +spine: KTerm, +ty: KTerm, +tail: String, +active: List<&2,String>, +depth: U32, +level: U32, +s: JRegionBuild) -> JRegionBuild:
  +d = lookup(book, nm(spine))
  kc(JRegionBuild, String.eq(tg(spine), "Call") && U32.is_gt(da(d), 0) && U32.is_le(da(d), 32) && U32.is_eq(terms_len(ks(spine)), da(d)), u =>
    kc(JRegionBuild, j_primitive_call(book, spine) || (Bool.not(String.eq(tail, "")) && String.eq(nm(spine), tail)), u =>
      j_region_call_done(book, spine, ty, False{}, j_region_args(book, env, ks(spine), dt(d), active, depth, level, s)), u =>
      kc(JRegionBuild, j_region_local_native(book, spine),
        u => j_region_native_done(spine, ty, j_region_args(book, env, ks(spine), dt(d), active, depth, level, j_region_native_dependency(d, s))), u =>
        j_region_try_helper(book, env, spine, ty, active, depth, level, s, j_region_helper(book, d, active, depth, s)))), u => j_region_fail(s))

@unsafe
def j_region_call_helper(+book: List<&2,KDef>, +env: List<&2,KTerm>, +spine: KTerm, +ty: KTerm, +active: List<&2,String>, +depth: U32, +level: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s), u =>
    j_region_call_done(book, spine, ty, True{}, j_region_args(book, env, ks(spine), dt(lookup(book, nm(spine))), active, depth, level, s)), u => s)

@unsafe
def j_region_call_done(+book: List<&2,KDef>, +spine: KTerm, +ty: KTerm, +private: Bool, +s: JRegionBuild) -> JRegionBuild:
  j_region_result(s, j_region_annotate(kc(KTerm, private,
    u => kt(kc(String, String.eq(tg(dv(lookup(j_region_helpers(s), nm(spine)))), "JResidual"), u => "JGeneric", u =>
      kc(String, j_region_read_call(book, spine, s), u => "JReadCall", u => "JCall")), nm(spine), 0, 0, ks(j_region_term(s))),
    u => j_region_app(ref(nm(spine)), ks(j_region_term(s)))), ty))

# Only a proved native read immediately consumed by a complete private pair
# match can use the bridge. All other producers keep their existing tuple ABI.
@unsafe
def j_region_read_call(+book: List<&2,KDef>, +spine: KTerm, +s: JRegionBuild) -> Bool:
  +last = j_strip(j_body(ks(j_region_term(s))))
  String.eq(tg(last), "JNative") && String.eq(nm(last), "Array.get") && U32.is_eq(terms_len(ks(last)), 3) &&
  j_region_read_consumer(book, lookup(j_region_helpers(s), nm(spine)))

@unsafe
def j_region_read_consumer(+book: List<&2,KDef>, +d: KDef) -> Bool:
  +body = j_strip(dv(d))
  Bool.not(db(d)) && U32.is_gt(da(d), 0) && String.eq(tg(body), "JUnpack") &&
  U32.is_eq(U32.inc(ix(body)), da(d)) && U32.is_eq(qt(body), 2) && j_region_local_pair(book, kid(body, 1))

@unsafe
def j_region_app(+head: KTerm, +args: List<&2,KTerm>) -> KTerm:
  match args:
    case Nil{}: head
    case Con{h, rest}: j_region_app(kt("App", "", 0, 0, [head, h]), rest)

@unsafe
def j_region_args(+book: List<&2,KDef>, +env: List<&2,KTerm>, +args: List<&2,KTerm>, +ty: KTerm, +active: List<&2,String>, +depth: U32, +level: U32, +s: JRegionBuild) -> JRegionBuild:
  match args:
    case Nil{}:
      kc(JRegionBuild, j_region_local_type(book, ty), u => j_region_result(s, kt("JList", "", 0, 0, Nil{})), u => j_region_fail(s))
    case Con{h, rest}:
      +head = wnf(book, ty)
      kc(JRegionBuild, j_region_valid(s) && String.eq(tg(head), "All"), u =>
        kc(JRegionBuild, U32.is_eq(qt(head), 0), u =>
          kc(JRegionBuild, j_primitive_type(book, wnf(book, h), "U32"),
            u => j_region_arg_first(book, env, rest, j_app_type(head, h), active, depth, level, j_region_result(s, h)), u => j_region_fail(s)), u =>
          kc(JRegionBuild, j_region_local_type(book, kid(head, 0)), u =>
            j_region_arg_first(book, env, rest, j_app_type(head, h), active, depth, level,
              j_region_expr(book, env, h, kid(head, 0), "", active, depth, level, s)), u => j_region_fail(s))), u => j_region_fail(s))

@unsafe
def j_region_arg_first(+book: List<&2,KDef>, +env: List<&2,KTerm>, +rest: List<&2,KTerm>, +ty: KTerm, +active: List<&2,String>, +depth: U32, +level: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s), u => j_region_list_prepend(j_region_term(s),
    j_region_args(book, env, rest, ty, active, depth, level, s)), u => s)

@unsafe
def j_region_helper(+book: List<&2,KDef>, +d: KDef, +active: List<&2,String>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, String.eq(dk(lookup(j_region_helpers(s), dn(d))), "Def") &&
    Bool.not(String.eq(tg(dv(lookup(j_region_helpers(s), dn(d)))), "JResidual")), u => s, u =>
    kc(JRegionBuild, j_region_valid(s) && U32.is_lt(depth, 16) && U32.is_lt(j_region_def_count(j_region_helpers(s)), 32) &&
      Bool.not(has_name(active, dn(d))), u =>
      kc(JRegionBuild, j_region_capture_eligible(book, d), u =>
        kc(JRegionBuild, j_u32_bounded([dv(d)], 8192), u =>
          j_fold_helper(book, d, active, depth, s, j_fold_plan(book, d)),
          u => j_region_fail(s)), u => j_region_fail(s)), u => j_region_fail(s)))

# Nested loops share the enclosing active chain, completed cache and fuel.
@unsafe
def j_region_nested(+book: List<&2,KDef>, +d: KDef, +active: List<&2,String>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  j_region_nested_zero(book, d, active, depth,
    j_region_prefix(book, Nil{}, kid(j_strip(dv(d)), 0), j_arm_type(book, wnf(book, dt(d)), "Zero"), 0, U32.sub(da(d), 1), False{}, "", active, depth, s))

@unsafe
def j_region_nested_zero(+book: List<&2,KDef>, +d: KDef, +active: List<&2,String>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s), u => j_region_nested_done(d, j_region_term(s),
    j_region_prefix(book, Nil{}, kid(j_strip(kid(j_strip(dv(d)), 1)), 0), j_arm_type(book, wnf(book, dt(d)), "Succ"), 0, da(d), True{}, dn(d), active, depth, s)), u => s)

@unsafe
def j_region_nested_done(+d: KDef, +zero: KTerm, +s: JRegionBuild) -> JRegionBuild:
  +outer = j_strip(dv(d))
  +inner = j_strip(kid(outer, 1))
  j_region_helper_done(d, j_region_result(s, k_with_children(outer, [zero, k_with_children(inner, [j_region_term(s), kid(inner, 1)])])))

@unsafe
def j_region_helper_done(+d: KDef, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s) && U32.is_lt(j_region_def_count(j_region_helpers(s)), 32), u =>
    JRegionBuild{j_region_term(s), Con{KDef{dn(d), dk(d), da(d), dx(d), dt(d), j_region_term(s), dc(d), db(d), du(d)}, j_pure_remove(j_region_helpers(s), dn(d))}, j_region_fuel(s), True{}},
    u => j_region_fail(s))

@unsafe
def j_region_names(+helpers: List<&2,KDef>) -> String:
  match helpers:
    case Nil{}: ""
    case Con{d, Nil{}}: j_quote(dn(d))
    case Con{d, rest}: j_quote(dn(d)) ++ "," ++ j_region_names(rest)

@unsafe
def j_region_declarations(+book: List<&2,KDef>, +helpers: List<&2,KDef>) -> String:
  j_region_definitions(book, j_region_inline_defs(book, helpers, helpers))

# Delimited codepoints preserve source identity without a private name table.
@unsafe
def j_region_name(+name: String) -> String:
  "$R" ++ j_region_name_chars(name)

@unsafe
def j_region_name_chars(+name: String) -> String:
  match name:
    case SNil{}: ""
    case SCon{c, rest}: "_" ++ U32.show(Char.to_u32(c)) ++ j_region_name_chars(rest)

@unsafe
def j_region_definitions(+book: List<&2,KDef>, +helpers: List<&2,KDef>) -> String:
  match helpers:
    case Nil{}: ""
    case Con{d, rest}:
      kc(String, db(d) || String.eq(tg(dv(d)), "JResidual"), u => "", u =>
        "function " ++ j_region_name(dn(d)) ++ "(" ++ j_region_parameters(0, da(d)) ++ "){" ++
        kc(String, String.eq(tg(dv(d)), "JFold"), u => j_fold_emit(book, d), u =>
          kc(String, String.eq(tg(dv(d)), "JProducer"), u => j_producer_emit(book, d), u =>
          kc(String, String.eq(tg(dv(d)), "Mat"), u => j_region_nested_body(book, d),
            u => j_region_return(book, Nil{}, dv(d), kid(dv(d), 1))))) ++ "}") ++
        j_region_read_definition(book, d) ++ j_region_definitions(book, rest)

# The suffix cannot collide with the decimal-only encoded private helper name.
# Perform the read before the consumer arm, including when that scalar is unused.
@unsafe
def j_region_read_definition(+book: List<&2,KDef>, +d: KDef) -> String:
  kc(String, j_region_read_consumer(book, d), u =>
    "function " ++ j_region_name(dn(d)) ++ "$get(" ++ j_region_parameters(0, U32.sub(da(d), 1)) ++
    kc(String, U32.is_gt(da(d), 1), u => ",", u => "") ++ "_t,$array,$index){" ++
    "const $p" ++ U32.show(da(d)) ++ "=$array;const $data=arraydata($array);const $p" ++ U32.show(U32.inc(da(d))) ++
    "=$data[Number($index)%$data.length];" ++ j_region_return(book, Nil{}, kid(j_strip(dv(d)), 0), kid(dv(d), 1)) ++ "}", u => "")

# Private callers already demand the result before the next source operation.
# Complete fields in order here; preserve parallel RHS scope and fresh aliases.
@unsafe
def j_region_return(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm) -> String:
  kc(String, String.eq(tg(t), "Ann"), u => j_region_return(book, env, kid(t, 0), kid(t, 1)), u =>
  kc(String, String.eq(tg(t), "Let"), u => "{" ++ j_nat_loop_values(book, env, ks(t), 0) ++ "{" ++
    j_nat_loop_names(ks(t), 0) ++ j_region_return(book, j_context(book, env, ks(t)), j_body(ks(t)), ty) ++ "}}", u =>
  kc(String, String.eq(tg(t), "JUnpack"), u => "{const $unpack=$p" ++ U32.show(ix(t)) ++
    kc(String, j_region_local_vector(book, kid(t, 1)), u => "", u => ".a") ++ ";{" ++
    j_region_field_bindings(ix(t), 0, qt(t)) ++ j_region_return(book, env, kid(t, 0), ty) ++ "}}", u =>
  kc(String, String.eq(tg(t), "JInline") || String.eq(tg(t), "JInlineRead"), u => j_region_inline_return(book, env, t, ty), u =>
    "return " ++ j_expr(book, env, t, ty, False{}) ++ ";"))))

# Capture the input outside the field-binding scope. Nested unpacking may reuse
# the temporary, while parallel lets and initial-zero rebinding keep their scope.
@unsafe
def j_region_field_bindings(+slot: U32, +at: U32, +total: U32) -> String:
  kc(String, U32.is_eq(at, total), u => "", u =>
    "const $p" ++ U32.show(U32.add(U32.inc(slot), at)) ++ "=$unpack[" ++ U32.show(at) ++ "];" ++
    j_region_field_bindings(slot, U32.inc(at), total))

@unsafe
def j_region_nested_body(+book: List<&2,KDef>, +d: KDef) -> String:
  "if($p0===0n){return ((" ++ j_region_parameters(0, U32.sub(da(d), 1)) ++ ")=>{" ++ j_region_return(book, Nil{}, kid(dv(d), 0), kid(kid(dv(d), 0), 1)) ++ "})(" ++ j_region_parameters(1, da(d)) ++ ");}" ++
  kc(String, j_region_number_counter(book, d), u => "let $s0=regionCounterNumber($p0)-1;", u => "let $s0=$p0-1n;") ++ j_region_nested_slots(1, da(d)) ++
  kc(String, U32.is_gt(j_region_vector_count(book, d), 0), u => j_region_vector_body(book, d, kid(j_strip(kid(dv(d), 1)), 0), da(d), j_region_vector_count(book, d)), u =>
    j_nat_loop_body(book, d, kid(j_strip(kid(dv(d), 1)), 0), da(d)))

@unsafe
def j_region_nested_slots(+at: U32, +total: U32) -> String:
  kc(String, U32.is_eq(at, total), u => "", u =>
    "let $s" ++ U32.show(at) ++ "=$p" ++ U32.show(at) ++ ";" ++ j_region_nested_slots(U32.inc(at), total))

@unsafe
def j_region_parameters(+at: U32, +total: U32) -> String:
  kc(String, U32.is_eq(at, total), u => "", u =>
    "$p" ++ U32.show(at) ++ kc(String, U32.is_eq(U32.inc(at), total), u => "", u => "," ++ j_region_parameters(U32.inc(at), total)))

# Native descriptors enter the same definition-time dependency guard, but have
# no emitted private body. Erased U32 arguments keep their null ABI slots.
@unsafe
def j_region_native_dependency(+d: KDef, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, String.eq(dk(lookup(j_region_helpers(s), dn(d))), "Def"), u => s, u =>
    kc(JRegionBuild, U32.is_lt(j_region_def_count(j_region_helpers(s)), 32),
      u => JRegionBuild{j_region_term(s), Con{d, j_region_helpers(s)}, j_region_fuel(s), j_region_valid(s)}, u => j_region_fail(s)))

@unsafe
def j_region_native_done(+spine: KTerm, +ty: KTerm, +s: JRegionBuild) -> JRegionBuild:
  j_region_result(s, j_region_annotate(kt("JNative", nm(spine), 0, 0, ks(j_region_term(s))), ty))

# A private record matcher consumes the complete specialized field telescope.
# The input is the last ordinary argument; its field slots follow all inputs.
@unsafe
def j_region_unpack(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +at: U32, +active: List<&2,String>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  +arg = wnf(book, kid(ty, 0))
  +c = j_region_local_ctor(book, arg)
  kc(JRegionBuild, String.eq(dk(c), "Ctr") && String.eq(nm(t), dn(c)) && U32.is_eq(terms_len(ks(t)), 2) &&
    String.eq(tg(j_strip(kid(t, 1))), "Efq") && U32.is_eq(terms_len(ks(j_strip(kid(t, 1)))), 0) &&
    j_nat_loop_lambdas(book, kid(t, 0), j_arm_type(book, ty, nm(t)), da(c)), u =>
    j_region_unpack_done(nm(t), arg, at, da(c), j_region_prefix(book, env, kid(t, 0), j_arm_type(book, ty, nm(t)), U32.inc(at), da(c), False{}, "", active, depth, s)), u => j_region_fail(s))

@unsafe
def j_region_unpack_done(+name: String, +arg: KTerm, +at: U32, +fields: U32, +s: JRegionBuild) -> JRegionBuild:
  j_region_result(s, j_region_annotate(kt("JUnpack", name, at, fields, [j_region_term(s), arg]), kid(j_region_term(s), 1)))

# Inline bounded private plans only after the closed-region proof. A shared
# visit budget includes copied bodies; failure keeps the original helper intact.
@unsafe
def j_region_inline_defs(+book: List<&2,KDef>, +helpers: List<&2,KDef>, +rest: List<&2,KDef>) -> List<&2,KDef>:
  match rest:
    case Nil{}: Nil{}
    case Con{d, more}:
      +s = kc(JRegionBuild, String.eq(tg(dv(d)), "JResidual"), u => JRegionBuild{dv(d), Nil{}, 2048, True{}}, u =>
        j_region_inline_term(book, helpers, dv(d), 0, JRegionBuild{atom("Absent"), Nil{}, 2048, True{}}))
      Con{KDef{dn(d), dk(d), da(d), dx(d), dt(d), kc(KTerm, j_region_valid(s), u => j_region_term(s), u => dv(d)), dc(d), db(d), du(d)}, j_region_inline_defs(book, helpers, more)}

@unsafe
def j_region_inline_term(+book: List<&2,KDef>, +helpers: List<&2,KDef>, +t: KTerm, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s) && U32.is_gt(j_region_fuel(s), 0), u =>
    j_region_inline_children(book, helpers, t, depth, j_region_inline_terms(book, helpers, ks(t), depth, j_region_tick(s))), u => j_region_fail(s))

@unsafe
def j_region_inline_terms(+book: List<&2,KDef>, +helpers: List<&2,KDef>, +xs: List<&2,KTerm>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  match xs:
    case Nil{}: j_region_result(s, kt("JList", "", 0, 0, Nil{}))
    case Con{h, rest}: j_region_inline_first(book, helpers, rest, depth, j_region_inline_term(book, helpers, h, depth, s))

@unsafe
def j_region_inline_first(+book: List<&2,KDef>, +helpers: List<&2,KDef>, +rest: List<&2,KTerm>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s), u =>
    j_region_list_prepend(j_region_term(s), j_region_inline_terms(book, helpers, rest, depth, s)), u => s)

@unsafe
def j_region_inline_children(+book: List<&2,KDef>, +helpers: List<&2,KDef>, +t: KTerm, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  +d = lookup(helpers, nm(t))
  kc(JRegionBuild, j_region_valid(s) && U32.is_lt(depth, 8) &&
    (String.eq(tg(t), "JCall") || String.eq(tg(t), "JReadCall")) &&
    String.eq(dk(d), "Def") && Bool.not(db(d)) && String.eq(tg(dv(d)), "Ann") &&
    j_region_local_vector(book, kid(dv(d), 1)), u =>
    j_region_inline_done(t, da(d), ks(j_region_term(s)), j_region_inline_term(book, helpers,
      kc(KTerm, String.eq(tg(t), "JReadCall"), u => kid(j_strip(dv(d)), 0), u => dv(d)), U32.inc(depth), s)),
    u => j_region_result(s, k_with_children(t, ks(j_region_term(s)))))

@unsafe
def j_region_inline_done(+t: KTerm, +arity: U32, +args: List<&2,KTerm>, +s: JRegionBuild) -> JRegionBuild:
  j_region_result(s, kt(kc(String, String.eq(tg(t), "JReadCall"), u => "JInlineRead", u => "JInline"), nm(t), arity, 0, Con{j_region_term(s), args}))

@unsafe
def j_region_inline_args(+t: KTerm) -> List<&2,KTerm>:
  j_region_inline_args_on(ks(t))

@unsafe
def j_region_inline_args_on(+xs: List<&2,KTerm>) -> List<&2,KTerm>:
  match xs:
    case Con{body, args}: args
    case Nil{}: Nil{}

# Capture all arguments before introducing positional names: callers can use
# those same names. Flatten a proved read only at its original producer point.
@unsafe
def j_region_inline_return(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm) -> String:
  j_region_inline_output(book, env, t, ty, "", 0)

@unsafe
def j_region_inline_output(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +out: String, +fields: U32) -> String:
  +read = String.eq(tg(t), "JInlineRead")
  +virtual = j_region_inline_virtual(t)
  "{" ++ j_region_inline_values(book, env, j_region_inline_args(t), dt(lookup(book, nm(t))), 0, read, virtual) ++ "{" ++
  j_region_inline_bind(0, kc(U32, read || virtual, u => U32.sub(ix(t), 1), u => ix(t))) ++
  kc(String, read, u => "const $array=$i" ++ U32.show(ix(t)) ++ ";const $index=$i" ++ U32.show(U32.inc(ix(t))) ++
    ";const $p" ++ U32.show(ix(t)) ++ "=$array;const $data=arraydata($array);const $p" ++ U32.show(U32.inc(ix(t))) ++
    "=$data[Number($index)%$data.length];", u => "") ++
  kc(String, virtual, u => j_region_inline_virtual_bind(ix(t), 0, qt(j_strip(kid(t, 0)))), u => "") ++
  j_region_emit_output(book, Nil{}, kc(KTerm, virtual, u => kid(j_strip(kid(t, 0)), 0), u => kid(t, 0)), ty, out, fields) ++ "}}"

@unsafe
def j_region_inline_values(+book: List<&2,KDef>, +env: List<&2,KTerm>, +args: List<&2,KTerm>, +ty: KTerm, +at: U32, +read: Bool, +virtual: Bool) -> String:
  match args:
    case Nil{}: ""
    case Con{h, rest}:
      +head = wnf(book, ty)
      kc(String, virtual && List.is_empty(&2, KTerm, rest), u => "", u =>
      kc(String, read && List.is_empty(&2, KTerm, rest), u =>
        j_region_inline_values(book, env, ks(j_strip(h)), dt(lookup(book, "Array.get")), at, False{}, False{}), u =>
        "const $i" ++ U32.show(at) ++ "=" ++ kc(String, U32.is_eq(qt(head), 0), u => "null", u => j_expr(book, env, h, kid(head, 0), False{})) ++ ";" ++
        j_region_inline_values(book, env, rest, j_app_type(head, h), U32.inc(at), read, virtual)))

@unsafe
def j_region_inline_bind(+at: U32, +total: U32) -> String:
  kc(String, U32.is_eq(at, total), u => "", u =>
    "const $p" ++ U32.show(at) ++ "=$i" ++ U32.show(at) ++ ";" ++ j_region_inline_bind(U32.inc(at), total))

# Scalarize only the final private vector argument of an admitted countdown.
# Other uses reify a value; complete inlined matches read virtual fields directly.
@unsafe
def j_region_vector_count(+book: List<&2,KDef>, +d: KDef) -> U32:
  +ty = j_region_last_input(book, dt(d), da(d))
  kc(U32, j_region_local_vector(book, ty), u => j_region_local_field_count(book, ty), u => 0)

@unsafe
def j_region_last_input(+book: List<&2,KDef>, +ty: KTerm, +left: U32) -> KTerm:
  +head = wnf(book, ty)
  kc(KTerm, U32.is_eq(left, 1), u => kid(head, 0), u =>
    kc(KTerm, U32.is_gt(left, 1), u => j_region_last_input(book, kid(head, 1), U32.sub(left, 1)), u => atom("Absent")))

@unsafe
def j_region_vector_names(+prefix: String, +at: U32, +total: U32) -> String:
  kc(String, U32.is_eq(at, total), u => "", u => prefix ++ U32.show(at) ++ "," ++ j_region_vector_names(prefix, U32.inc(at), total))

@unsafe
def j_region_vector_copy(+to: String, +from: String, +at: U32, +total: U32, +index: Bool) -> String:
  kc(String, U32.is_eq(at, total), u => "", u => to ++ U32.show(at) ++ "=" ++ from ++
    kc(String, index, u => "[" ++ U32.show(at) ++ "]", u => U32.show(at)) ++ ";" ++
    j_region_vector_copy(to, from, U32.inc(at), total, index))

@unsafe
def j_region_vector_body(+book: List<&2,KDef>, +d: KDef, +succ: KTerm, +total: U32, +fields: U32) -> String:
  j_region_vector_copy("let $w", "$p" ++ U32.show(U32.sub(total, 1)), 0, fields, True{}) ++
  "for(;;){" ++ j_region_vector_enter(book, Nil{}, succ, j_arm_type(book, wnf(book, dt(d)), "Succ"), d, 0, total, fields) ++ "}"

@unsafe
def j_region_vector_enter(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +d: KDef, +at: U32, +total: U32, +fields: U32) -> String:
  +body = j_strip(t)
  +head = wnf(book, ty)
  kc(String, String.eq(tg(body), "Lam"), u =>
    kc(String, U32.is_eq(U32.inc(at), total), u => "", u => "const " ++ j_local(ix(body)) ++ "=$s" ++ U32.show(at) ++ ";") ++
    j_region_vector_enter(book, Con{kt("Env", "", ix(body), 0, [kid(head, 0)]), env},
      kc(KTerm, U32.is_eq(U32.inc(at), total), u => subst(kid(body, 0), ix(body), kt("JVirtual", "", fields, 0, Nil{})), u => kid(body, 0)),
      subst(kid(head, 1), ix(head), var(nm(body), ix(body))), d, U32.inc(at), total, fields),
    u => j_region_vector_emit(book, env, body, head, d, total, fields))

@unsafe
def j_region_vector_emit(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +d: KDef, +total: U32, +fields: U32) -> String:
  +last = U32.sub(total, 1)
  +out = "$n" ++ U32.show(last) ++ "_"
  kc(String, String.eq(tg(t), "Ann"), u => j_region_vector_emit(book, env, kid(t, 0), kid(t, 1), d, total, fields), u =>
  kc(String, String.eq(tg(t), "Let"), u => "{" ++ j_nat_loop_values(book, env, ks(t), 0) ++ "{" ++ j_nat_loop_names(ks(t), 0) ++
    j_region_vector_emit(book, j_context(book, env, ks(t)), j_body(ks(t)), ty, d, total, fields) ++ "}}", u =>
    j_region_vector_next(book, env, ks(j_call_spine(t, Nil{})), dt(d), 0, last, fields) ++
    "if($n0===" ++ kc(String, j_region_number_counter(book, d), u => "0", u => "0n") ++ "){const $n" ++ U32.show(last) ++ "=[" ++ j_region_vector_names(out, 0, fields) ++ "];" ++ j_nat_loop_zero(book, d, total) ++ "}" ++
    "$s0=$n0-" ++ kc(String, j_region_number_counter(book, d), u => "1", u => "1n") ++ ";" ++ j_nat_loop_assign(last, 1) ++ j_region_vector_copy("$w", out, 0, fields, False{}) ++ "continue;"))

@unsafe
def j_region_vector_next(+book: List<&2,KDef>, +env: List<&2,KTerm>, +args: List<&2,KTerm>, +ty: KTerm, +at: U32, +last: U32, +fields: U32) -> String:
  match args:
    case Nil{}: ""
    case Con{h, rest}:
      +head = wnf(book, ty)
      +out = "$n" ++ U32.show(at) ++ "_"
      kc(String, U32.is_eq(at, last), u => "let " ++ j_region_vector_names(out, 0, U32.sub(fields, 1)) ++ out ++ U32.show(U32.sub(fields, 1)) ++ ";" ++
        j_region_vector_return(book, env, h, kid(head, 0), out, fields), u =>
        "const $n" ++ U32.show(at) ++ "=" ++ j_expr(book, env, h, kid(head, 0), False{}) ++ ";" ++
        j_region_vector_next(book, env, rest, j_app_type(head, h), U32.inc(at), last, fields))

# Result destinations are fresh next-state slots. All fields are completed in
# source order before any current loop slot changes; aliases remain snapshots.
@unsafe
def j_region_vector_return(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +out: String, +fields: U32) -> String:
  kc(String, String.eq(tg(t), "Ann"), u => j_region_vector_return(book, env, kid(t, 0), kid(t, 1), out, fields), u =>
  kc(String, String.eq(tg(t), "Let"), u => "{" ++ j_nat_loop_values(book, env, ks(t), 0) ++ "{" ++ j_nat_loop_names(ks(t), 0) ++
    j_region_vector_return(book, j_context(book, env, ks(t)), j_body(ks(t)), ty, out, fields) ++ "}}", u =>
  kc(String, String.eq(tg(t), "JInline") || String.eq(tg(t), "JInlineRead"), u => j_region_inline_output(book, env, t, ty, out, fields), u =>
  kc(String, String.eq(tg(t), "JUnpack"), u => "{const $unpack=$p" ++ U32.show(ix(t)) ++
    kc(String, j_region_local_vector(book, kid(t, 1)), u => "", u => ".a") ++ ";{" ++ j_region_field_bindings(ix(t), 0, qt(t)) ++
    j_region_vector_return(book, env, kid(t, 0), ty, out, fields) ++ "}}", u =>
  kc(String, String.eq(tg(t), "JIf"), u => "if(" ++ j_expr(book, env, kid(t, 0), kt("ADT", "Bool", 0, 0, Nil{}), False{}) ++ "){" ++
    j_region_vector_return(book, env, kid(t, 1), ty, out, fields) ++ "}else{" ++ j_region_vector_return(book, env, kid(t, 2), ty, out, fields) ++ "}", u =>
  kc(String, String.eq(tg(t), "JVector"), u => j_region_vector_values(book, env, ks(t), j_region_local_fields(book, ty), out, 0), u =>
  kc(String, String.eq(tg(t), "JVirtual"), u => j_region_vector_copy(out, "$w", 0, fields, False{}), u =>
    "{const $result=" ++ j_expr(book, env, t, ty, False{}) ++ ";" ++ j_region_vector_copy(out, "$result", 0, fields, True{}) ++ "}")))))))

@unsafe
def j_region_vector_values(+book: List<&2,KDef>, +env: List<&2,KTerm>, +xs: List<&2,KTerm>, +ty: KTerm, +out: String, +at: U32) -> String:
  match xs:
    case Nil{}: ""
    case Con{h, rest}:
      +head = wnf(book, ty)
      out ++ U32.show(at) ++ "=" ++ j_expr(book, env, h, kid(head, 0), False{}) ++ ";" ++
      j_region_vector_values(book, env, rest, j_app_type(head, h), out, U32.inc(at))

@unsafe
def j_region_inline_virtual(+t: KTerm) -> Bool:
  +body = j_strip(kid(t, 0))
  +last = j_strip(j_body(j_region_inline_args(t)))
  String.eq(tg(t), "JInline") && String.eq(tg(body), "JUnpack") &&
  U32.is_eq(U32.inc(ix(body)), ix(t)) && String.eq(tg(last), "JVirtual") && U32.is_eq(qt(body), ix(last))

@unsafe
def j_region_inline_virtual_bind(+at: U32, +field: U32, +total: U32) -> String:
  kc(String, U32.is_eq(field, total), u => "", u =>
    "const $p" ++ U32.show(U32.add(at, field)) ++ "=$w" ++ U32.show(field) ++ ";" ++ j_region_inline_virtual_bind(at, U32.inc(field), total))

@unsafe
def j_region_emit_output(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +out: String, +fields: U32) -> String:
  kc(String, U32.is_gt(fields, 0), u => j_region_vector_return(book, env, t, ty, out, fields), u => j_region_return(book, env, t, ty))

# Ordinary integer regions retain their existing guard cost. Floating operations
# require the host-intrinsic/protocol guard before Math-based input validation.
@unsafe
def j_region_float_terms(+todo: List<&2,KTerm>) -> Bool:
  match todo:
    case Nil{}: False{}
    case Con{t, rest}:
      kc(Bool, String.eq(nm(t), "F32") || String.starts_with(nm(t), "F32.") || String.eq(nm(t), "U32.to_f32"), u => True{},
        u => j_region_float_terms(List.append(&2, KTerm, ks(t), rest)))

@unsafe
def j_region_float_helpers(+book: List<&2,KDef>, +helpers: List<&2,KDef>) -> Bool:
  match helpers:
    case Nil{}: False{}
    case Con{d, rest}: kc(Bool, j_region_float_signature(book, dt(d), da(d)) || j_region_float_terms([dt(d), dv(d)]), u => True{}, u => j_region_float_helpers(book, rest))

@unsafe
def j_region_host_guard(+book: List<&2,KDef>, +d: KDef, +helpers: List<&2,KDef>) -> String:
  kc(String, j_fold_has(helpers) || j_region_has_residual(helpers) || j_region_float_signature(book, dt(d), da(d)) || j_region_float_terms([dt(d), dv(d)]) || j_region_float_helpers(book, helpers), u => "regionHostGuard()&&", u => "")

# Alias normalization is essential even for an unused floating input: its
# canonical-input test calls Math.fround before any body expression executes.
@unsafe
def j_region_float_signature(+book: List<&2,KDef>, +ty: KTerm, +left: U32) -> Bool:
  +head = wnf(book, ty)
  kc(Bool, U32.is_eq(left, 0), u => String.eq(nm(head), "F32"), u =>
    kc(Bool, String.eq(tg(head), "All"), u => String.eq(nm(wnf(book, kid(head, 0))), "F32") ||
      j_region_float_signature(book, kid(head, 1), U32.sub(left, 1)), u => False{}))

# Primitive comparisons on inert scalar operands preserve deferred field demand.
# No helper, constructor, conversion or Math method is evaluated by this rule.
@unsafe
def j_region_field_atom(+t: KTerm) -> Bool:
  +body = j_strip(t)
  String.eq(tg(body), "Var") || String.eq(tg(body), "Lit") ||
    (String.eq(tg(body), "Ctr") && U32.is_eq(terms_len(ks(body)), 0) && (String.eq(nm(body), "True") || String.eq(nm(body), "False")))

@unsafe
def j_region_field_compare(+book: List<&2,KDef>, +t: KTerm) -> Bool:
  +spine = j_call_spine(t, Nil{})
  (String.starts_with(nm(spine), "U32.is_") || String.starts_with(nm(spine), "F32.is_")) &&
    j_primitive_call(book, spine) && j_region_field_operands(ks(spine))

@unsafe
def j_region_field_operands(+xs: List<&2,KTerm>) -> Bool:
  match xs:
    case Nil{}: True{}
    case Con{h, rest}: j_region_field_atom(h) && j_region_field_operands(rest)

# A private Nat below 2^48 fits exactly in a Number. Change only a vector-loop
# predecessor occurring once, as the first self-tail argument: it cannot escape
# through source arithmetic, stores, results, type terms or copied helper plans.
@unsafe
def j_region_number_counter(+book: List<&2,KDef>, +d: KDef) -> Bool:
  +succ = j_strip(kid(j_strip(kid(dv(d), 1)), 0))
  U32.is_gt(j_region_vector_count(book, d), 0) && String.eq(tg(succ), "Lam") &&
    j_nat_loop_tail(j_nat_loop_unwrap(succ), dn(d), ix(succ), da(d)) &&
    U32.is_eq(j_region_counter_uses([kid(succ, 0)], ix(succ), 0), 1)

# Stop after two uses. Inspect every child, including closures and annotations;
# globally fresh frontend IDs make copied helper binders unambiguous here.
@unsafe
def j_region_counter_uses(+todo: List<&2,KTerm>, +id: U32, +count: U32) -> U32:
  match todo:
    case Nil{}: count
    case Con{t, rest}:
      kc(U32, U32.is_ge(count, 2), u => count, u =>
        j_region_counter_uses(List.append(&2, KTerm, ks(t), rest), id,
          U32.add(count, kc(U32, String.eq(tg(t), "Var") && U32.is_eq(ix(t), id), u => 1, u => 0))))
