# Two pure scalar children use a private depth-first continuation stack. Public
# matcher entry and every refused shape keep the original generic evaluation.

@unsafe
def j_tree_global(+book: List<&2,KDef>, +d: KDef) -> String:
  +worker = j_tree_worker(book, d)
  kc(String, String.eq(worker, ""), u => j_region_global(book, d),
    u => "G[" ++ j_quote(dn(d)) ++ "]=" ++ worker ++ ";\n")

@unsafe
def j_tree_worker(+book: List<&2,KDef>, +d: KDef) -> String:
  kc(String, j_nat_scalar_shape(book, d), u =>
    kc(String, j_region_signature(book, dt(d), da(d)), u =>
      j_tree_checked(book, d, kid(j_strip(dv(d)), 0), j_strip(kid(j_strip(kid(j_strip(dv(d)), 1)), 0))), u => ""), u => "")

@unsafe
def j_tree_checked(+book: List<&2,KDef>, +d: KDef, +zero: KTerm, +succ: KTerm) -> String:
  kc(String, j_tree_shape(j_nat_loop_unwrap(succ), dn(d), ix(succ), da(d)), u =>
    kc(String, j_tree_distinct(succ, j_nat_loop_unwrap(succ)), u => j_tree_zero(book, d, zero, succ,
      j_region_prefix(book, Nil{}, zero, j_arm_type(book, wnf(book, dt(d)), "Zero"), 0, U32.sub(da(d), 1), True{}, "", [dn(d)], 0,
        JRegionBuild{atom("Absent"), Nil{}, 32768, True{}})), u => ""), u => "")

@unsafe
def j_tree_shape(+t: KTerm, +name: String, +pred: U32, +total: U32) -> Bool:
  kc(Bool, String.eq(tg(t), "Let") && U32.is_eq(terms_len(ks(t)), 3), u =>
    kc(Bool, j_nat_loop_bindings(ks(t), pred, Nil{}) && Bool.not(U32.is_eq(qt(kid(t, 0)), 0)) && Bool.not(U32.is_eq(qt(kid(t, 1)), 0)), u =>
      j_nat_loop_call(j_call_spine(kid(kid(t, 0), 0), Nil{}), name, pred, total) &&
      j_nat_loop_call(j_call_spine(kid(kid(t, 1), 0), Nil{}), name, pred, total), u => False{}), u => False{})

@unsafe
def j_tree_distinct(+t: KTerm, +body: KTerm) -> Bool:
  +head = j_strip(t)
  kc(Bool, String.eq(tg(head), "Lam"), u =>
    kc(Bool, Bool.not(U32.is_eq(ix(head), ix(kid(body, 0)))) && Bool.not(U32.is_eq(ix(head), ix(kid(body, 1)))),
      u => j_tree_distinct(kid(head, 0), body), u => False{}), u => True{})

@unsafe
def j_tree_zero(+book: List<&2,KDef>, +d: KDef, +zero: KTerm, +succ: KTerm, +s: JRegionBuild) -> String:
  kc(String, j_region_valid(s), u =>
    j_tree_done(book, d, zero, succ, j_region_term(s),
      j_tree_prefix(book, Nil{}, succ, j_arm_type(book, wnf(book, dt(d)), "Succ"), da(d), dn(d), s)), u => "")

# Both child RHSs see only the original parent environment. The combination
# sees only the two new results, so no parent capture survives an unwind.
@unsafe
def j_tree_prefix(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +left: U32, +name: String, +s: JRegionBuild) -> JRegionBuild:
  +body = j_strip(t)
  +head = wnf(book, ty)
  kc(JRegionBuild, j_region_valid(s) && U32.is_gt(j_region_fuel(s), 0), u =>
    kc(JRegionBuild, U32.is_eq(left, 0), u =>
      j_tree_left(book, env, body, head, name,
        j_region_expr(book, env, kid(kid(body, 0), 0), head, name, [name], 0, 0, j_region_tick(s))), u =>
      j_region_prefix_lam(body, True{}, j_tree_prefix(book,
        Con{kt("Env", "", ix(body), 0, [kid(head, 0)]), env}, kid(body, 0),
        subst(kid(head, 1), ix(head), var(nm(body), ix(body))), U32.sub(left, 1), name, j_region_tick(s)))), u => j_region_fail(s))

@unsafe
def j_tree_left(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +name: String, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s), u =>
    j_tree_right(book, t, ty, name, k_with_children(kid(t, 0), [j_region_term(s)]),
      j_region_expr(book, env, kid(kid(t, 1), 0), ty, name, [name], 0, 0, s)), u => s)

@unsafe
def j_tree_right(+book: List<&2,KDef>, +t: KTerm, +ty: KTerm, +name: String, +left: KTerm, +s: JRegionBuild) -> JRegionBuild:
  kc(JRegionBuild, j_region_valid(s), u =>
    j_tree_combine(t, ty, left, k_with_children(kid(t, 1), [j_region_term(s)]),
      j_region_expr(book, [kt("Env", "", ix(kid(t, 0)), 0, [ty]), kt("Env", "", ix(kid(t, 1)), 0, [ty])],
        kid(t, 2), ty, "", [name], 0, 0, s)), u => s)

@unsafe
def j_tree_combine(+t: KTerm, +ty: KTerm, +left: KTerm, +right: KTerm, +s: JRegionBuild) -> JRegionBuild:
  j_region_result(s, j_region_annotate(k_with_children(t, [left, right, j_region_term(s)]), ty))

