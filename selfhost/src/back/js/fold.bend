# Closed structural folds over existing tagged records. The public boundary
# remains scalar; only locally proved pure sum values reach these helpers.
@unsafe
def j_fold_type(+book: List<&2,KDef>, +ty: KTerm) -> Bool:
  +head = wnf(book, ty)
  +owner = lookup(book, nm(head))
  String.eq(tg(head), "ADT") && U32.is_eq(terms_len(ks(head)), 0) && List.is_empty(&2, String, rm(head)) &&
    String.eq(dk(owner), "ADT") && Bool.not(db(owner)) && U32.is_eq(da(owner), 0) && U32.is_eq(dx(owner), 0) &&
    U32.is_ge(j_region_def_count(dc(owner)), 2) && U32.is_le(j_region_def_count(dc(owner)), 8) &&
    j_pure_type(book, head) && j_fold_ctors(book, nm(head), dc(owner))

@unsafe
def j_fold_ctors(+book: List<&2,KDef>, +name: String, +ctors: List<&2,KDef>) -> Bool:
  match ctors:
    case Nil{}: True{}
    case Con{c, rest}:
      String.eq(dk(c), "Ctr") && Bool.not(db(c)) && U32.is_eq(dx(c), 0) && U32.is_le(da(c), 2) &&
        j_fold_fields(book, dt(c), name, da(c)) && j_fold_ctors(book, name, rest)

@unsafe
def j_fold_fields(+book: List<&2,KDef>, +ty: KTerm, +owner: String, +left: U32) -> Bool:
  +head = wnf(book, ty)
  kc(Bool, U32.is_eq(left, 0), u => String.eq(tg(head), "ADT") && String.eq(nm(head), owner) &&
    U32.is_eq(terms_len(ks(head)), 0) && List.is_empty(&2, String, rm(head)), u =>
    String.eq(tg(head), "All") && Bool.not(U32.is_eq(qt(head), 0)) &&
      (j_primitive_type(book, wnf(book, kid(head, 0)), "U32") ||
        (String.eq(tg(wnf(book, kid(head, 0))), "ADT") && String.eq(nm(wnf(book, kid(head, 0))), owner) &&
          U32.is_eq(terms_len(ks(wnf(book, kid(head, 0)))), 0) && List.is_empty(&2, String, rm(wnf(book, kid(head, 0)))))) &&
      j_fold_fields(book, kid(head, 1), owner, U32.sub(left, 1)))

@unsafe
def j_fold_signature(+book: List<&2,KDef>, +ty: KTerm, +left: U32) -> Bool:
  +head = wnf(book, ty)
  kc(Bool, U32.is_eq(left, 0), u => j_primitive_type(book, head, "U32"), u =>
    String.eq(tg(head), "All") && Bool.not(U32.is_eq(qt(head), 0)) &&
      j_primitive_type(book, wnf(book, kid(head, 0)), "U32") && j_fold_signature(book, kid(head, 1), U32.sub(left, 1)))

@unsafe
def j_fold_plan(+book: List<&2,KDef>, +d: KDef) -> KTerm:
  +head = wnf(book, dt(d))
  kc(KTerm, String.eq(dk(d), "Def") && Bool.not(db(d)) && U32.is_eq(dx(d), 0) && U32.is_gt(da(d), 0) && U32.is_le(da(d), 8) &&
    String.eq(tg(head), "All") && Bool.not(U32.is_eq(qt(head), 0)) && j_fold_type(book, kid(head, 0)) &&
    j_fold_signature(book, kid(head, 1), U32.sub(da(d), 1)) && j_u32_bounded([dv(d)], 8192) && Bool.not(j_l_deep(dv(d), 0)), u =>
    j_fold_plan_done(nm(wnf(book, kid(head, 0))),
      j_fold_cases(book, d, dc(lookup(book, nm(wnf(book, kid(head, 0))))), j_strip(dv(d)), Nil{})), u => atom("Absent"))

@unsafe
def j_fold_plan_done(+owner: String, +cases: List<&2,KTerm>) -> KTerm:
  kc(KTerm, j_fold_cases_valid(cases) && Bool.not(List.is_empty(&2, KTerm, cases)),
    u => kt("JFold", owner, 0, 0, cases), u => atom("Absent"))

