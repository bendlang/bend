# A native Nat countdown keeps its public matcher and partial descriptor. Once
# the successor callback has all its arguments, a local loop replaces only exact
# self-tail calls on the captured predecessor. All unknown shapes fall back.

@unsafe
def j_nat_loop_native(+book: List<&2,KDef>) -> Bool:
  +owner = lookup(book, "Nat")
  +succ = wnf(book, dt(lookup(dc(owner), "Succ")))
  j_u32_native_ctor(book, "Nat", "Zero") && j_u32_native_ctor(book, "Nat", "Succ") &&
  j_primitive_type(book, wnf(book, dt(lookup(dc(owner), "Zero"))), "Nat") &&
  String.eq(tg(succ), "All") && Bool.not(U32.is_eq(qt(succ), 0)) &&
  j_primitive_type(book, wnf(book, kid(succ, 0)), "Nat") && j_primitive_type(book, wnf(book, kid(succ, 1)), "Nat")

@unsafe
def j_nat_loop_scalar(+book: List<&2,KDef>, +ty: KTerm) -> Bool:
  +head = wnf(book, ty)
  String.contains("|Nat|U32|F32|Bool|", "|" ++ nm(head) ++ "|") && j_primitive_type(book, head, nm(head))

@unsafe
def j_nat_loop_signature(+book: List<&2,KDef>, +ty: KTerm, +at: U32, +left: U32) -> Bool:
  +head = wnf(book, ty)
  kc(Bool, U32.is_eq(left, 0), u => j_region_result_type(book, head), u =>
    kc(Bool, String.eq(tg(head), "All") && Bool.not(U32.is_eq(qt(head), 0)) &&
      kc(Bool, U32.is_eq(at, 0), u => j_primitive_type(book, wnf(book, kid(head, 0)), "Nat"), u => j_nat_loop_scalar(book, kid(head, 0))),
      u => j_nat_loop_signature(book, kid(head, 1), U32.inc(at), U32.sub(left, 1)), u => False{}))

@unsafe
def j_nat_loop_lambdas(+book: List<&2,KDef>, +t: KTerm, +ty: KTerm, +left: U32) -> Bool:
  +body = j_strip(t)
  +head = wnf(book, ty)
  kc(Bool, U32.is_eq(left, 0), u => Bool.not(String.eq(tg(body), "Lam")), u =>
    kc(Bool, String.eq(tg(body), "Lam") && String.eq(j_l_name(body), "") &&
      String.eq(tg(head), "All") && Bool.not(U32.is_eq(qt(head), 0)),
      u => j_nat_loop_lambdas(book, kid(body, 0), subst(kid(head, 1), ix(head), var(nm(body), ix(body))), U32.sub(left, 1)), u => False{}))

@unsafe
def j_nat_loop_count(+t: KTerm, +at: U32) -> U32:
  kc(U32, U32.is_ge(at, 33), u => at, u =>
    kc(U32, String.eq(tg(j_strip(t)), "Lam"), u => j_nat_loop_count(kid(j_strip(t), 0), U32.inc(at)), u => at))

@unsafe
def j_nat_loop_unwrap(+t: KTerm) -> KTerm:
  +body = j_strip(t)
  kc(KTerm, String.eq(tg(body), "Lam"), u => j_nat_loop_unwrap(kid(body, 0)), u => body)

@unsafe
def j_nat_loop_distinct(+t: KTerm, +seen: List<&2,String>) -> Bool:
  +body = j_strip(t)
  kc(Bool, String.eq(tg(body), "Lam"), u => kc(Bool, has_name(seen, j_local(ix(body))), u => False{},
    u => j_nat_loop_distinct(kid(body, 0), Con{j_local(ix(body)), seen})), u => True{})

@unsafe
def j_nat_loop_bindings(+xs: List<&2,KTerm>, +pred: U32, +seen: List<&2,String>) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{h, Nil{}}: True{}
    case Con{h, rest}: kc(Bool, String.eq(tg(h), "Bind") && U32.is_eq(terms_len(ks(h)), 1) &&
      Bool.not(U32.is_eq(ix(h), pred)) && Bool.not(has_name(seen, j_local(ix(h)))),
      u => j_nat_loop_bindings(rest, pred, Con{j_local(ix(h)), seen}), u => False{})