@unsafe
def j_tree_done(+book: List<&2,KDef>, +d: KDef, +zero: KTerm, +succ: KTerm, +fastZero: KTerm, +s: JRegionBuild) -> String:
  kc(String, j_region_valid(s), u =>
    "scalarCapture(" ++ j_quote(dn(d)) ++ ",(()=>{" ++ j_region_declarations(book, j_region_helpers(s)) ++
    "const $guards=[" ++ j_quote(dn(d)) ++ kc(String, List.is_empty(&2, KDef, j_region_helpers(s)), u => "", u => "," ++ j_region_names(j_region_helpers(s))) ++ "];return " ++
    j_nat_loop_wrapper(book, d, zero, da(d),
      "if($entered&&" ++ j_region_host_guard(book, d, j_region_helpers(s)) ++ j_region_inputs(book, j_arm_type(book, wnf(book, dt(d)), "Succ"), 0, da(d), True{}) ++ "&&$s0<32n&&localGuard($guards)){/* private scalar tree */" ++
      j_tree_scope(book, d, j_region_helpers(s), j_tree_body(book, d, fastZero, j_region_term(s))) ++ "}" ++
      j_nat_loop_generic(book, Nil{}, succ, j_arm_type(book, wnf(book, dt(d)), "Succ"), 0)) ++ ";})())", u => "")

# Share a complete checked entry only inside a scalar-input, independently pure
# residual graph. Delayed results and exceptions leave the proof in finally.
@unsafe
def j_tree_scope(+book: List<&2,KDef>, +d: KDef, +helpers: List<&2,KDef>, +body: String) -> String:
  kc(String, j_fold_root_signature(book, dt(d), da(d)) && j_region_has_residual(helpers), u =>
    kc(String, j_pure_valid(j_pure_graph(book, d, JPure{Nil{}, 32768, True{}})), u =>
      "const $previousProof=regionProofOpen($guards);try{" ++ body ++ "}finally{regionProofClose($previousProof);}", u => body), u => body)

@unsafe
def j_tree_body(+book: List<&2,KDef>, +d: KDef, +zero: KTerm, +succ: KTerm) -> String:
  "$s0=$s0+1n;const $frames=[];let $top=0,$value;$visit:for(;;){if($s0!==0n){" ++
  j_tree_enter(book, Nil{}, succ, j_arm_type(book, wnf(book, dt(d)), "Succ"), d, succ, 0, False{}) ++ "}{" ++
  j_region_body(book, Nil{}, zero, j_arm_type(book, wnf(book, dt(d)), "Zero"), 1, "$value=", False{}) ++ "}" ++
  "while($top){const $frame=$frames[$top-1];if($frame.phase===0){$frame.left=$value;$frame.phase=1;" ++
  j_tree_enter(book, Nil{}, succ, j_arm_type(book, wnf(book, dt(d)), "Succ"), d, succ, 0, True{}) ++ "}" ++
  j_tree_unwind(book, j_nat_loop_unwrap(succ)) ++ "--$top;}return $value;}"

@unsafe
def j_tree_enter(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +d: KDef, +succ: KTerm, +at: U32, +right: Bool) -> String:
  +body = j_strip(t)
  +head = wnf(book, ty)
  kc(String, String.eq(tg(body), "Lam"), u =>
    "const " ++ j_local(ix(body)) ++ "=" ++ kc(String, right,
      u => "$frame.args[" ++ U32.show(at) ++ "]",
      u => "$s" ++ U32.show(at) ++ kc(String, U32.is_eq(at, 0), u => "-1n", u => "")) ++ ";" ++
    j_tree_enter(book, Con{kt("Env", "", ix(body), 0, [kid(head, 0)]), env}, kid(body, 0),
      subst(kid(head, 1), ix(head), var(nm(body), ix(body))), d, succ, U32.inc(at), right), u =>
    j_nat_loop_next(book, env, ks(j_call_spine(kid(kid(body, kc(U32, right, u => 1, u => 0)), 0), Nil{})), dt(d), 0) ++
    kc(String, right, u => "", u => j_tree_push(succ)) ++
    j_nat_loop_assign(da(d), 0) ++ "continue $visit;")

@unsafe
def j_tree_push(+succ: KTerm) -> String:
  "const $saved=$frames[$top++];if($saved){" ++ j_tree_save(succ, 0) ++
  "$saved.phase=0;$saved.left=null;}else $frames[$top-1]={args:[" ++
  j_tree_aliases(succ) ++ "],phase:0,left:null};"

@unsafe
def j_tree_save(+t: KTerm, +at: U32) -> String:
  +body = j_strip(t)
  kc(String, String.eq(tg(body), "Lam"), u =>
    "$saved.args[" ++ U32.show(at) ++ "]=" ++ j_local(ix(body)) ++ ";" ++
    j_tree_save(kid(body, 0), U32.inc(at)), u => "")

@unsafe
def j_tree_aliases(+t: KTerm) -> String:
  +body = j_strip(t)
  kc(String, String.eq(tg(body), "Lam"), u => j_local(ix(body)) ++ "," ++ j_tree_aliases(kid(body, 0)), u => "")

@unsafe
def j_tree_unwind(+book: List<&2,KDef>, +body: KTerm) -> String:
  "const " ++ j_local(ix(kid(body, 0))) ++ "=$frame.left;const " ++ j_local(ix(kid(body, 1))) ++ "=$value;" ++
  "$value=" ++ j_expr(book, j_context(book, Nil{}, ks(body)), kid(body, 2), atom("Absent"), False{}) ++ ";"