@unsafe
def j_fold_cases_valid(+cases: List<&2,KTerm>) -> Bool:
  match cases:
    case Nil{}: True{}
    case Con{h, rest}: String.eq(tg(h), "JFoldCase") && j_fold_cases_valid(rest)

# A complete constructor permutation ends at Efq. Duplicate, partial, default,
# lifted and conditional bodies cannot acquire a fold plan.
@unsafe
def j_fold_cases(+book: List<&2,KDef>, +d: KDef, +ctors: List<&2,KDef>, +t: KTerm, +seen: List<&2,String>) -> List<&2,KTerm>:
  +body = j_strip(t)
  kc(List<&2,KTerm>, String.eq(tg(body), "Efq") && U32.is_eq(terms_len(ks(body)), 0), u =>
    kc(List<&2,KTerm>, U32.is_eq(norm_names_len(seen), j_region_def_count(ctors)), u => Nil{}, u => [atom("Absent")]), u =>
    kc(List<&2,KTerm>, String.eq(tg(body), "Mat") && U32.is_eq(terms_len(ks(body)), 2) &&
      String.eq(dk(lookup(ctors, nm(body))), "Ctr") && Bool.not(has_name(seen, nm(body))), u =>
      Con{j_fold_arm(book, d, lookup(ctors, nm(body)), kid(body, 0)),
        j_fold_cases(book, d, ctors, kid(body, 1), Con{nm(body), seen})}, u => [atom("Absent")]))

@unsafe
def j_fold_arm(+book: List<&2,KDef>, +d: KDef, +c: KDef, +arm: KTerm) -> KTerm:
  +total = U32.add(da(c), U32.sub(da(d), 1))
  kc(KTerm, j_nat_loop_lambdas(book, arm, j_arm_type(book, wnf(book, dt(d)), dn(c)), total) && j_nat_loop_distinct(arm, Nil{}), u =>
    j_fold_arm_done(book, d, c, j_nat_loop_unwrap(arm),
      j_fold_binders(book, arm, j_arm_type(book, wnf(book, dt(d)), dn(c)),
        nm(wnf(book, kid(wnf(book, dt(d)), 0))), da(c), 0, 1)), u => atom("Absent"))

@unsafe
def j_fold_binders(+book: List<&2,KDef>, +t: KTerm, +ty: KTerm, +owner: String, +fields: U32, +at: U32, +arg: U32) -> List<&2,KTerm>:
  +body = j_strip(t)
  +head = wnf(book, ty)
  kc(List<&2,KTerm>, String.eq(tg(body), "Lam"), u =>
    Con{kt(kc(String, U32.is_lt(at, fields), u => kc(String, String.eq(nm(wnf(book, kid(head, 0))), owner),
      u => "JFoldChild", u => "JFoldField"), u => "JFoldArg"), nm(body), ix(body),
      kc(U32, U32.is_lt(at, fields), u => at, u => arg), [kt("ADT", "U32", 0, 0, Nil{})]),
      j_fold_binders(book, kid(body, 0), subst(kid(head, 1), ix(head), var(nm(body), ix(body))), owner, fields, U32.inc(at),
        kc(U32, U32.is_lt(at, fields), u => arg, u => U32.inc(arg)))}, u => Nil{})

@unsafe
def j_fold_arm_done(+book: List<&2,KDef>, +d: KDef, +c: KDef, +body: KTerm, +binders: List<&2,KTerm>) -> KTerm:
  +calls = j_fold_calls(body, dn(d))
  kc(KTerm, j_fold_expr_ok(book, d, body, binders, 128) &&
    U32.is_eq(terms_len(calls), j_fold_children(binders)) && j_fold_calls_unique(calls, Nil{}), u =>
    j_fold_arm_checked(c, binders, calls, j_region_expr(book, binders, j_fold_rewrite(body, dn(d)), kt("ADT", "U32", 0, 0, Nil{}),
      "", Nil{}, 0, 0, JRegionBuild{atom("Absent"), Nil{}, 8192, True{}})), u => atom("Absent"))