@unsafe
def j_nat_loop_tail(+t: KTerm, +name: String, +pred: U32, +total: U32) -> Bool:
  +body = j_strip(t)
  kc(Bool, String.eq(tg(body), "Let"), u => kc(Bool, j_nat_loop_bindings(ks(body), pred, Nil{}), u => j_nat_loop_tail(j_body(ks(body)), name, pred, total), u => False{}), u =>
    j_nat_loop_call(j_call_spine(body, Nil{}), name, pred, total))

@unsafe
def j_nat_loop_call(+spine: KTerm, +name: String, +pred: U32, +total: U32) -> Bool:
  String.eq(tg(spine), "Call") && String.eq(nm(spine), name) && U32.is_eq(terms_len(ks(spine)), total) &&
  String.eq(tg(j_strip(kid(spine, 0))), "Var") && U32.is_eq(ix(j_strip(kid(spine, 0))), pred)

@unsafe
def j_nat_loop_worker(+book: List<&2,KDef>, +d: KDef) -> String:
  kc(String, j_nat_loop_shape(book, d), u =>
    j_nat_loop_public(book, d, kid(j_strip(dv(d)), 0), j_strip(kid(j_strip(kid(j_strip(dv(d)), 1)), 0)), da(d)), u => "")

@unsafe
def j_nat_loop_shape(+book: List<&2,KDef>, +d: KDef) -> Bool:
  kc(Bool, j_nat_scalar_shape(book, d), u =>
    j_nat_loop_tail(j_nat_loop_unwrap(kid(j_strip(kid(j_strip(dv(d)), 1)), 0)), dn(d), ix(j_strip(kid(j_strip(kid(j_strip(dv(d)), 1)), 0))), da(d)), u => False{})

@unsafe
def j_nat_scalar_shape(+book: List<&2,KDef>, +d: KDef) -> Bool:
  +t = j_strip(dv(d))
  kc(Bool, String.eq(dk(d), "Def") && Bool.not(db(d)) && U32.is_eq(dx(d), 0) && String.eq(tg(t), "Mat") && String.eq(nm(t), "Zero") && U32.is_eq(terms_len(ks(t)), 2),
    u => j_nat_loop_match(book, d, t, j_strip(kid(t, 1))), u => False{})

@unsafe
def j_nat_loop_match(+book: List<&2,KDef>, +d: KDef, +zero: KTerm, +succ: KTerm) -> Bool:
  kc(Bool, String.eq(tg(succ), "Mat") && String.eq(nm(succ), "Succ") && U32.is_eq(terms_len(ks(succ)), 2) &&
    String.eq(tg(j_strip(kid(succ, 1))), "Efq") && U32.is_eq(terms_len(ks(j_strip(kid(succ, 1)))), 0),
    u => j_nat_loop_checked(book, d, kid(zero, 0), j_strip(kid(succ, 0)), j_nat_loop_count(kid(succ, 0), 0)), u => False{})

@unsafe
def j_nat_loop_checked(+book: List<&2,KDef>, +d: KDef, +zero: KTerm, +succ: KTerm, +total: U32) -> Bool:
  kc(Bool, U32.is_gt(total, 1) && U32.is_le(total, 32) && U32.is_eq(da(d), total), u =>
    kc(Bool, U32.is_eq(j_nat_loop_count(zero, 0), U32.sub(total, 1)) && j_u32_bounded([dv(d)], 8192), u =>
      kc(Bool, j_nat_loop_native(book) && j_nat_loop_signature(book, dt(d), 0, total) && Bool.not(j_l_deep(dv(d), 0)), u =>
        kc(Bool, j_nat_loop_distinct(zero, Nil{}) && j_nat_loop_distinct(succ, Nil{}) &&
          j_nat_loop_lambdas(book, zero, j_arm_type(book, wnf(book, dt(d)), "Zero"), U32.sub(total, 1)) &&
          j_nat_loop_lambdas(book, succ, j_arm_type(book, wnf(book, dt(d)), "Succ"), total), u =>
            True{}, u => False{}), u => False{}), u => False{}), u => False{})

@unsafe
def j_nat_loop_public(+book: List<&2,KDef>, +d: KDef, +zero: KTerm, +succ: KTerm, +total: U32) -> String:
  j_nat_loop_region(book, d, zero, succ, total, j_region_plan(book, d, zero, succ, total))

