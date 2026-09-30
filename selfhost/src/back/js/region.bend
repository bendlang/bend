# Private scalar copies for the already checked Nat worker. Analysis always
# reads original terms; the emitter-only JSlot/JCall/JIf nodes are never reduced.
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
  String.contains("|U32|Bool|Nat|", "|" ++ nm(head) ++ "|") && j_primitive_type(book, head, nm(head))

# Helper parameters/results deliberately exclude Nat and F32. Nat is retained
# in worker state and primitive shift operands, without changing representation.
@unsafe
def j_region_signature(+book: List<&2,KDef>, +ty: KTerm, +left: U32) -> Bool:
  +head = wnf(book, ty)
  kc(Bool, U32.is_eq(left, 0), u =>
    String.contains("|U32|Bool|", "|" ++ nm(head) ++ "|") && j_primitive_type(book, head, nm(head)), u =>
    kc(Bool, String.eq(tg(head), "All") && Bool.not(U32.is_eq(qt(head), 0)) &&
      j_region_signature(book, kid(head, 0), 0),
      u => j_region_signature(book, kid(head, 1), U32.sub(left, 1)), u => False{}))

@unsafe
def j_region_capture_eligible(+book: List<&2,KDef>, +d: KDef) -> Bool:
  kc(Bool, String.eq(dk(d), "Def") && Bool.not(db(d)) && U32.is_eq(dx(d), 0) &&
    U32.is_gt(da(d), 0) && U32.is_le(da(d), 32), u =>
    kc(Bool, String.eq(tg(j_strip(dv(d))), "Lam") || String.eq(tg(j_strip(dv(d))), "Mat"),
      u => j_region_signature(book, dt(d), da(d)), u => False{}), u => False{})

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
        kc(KTerm, String.eq(tg(h), "JEnv"), u => kt("JSlot", "", qt(h), 0, Nil{}), u => t),
        u => j_region_variable(rest, t))

@unsafe
def j_region_def_count(+ds: List<&2,KDef>) -> U32:
  match ds:
    case Nil{}: 0
    case Con{h, rest}: U32.inc(j_region_def_count(rest))

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
  kc(JRegionBuild, String.eq(tg(ty), "All") && Bool.not(U32.is_eq(qt(ty), 0)) && j_region_scalar(book, kid(ty, 0)), u =>
    kc(JRegionBuild, String.eq(tg(t), "Lam") && String.eq(j_l_name(t), ""), u =>
      j_region_prefix_lam(t, keep, j_region_prefix(book,
        Con{kt(kc(String, keep, u => "Env", u => "JEnv"), "", ix(t), at, [wnf(book, kid(ty, 0))]), env},
        kid(t, 0), subst(kid(ty, 1), ix(ty), var(nm(t), ix(t))), U32.inc(at), U32.sub(left, 1), keep, tail, active, depth, s)), u =>
      kc(JRegionBuild, Bool.not(keep) && String.eq(tg(t), "Mat") && j_primitive_type(book, wnf(book, kid(ty, 0)), "Bool"),
        u => j_region_match(book, env, t, ty, at, left, active, depth, s), u => j_region_fail(s))), u => j_region_fail(s))

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

@unsafe
def j_region_expr(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +tail: String, +active: List<&2,String>, +depth: U32, +level: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s) && U32.is_gt(j_region_fuel(s), 0) && U32.is_lt(level, 128), u =>
    kc(JRegionBuild, j_region_scalar(book, ty), u =>
      j_region_expr_on(book, env, t, wnf(book, ty), tail, active, depth, U32.inc(level), j_region_tick(s)), u => j_region_fail(s)), u => j_region_fail(s))

@unsafe
def j_region_expr_on(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +tail: String, +active: List<&2,String>, +depth: U32, +level: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, String.eq(tg(t), "Ann"), u =>
    kc(JRegionBuild, j_region_scalar(book, kid(t, 1)) && String.eq(nm(wnf(book, kid(t, 1))), nm(ty)),
      u => j_region_expr(book, env, kid(t, 0), ty, tail, active, depth, level, s), u => j_region_fail(s)), u =>
  kc(JRegionBuild, String.eq(tg(t), "Var"), u =>
    kc(JRegionBuild, j_region_scalar(book, j_env(env, ix(t))) && String.eq(nm(wnf(book, j_env(env, ix(t)))), nm(ty)),
      u => j_region_result(s, j_region_annotate(j_region_variable(env, t), ty)), u => j_region_fail(s)), u =>
  kc(JRegionBuild, String.eq(tg(t), "Lit"), u =>
    kc(JRegionBuild, String.eq(nm(t), nm(ty)) && (String.eq(nm(t), "U32") || String.eq(nm(t), "Nat")),
      u => j_region_result(s, j_region_annotate(t, ty)), u => j_region_fail(s)), u =>
  kc(JRegionBuild, String.eq(tg(t), "Ctr"), u =>
    kc(JRegionBuild, String.eq(nm(ty), "Bool") && U32.is_eq(terms_len(ks(t)), 0) && (String.eq(nm(t), "True") || String.eq(nm(t), "False")),
      u => j_region_result(s, j_region_annotate(t, ty)), u => j_region_fail(s)), u =>
  kc(JRegionBuild, String.eq(tg(t), "Let"), u =>
    j_region_let_done(t, ty, j_region_bindings(book, env, j_context(book, env, ks(t)), ks(t), ty, tail, active, depth, level, 0, s)), u =>
  kc(JRegionBuild, String.eq(tg(t), "App"), u =>
    j_region_call(book, env, j_call_spine(t, Nil{}), ty, tail, active, depth, level, s), u => j_region_fail(s)))))))

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
        Bool.not(U32.is_eq(qt(bind), 0)) && U32.is_eq(terms_len(ks(bind)), 1), u =>
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
      j_region_call_done(spine, ty, False{}, j_region_args(book, env, ks(spine), dt(d), active, depth, level, s)), u =>
      j_region_call_helper(book, env, spine, ty, active, depth, level, j_region_helper(book, d, active, depth, s))), u => j_region_fail(s))