@unsafe
def j_fold_arm_checked(+c: KDef, +binders: List<&2,KTerm>, +calls: List<&2,KTerm>, +s: JRegionBuild) -> KTerm:
  kc(KTerm, j_region_valid(s) && List.is_empty(&2, KDef, j_region_helpers(s)), u =>
    kt("JFoldCase", dn(c), da(c), 0, [j_region_term(s), kt("JFoldBindings", "", 0, 0, binders), kt("JFoldOrder", "", 0, 0, calls)]),
    u => atom("Absent"))

@unsafe
def j_fold_find(+binders: List<&2,KTerm>, +id: U32) -> KTerm:
  match binders:
    case Nil{}: atom("Absent")
    case Con{h, rest}: kc(KTerm, U32.is_eq(ix(h), id), u => h, u => j_fold_find(rest, id))

@unsafe
def j_fold_children(+binders: List<&2,KTerm>) -> U32:
  match binders:
    case Nil{}: 0
    case Con{h, rest}: U32.add(kc(U32, String.eq(tg(h), "JFoldChild"), u => 1, u => 0), j_fold_children(rest))

@unsafe
def j_fold_call(+d: KDef, +spine: KTerm, +binders: List<&2,KTerm>) -> Bool:
  String.eq(tg(spine), "Call") && String.eq(nm(spine), dn(d)) && U32.is_eq(terms_len(ks(spine)), da(d)) &&
    String.eq(tg(j_strip(kid(spine, 0))), "Var") && String.eq(tg(j_fold_find(binders, ix(j_strip(kid(spine, 0))))), "JFoldChild") &&
    j_fold_call_args(ks(spine), binders)

@unsafe
def j_fold_call_args(+args: List<&2,KTerm>, +binders: List<&2,KTerm>) -> Bool:
  match binders:
    case Nil{}: True{}
    case Con{h, rest}:
      (Bool.not(String.eq(tg(h), "JFoldArg")) || (String.eq(tg(j_strip(terms_at(args, qt(h)))), "Var") &&
        U32.is_eq(ix(j_strip(terms_at(args, qt(h)))), ix(h)))) && j_fold_call_args(args, rest)

# Only strict scalar expressions are admitted. No Let, lambda, matcher,
# conditional helper or changing recursive scalar argument can alter demand.
@unsafe
def j_fold_expr_ok(+book: List<&2,KDef>, +d: KDef, +t: KTerm, +binders: List<&2,KTerm>, +fuel: U32) -> Bool:
  +body = j_strip(t)
  +spine = j_call_spine(body, Nil{})
  kc(Bool, U32.is_gt(fuel, 0), u =>
    kc(Bool, String.eq(tg(body), "Var"), u => String.eq(tg(j_fold_find(binders, ix(body))), "JFoldField") || String.eq(tg(j_fold_find(binders, ix(body))), "JFoldArg"), u =>
    kc(Bool, String.eq(tg(body), "Lit"), u => True{}, u =>
    kc(Bool, String.eq(tg(body), "App"), u => j_fold_call(d, spine, binders) ||
      (j_primitive_call(book, spine) && j_fold_args_ok(book, d, ks(spine), binders, U32.sub(fuel, 1))), u => False{}))), u => False{})

@unsafe
def j_fold_args_ok(+book: List<&2,KDef>, +d: KDef, +args: List<&2,KTerm>, +binders: List<&2,KTerm>, +fuel: U32) -> Bool:
  match args:
    case Nil{}: True{}
    case Con{h, rest}: j_fold_expr_ok(book, d, h, binders, fuel) && j_fold_args_ok(book, d, rest, binders, fuel)

@unsafe
def j_fold_calls(+t: KTerm, +name: String) -> List<&2,KTerm>:
  +body = j_strip(t)
  +spine = j_call_spine(body, Nil{})
  kc(List<&2,KTerm>, String.eq(tg(body), "App"), u =>
    kc(List<&2,KTerm>, String.eq(nm(spine), name), u => [j_strip(kid(spine, 0))], u => j_fold_calls_args(ks(spine), name)), u => Nil{})

@unsafe
def j_fold_calls_args(+args: List<&2,KTerm>, +name: String) -> List<&2,KTerm>:
  match args:
    case Nil{}: Nil{}
    case Con{h, rest}: List.append(&2, KTerm, j_fold_calls(h, name), j_fold_calls_args(rest, name))