@unsafe
def j_nat_loop_region(+book: List<&2,KDef>, +d: KDef, +zero: KTerm, +succ: KTerm, +total: U32, +plan: Maybe<&2,JRegion>) -> String:
  match plan:
    case None{}:
      ""
    case Some{region}:
      match region:
        case JRegion{fastZero, fastSucc, helpers}:
          +fast: KDef = KDef{dn(d), dk(d), da(d), dx(d), dt(d), k_with_children(j_strip(dv(d)), [fastZero, kid(j_strip(dv(d)), 1)]), dc(d), db(d), du(d)}
          "scalarCapture(" ++ j_quote(dn(d)) ++ ",(()=>{" ++ j_region_declarations(book, helpers) ++ "const $guards=[" ++ j_quote(dn(d)) ++ "," ++ j_region_names(helpers) ++ "];return " ++
          j_nat_loop_wrapper(book, d, zero, total,
            "if($entered&&" ++ j_region_inputs(book, j_arm_type(book, wnf(book, dt(d)), "Succ"), 0, total, True{}) ++ "&&scalarGuard($guards)){/* private scalar region */" ++
            j_nat_loop_body(book, fast, fastSucc, total) ++ "}" ++
            j_nat_loop_generic(book, Nil{}, succ, j_arm_type(book, wnf(book, dt(d)), "Succ"), 0)) ++ ";})())"

@unsafe
def j_nat_loop_wrapper(+book: List<&2,KDef>, +d: KDef, +zero: KTerm, +total: U32, +body: String) -> String:
  "matcher(\"Zero\",()=>" ++ j_expr(book, Nil{}, zero, j_arm_type(book, wnf(book, dt(d)), "Zero"), False{}) ++ ",()=>" ++
  "matcher1(\"Succ\",()=>fn(" ++ U32.show(total) ++ ",exactCode(function(a,$entered){/* private Nat loop */" ++ j_nat_loop_slots(total, 0) ++ body ++ "}))))"

# The fallback has the original generic self call and delayed result. Reuse the
# slots read at entry, including observable getters, without entering a loop.
@unsafe
def j_nat_loop_generic(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +at: U32) -> String:
  j_region_body(book, env, t, ty, at, "return ", True{})

@unsafe
def j_region_body(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +at: U32, +result: String, +tail: Bool) -> String:
  +body = j_strip(t)
  +head = wnf(book, ty)
  kc(String, String.eq(tg(body), "Lam"), u =>
    "const " ++ j_local(ix(body)) ++ "=$s" ++ U32.show(at) ++ ";" ++
    j_region_body(book, Con{kt("Env", "", ix(body), 0, [kid(head, 0)]), env}, kid(body, 0), subst(kid(head, 1), ix(head), var(nm(body), ix(body))), U32.inc(at), result, tail),
    u => result ++ j_expr(book, env, body, head, tail) ++ ";")

@unsafe
def j_nat_loop_body(+book: List<&2,KDef>, +d: KDef, +succ: KTerm, +total: U32) -> String:
  "for(;;){" ++ j_nat_loop_enter(book, Nil{}, succ, j_arm_type(book, wnf(book, dt(d)), "Succ"), d, 0, total) ++ "}"

@unsafe
def j_region_inputs(+book: List<&2,KDef>, +ty: KTerm, +at: U32, +total: U32, +predecessor: Bool) -> String:
  kc(String, U32.is_eq(at, total), u => "true", u =>
    j_nat_loop_input(nm(wnf(book, kid(wnf(book, ty), 0))), "$s" ++ U32.show(at), kc(U32, predecessor, u => at, u => 1)) ++ "&&" ++
    j_region_inputs(book, kid(wnf(book, ty), 1), U32.inc(at), total, predecessor))

@unsafe
def j_nat_loop_input(+kind: String, +slot: String, +at: U32) -> String:
  kc(String, String.eq(kind, "U32"), u => "(typeof " ++ slot ++ "===\"number\"&&Number.isInteger(" ++ slot ++ ")&&" ++ slot ++ ">=0&&" ++ slot ++ "<=4294967295)", u =>
  kc(String, String.eq(kind, "Bool"), u => "(typeof " ++ slot ++ "===\"boolean\")", u =>
  kc(String, String.eq(kind, "Nat"), u => "(typeof " ++ slot ++ "===\"bigint\"&&" ++ slot ++ ">=0n&&" ++ slot ++ kc(String, U32.is_eq(at, 0), u => "<", u => "<=") ++ "281474976710655n)", u =>
  kc(String, String.eq(kind, "F32"), u => "(typeof " ++ slot ++ "===\"number\"&&(Math.fround(" ++ slot ++ ")===" ++ slot ++ "||Number.isNaN(" ++ slot ++ ")))", u => "false"))))