@unsafe
def j_region_call_helper(+book: List<&2,KDef>, +env: List<&2,KTerm>, +spine: KTerm, +ty: KTerm, +active: List<&2,String>, +depth: U32, +level: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s), u =>
    j_region_call_done(spine, ty, True{}, j_region_args(book, env, ks(spine), dt(lookup(book, nm(spine))), active, depth, level, s)), u => s)

@unsafe
def j_region_call_done(+spine: KTerm, +ty: KTerm, +private: Bool, +s: JRegionBuild) -> JRegionBuild:
  j_region_result(s, j_region_annotate(kc(KTerm, private,
    u => kt("JCall", nm(spine), 0, 0, ks(j_region_term(s))),
    u => j_region_app(ref(nm(spine)), ks(j_region_term(s)))), ty))

@unsafe
def j_region_app(+head: KTerm, +args: List<&2,KTerm>) -> KTerm:
  match args:
    case Nil{}: head
    case Con{h, rest}: j_region_app(kt("App", "", 0, 0, [head, h]), rest)

@unsafe
def j_region_args(+book: List<&2,KDef>, +env: List<&2,KTerm>, +args: List<&2,KTerm>, +ty: KTerm, +active: List<&2,String>, +depth: U32, +level: U32, +s: JRegionBuild) -> JRegionBuild:
  match args:
    case Nil{}:
      kc(JRegionBuild, j_region_scalar(book, ty), u => j_region_result(s, kt("JList", "", 0, 0, Nil{})), u => j_region_fail(s))
    case Con{h, rest}:
      +head = wnf(book, ty)
      kc(JRegionBuild, j_region_valid(s) && String.eq(tg(head), "All") && Bool.not(U32.is_eq(qt(head), 0)), u =>
        j_region_arg_first(book, env, rest, j_app_type(head, h), active, depth, level,
          j_region_expr(book, env, h, kid(head, 0), "", active, depth, level, s)), u => j_region_fail(s))

@unsafe
def j_region_arg_first(+book: List<&2,KDef>, +env: List<&2,KTerm>, +rest: List<&2,KTerm>, +ty: KTerm, +active: List<&2,String>, +depth: U32, +level: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s), u => j_region_list_prepend(j_region_term(s),
    j_region_args(book, env, rest, ty, active, depth, level, s)), u => s)

@unsafe
def j_region_helper(+book: List<&2,KDef>, +d: KDef, +active: List<&2,String>, +depth: U32, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, String.eq(dk(lookup(j_region_helpers(s), dn(d))), "Def"), u => s, u =>
    kc(JRegionBuild, j_region_valid(s) && U32.is_lt(depth, 16) && U32.is_lt(j_region_def_count(j_region_helpers(s)), 32) &&
      Bool.not(has_name(active, dn(d))), u =>
      kc(JRegionBuild, j_region_capture_eligible(book, d), u =>
        kc(JRegionBuild, j_u32_bounded([dv(d)], 8192), u =>
          j_region_helper_done(d, j_region_prefix(book, Nil{}, dv(d), dt(d), 0, da(d), False{}, "", Con{dn(d), active}, U32.inc(depth), s)),
          u => j_region_fail(s)), u => j_region_fail(s)), u => j_region_fail(s)))

@unsafe
def j_region_helper_done(+d: KDef, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s) && U32.is_lt(j_region_def_count(j_region_helpers(s)), 32), u =>
    JRegionBuild{j_region_term(s), Con{KDef{dn(d), dk(d), da(d), dx(d), dt(d), j_region_term(s), dc(d), db(d), du(d)}, j_region_helpers(s)}, j_region_fuel(s), True{}},
    u => j_region_fail(s))

@unsafe
def j_region_names(+helpers: List<&2,KDef>) -> String:
  match helpers:
    case Nil{}: ""
    case Con{d, Nil{}}: j_quote(dn(d))
    case Con{d, rest}: j_quote(dn(d)) ++ "," ++ j_region_names(rest)

@unsafe
def j_region_declarations(+book: List<&2,KDef>, +helpers: List<&2,KDef>) -> String:
  "const $R=Object.create(null);" ++ j_region_definitions(book, helpers)

@unsafe
def j_region_definitions(+book: List<&2,KDef>, +helpers: List<&2,KDef>) -> String:
  match helpers:
    case Nil{}: ""
    case Con{d, rest}:
      "$R[" ++ j_quote(dn(d)) ++ "]=function(" ++ j_region_parameters(0, da(d)) ++ "){return " ++
      j_expr(book, Nil{}, dv(d), kid(dv(d), 1), False{}) ++ ";};" ++ j_region_definitions(book, rest)

@unsafe
def j_region_parameters(+at: U32, +total: U32) -> String:
  kc(String, U32.is_eq(at, total), u => "", u =>
    "$p" ++ U32.show(at) ++ kc(String, U32.is_eq(U32.inc(at), total), u => "", u => "," ++ j_region_parameters(U32.inc(at), total)))