@unsafe
def j_fold_calls_unique(+calls: List<&2,KTerm>, +seen: List<&2,String>) -> Bool:
  match calls:
    case Nil{}: True{}
    case Con{h, rest}: Bool.not(has_name(seen, U32.show(ix(h)))) && j_fold_calls_unique(rest, Con{U32.show(ix(h)), seen})

@unsafe
def j_fold_rewrite(+t: KTerm, +name: String) -> KTerm:
  +body = j_strip(t)
  +spine = j_call_spine(body, Nil{})
  kc(KTerm, String.eq(tg(body), "App"), u => kc(KTerm, String.eq(nm(spine), name),
    u => j_strip(kid(spine, 0)), u => j_region_app(ref(nm(spine)), j_fold_rewrite_args(ks(spine), name))), u => body)

@unsafe
def j_fold_rewrite_args(+args: List<&2,KTerm>, +name: String) -> List<&2,KTerm>:
  match args:
    case Nil{}: Nil{}
    case Con{h, rest}: Con{j_fold_rewrite(h, name), j_fold_rewrite_args(rest, name)}

# Reuse a frame per active depth. The field order is the original strict
# selfcall order, not constructor declaration order. Shared subtrees are read,
# never changed, and traversed each time the source calls the fold.
@unsafe
def j_fold_emit(+book: List<&2,KDef>, +d: KDef) -> String:
  "const $frames=[];let $top=0,$node=$p0,$value;$fold:for(;;){switch($node.$){" ++
    j_fold_visit(book, ks(dv(d)), 0) ++ "default:throw Error('private sum invariant');}" ++
    "while($top){const $frame=$frames[$top-1];switch($frame.tag){" ++ j_fold_unwind(book, ks(dv(d)), 0) ++
    "default:throw Error('private fold frame');}}return $value;}"

@unsafe
def j_fold_visit(+book: List<&2,KDef>, +cases: List<&2,KTerm>, +tag: U32) -> String:
  match cases:
    case Nil{}: ""
    case Con{c, rest}:
      "case " ++ j_quote(nm(c)) ++ ":{" ++
      kc(String, List.is_empty(&2, KTerm, ks(kid(c, 2))), u => j_fold_combine(book, c, "$node", False{}) ++ "break;", u =>
        "let $frame=$top<$frames.length?$frames[$top]:null;if(!$frame)$frame=$frames[$top]={node:null,tag:0,phase:0,value:0};$frame.node=$node;$frame.tag=" ++ U32.show(tag) ++
        ";$frame.phase=0;++$top;$node=$node.a[" ++ U32.show(qt(j_fold_find(ks(kid(c, 1)), ix(kid(kid(c, 2), 0))))) ++ "];continue $fold;") ++
      "}" ++ j_fold_visit(book, rest, U32.inc(tag))

@unsafe
def j_fold_unwind(+book: List<&2,KDef>, +cases: List<&2,KTerm>, +tag: U32) -> String:
  match cases:
    case Nil{}: ""
    case Con{c, rest}:
      kc(String, List.is_empty(&2, KTerm, ks(kid(c, 2))), u => "", u =>
        "case " ++ U32.show(tag) ++ ":{" ++
        kc(String, U32.is_eq(terms_len(ks(kid(c, 2))), 2), u =>
          "if($frame.phase===0){$frame.value=$value;$frame.phase=1;$node=$frame.node.a[" ++
          U32.show(qt(j_fold_find(ks(kid(c, 1)), ix(kid(kid(c, 2), 1))))) ++ "];continue $fold;}", u => "") ++
        j_fold_combine(book, c, "$frame.node", True{}) ++ "--$top;break;}") ++ j_fold_unwind(book, rest, U32.inc(tag))

@unsafe
def j_fold_combine(+book: List<&2,KDef>, +c: KTerm, +node: String, +unwind: Bool) -> String:
  j_fold_bind(ks(kid(c, 1)), ks(kid(c, 2)), node, unwind) ++
    "$value=" ++ j_expr(book, ks(kid(c, 1)), kid(c, 0), kt("ADT", "U32", 0, 0, Nil{}), False{}) ++ ";"