@unsafe
def j_nat_loop_slots(+total: U32, +at: U32) -> String:
  kc(String, U32.is_eq(at, total), u => "", u => "let $s" ++ U32.show(at) ++ "=a[" ++ U32.show(at) ++ "];" ++ j_nat_loop_slots(total, U32.inc(at)))

@unsafe
def j_nat_loop_enter(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +d: KDef, +at: U32, +total: U32) -> String:
  +body = j_strip(t)
  +head = wnf(book, ty)
  kc(String, String.eq(tg(body), "Lam"), u =>
    "const " ++ j_local(ix(body)) ++ "=$s" ++ U32.show(at) ++ ";" ++
    j_nat_loop_enter(book, Con{kt("Env", "", ix(body), 0, [kid(head, 0)]), env}, kid(body, 0), subst(kid(head, 1), ix(head), var(nm(body), ix(body))), d, U32.inc(at), total),
    u => j_nat_loop_emit(book, env, body, head, d, total))

@unsafe
def j_nat_loop_emit(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +d: KDef, +total: U32) -> String:
  kc(String, String.eq(tg(t), "Ann"), u => j_nat_loop_emit(book, env, kid(t, 0), kid(t, 1), d, total), u =>
  kc(String, String.eq(tg(t), "Let"), u => "{" ++ j_nat_loop_values(book, env, ks(t), 0) ++ "{" ++ j_nat_loop_names(ks(t), 0) ++
    j_nat_loop_emit(book, j_context(book, env, ks(t)), j_body(ks(t)), ty, d, total) ++ "}}", u =>
    j_nat_loop_next(book, env, ks(j_call_spine(t, Nil{})), dt(d), 0) ++
    "if($n0===0n){const a=[" ++ j_nat_loop_zero_args(total, 1) ++ "];" ++
      j_lambda_code(book, Nil{}, kid(j_strip(dv(d)), 0), j_arm_type(book, wnf(book, dt(d)), "Zero"), 0) ++ "}" ++
    "$s0=$n0-1n;" ++ j_nat_loop_assign(total, 1) ++ "continue;"))

# Values are outside the block that introduces all parallel binders. The body
# then sees fresh immutable aliases on every iteration, including in closures.
@unsafe
def j_nat_loop_values(+book: List<&2,KDef>, +env: List<&2,KTerm>, +xs: List<&2,KTerm>, +at: U32) -> String:
  match xs:
    case Nil{}: ""
    case Con{h, Nil{}}: ""
    case Con{h, rest}:
      "const $v" ++ U32.show(at) ++ "=" ++ kc(String, U32.is_eq(qt(h), 0), u => "null", u => j_expr(book, env, kid(h, 0), atom("Absent"), False{})) ++ ";" ++ j_nat_loop_values(book, env, rest, U32.inc(at))

@unsafe
def j_nat_loop_names(+xs: List<&2,KTerm>, +at: U32) -> String:
  match xs:
    case Nil{}: ""
    case Con{h, Nil{}}: ""
    case Con{h, rest}: "const " ++ j_local(ix(h)) ++ "=$v" ++ U32.show(at) ++ ";" ++ j_nat_loop_names(rest, U32.inc(at))

@unsafe
def j_nat_loop_next(+book: List<&2,KDef>, +env: List<&2,KTerm>, +args: List<&2,KTerm>, +ty: KTerm, +at: U32) -> String:
  j_nat_loop_next_head(book, env, args, wnf(book, ty), at)

@unsafe
def j_nat_loop_next_head(+book: List<&2,KDef>, +env: List<&2,KTerm>, +args: List<&2,KTerm>, +head: KTerm, +at: U32) -> String:
  match args:
    case Nil{}: ""
    case Con{h, rest}:
      "const $n" ++ U32.show(at) ++ "=" ++ j_expr(book, env, h, kid(head, 0), False{}) ++ ";" ++
      j_nat_loop_next(book, env, rest, j_app_type(head, h), U32.inc(at))

@unsafe
def j_nat_loop_zero_args(+total: U32, +at: U32) -> String:
  kc(String, U32.is_eq(at, total), u => "", u => "$n" ++ U32.show(at) ++ "," ++ j_nat_loop_zero_args(total, U32.inc(at)))

@unsafe
def j_nat_loop_assign(+total: U32, +at: U32) -> String:
  kc(String, U32.is_eq(at, total), u => "", u => "$s" ++ U32.show(at) ++ "=$n" ++ U32.show(at) ++ ";" ++ j_nat_loop_assign(total, U32.inc(at)))