@unsafe
def j_fold_bind(+binders: List<&2,KTerm>, +order: List<&2,KTerm>, +node: String, +unwind: Bool) -> String:
  match binders:
    case Nil{}: ""
    case Con{h, rest}:
      "const " ++ j_local(ix(h)) ++ "=" ++
      kc(String, String.eq(tg(h), "JFoldArg"), u => "$p" ++ U32.show(qt(h)), u =>
        kc(String, String.eq(tg(h), "JFoldChild") && unwind, u =>
          kc(String, U32.is_eq(terms_len(order), 2) && U32.is_eq(ix(h), ix(terms_at(order, 0))), u => "$frame.value", u => "$value"),
          u => node ++ ".a[" ++ U32.show(qt(h)) ++ "]")) ++ ";" ++ j_fold_bind(rest, order, node, unwind)

@unsafe
def j_fold_helper(+book: List<&2,KDef>, +d: KDef, +active: List<&2,String>, +depth: U32, +s: JRegionBuild, +fold: KTerm) -> JRegionBuild:
  kc(JRegionBuild, String.eq(tg(fold), "JFold"), u => j_region_helper_done(d, j_region_result(s, fold)), u =>
    kc(JRegionBuild, j_nat_local_shape(book, d),
      u => j_region_nested(book, d, Con{dn(d), active}, U32.inc(depth), s),
      u => j_region_helper_done(d, j_region_prefix(book, Nil{}, dv(d), dt(d), 0, da(d), False{}, "", Con{dn(d), active}, U32.inc(depth), s))))

# Only ordinary public roots gain flat-record outputs. Every input remains a
# native scalar; this never admits a caller-provided recursive record.
@unsafe
def j_fold_root_signature(+book: List<&2,KDef>, +ty: KTerm, +left: U32) -> Bool:
  +head = wnf(book, ty)
  kc(Bool, U32.is_eq(left, 0), u => j_region_result_type(book, head), u =>
    String.eq(tg(head), "All") && Bool.not(U32.is_eq(qt(head), 0)) && j_region_scalar(book, kid(head, 0)) &&
      j_fold_root_signature(book, kid(head, 1), U32.sub(left, 1)))

@unsafe
def j_fold_root_result(+book: List<&2,KDef>, +ty: KTerm, +left: U32) -> KTerm:
  +head = wnf(book, ty)
  kc(KTerm, U32.is_eq(left, 0), u => head, u => j_fold_root_result(book, kid(head, 1), U32.sub(left, 1)))

@unsafe
def j_fold_root_guard(+book: List<&2,KDef>, +d: KDef, +helpers: List<&2,KDef>) -> String:
  kc(String, j_region_record(book, j_fold_root_result(book, dt(d), da(d))), u => "regionHostGuard()&&",
    u => j_region_host_guard(book, d, helpers))

# The @root-return context is confined to a top-level root's final expression.
# It keeps the existing tail-position build and its original field thunks.
# Private helpers retain their stricter eager-constructor admission rule.
@unsafe
def j_fold_terminal_fields(+book: List<&2,KDef>, +xs: List<&2,KTerm>, +left: U32) -> Bool:
  match xs:
    case Nil{}: U32.is_eq(left, 0)
    case Con{h, rest}: U32.is_gt(left, 0) && j_fold_terminal_expr(book, h, 128) && j_fold_terminal_fields(book, rest, U32.sub(left, 1))

@unsafe
def j_fold_terminal_expr(+book: List<&2,KDef>, +t: KTerm, +fuel: U32) -> Bool:
  +body = j_strip(t)
  +spine = j_call_spine(body, Nil{})
  kc(Bool, U32.is_gt(fuel, 0), u => j_region_field_atom(body) ||
    (String.eq(tg(body), "App") && j_primitive_call(book, spine) && j_fold_terminal_args(book, ks(spine), U32.sub(fuel, 1))), u => False{})

@unsafe
def j_fold_terminal_args(+book: List<&2,KDef>, +args: List<&2,KTerm>, +fuel: U32) -> Bool:
  match args:
    case Nil{}: True{}
    case Con{h, rest}: j_fold_terminal_expr(book, h, fuel) && j_fold_terminal_args(book, rest, fuel)

# A fold can reorder surrounding primitive work across child traversal only
# while the shared host identities remain unchanged, even without a residual.
@unsafe
def j_fold_has(+helpers: List<&2,KDef>) -> Bool:
  match helpers:
    case Nil{}: False{}
    case Con{d, rest}: String.eq(tg(dv(d)), "JFold") || j_fold_has(rest)
