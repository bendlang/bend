import Base

# Error-only metadata; consumed by an isolated instrumented build of the existing checker.
law dg_text:
  for +s: String
  KTerm

law dg_bad_detail:
  for +message: String
  for +expected: KTerm
  for +observed: KTerm
  KChecked

law dg_bad_message:
  for +message: String
  for +expected: KTerm
  KChecked

law dg_trace:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +r: KChecked
  KChecked

law dg_trace_detail:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +r: KChecked
  for +detail: KTerm
  KChecked

law dg_reason:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +code: String
  KTerm

@unsafe
def dg_text(s):
  kt("DText", s, 0, 0, Nil{})

@unsafe
def dg_bad_detail(message, expected, observed):
  KChecked{kt("DDetail", "", 0, 1, [expected, observed]), atom("Error"), Nil{}, message}

@unsafe
def dg_bad_message(message, expected):
  KChecked{kt("DDetail", "", 0, 0, [expected, atom("Absent")]), atom("Error"), Nil{}, message}

@unsafe
def dg_pair(
  +expected: KTerm,
  +observed: KTerm,
) -> KTerm:
  kt("DDetail", "", 0, 1, [expected, observed])

@unsafe
def dg_family(
  +book: List<&2, KDef>,
  +name: String,
) -> String:
  match book:
    case Nil{}: ""
    case Con{d, rest}: kc(String, String.eq(dk(d), "ADT") && Bool.not(String.eq(dk(lookup(dc(d), name)), "Absent")), u => dn(d), u => dg_family(rest, name))

@unsafe
def dg_trace(e, ctx, t, ty, r):
  kc(KChecked, good(r), u => r, u => kc(KChecked, String.eq(tg(ct(r)), "DTrace"), u => KChecked{kt("DTrace", nm(ct(r)), ix(ct(r)), qt(ct(r)), [kid(ct(r), 0), kid(ct(r), 1), kid(ct(r), 2), kid(ct(r), 3), kt("DTrail", "", 0, 0, norm_join(ks(kid(ct(r), 4)), [t])), kid(ct(r), 5)]), cy(r), cs(r), ce(r)}, u => dg_trace_detail(e, ctx, t, r, kc(KTerm, String.eq(tg(ct(r)), "DDetail"), u => ct(r), u => dg_reason(e, ctx, t, ty, ce(r))))))

@unsafe
def dg_trace_detail(e, ctx, t, r, detail):
  KChecked{kt("DTrace", cn(e), 0, qt(detail), [kid(detail, 0), kid(detail, 1), kt("DCtx", "", 0, 0, ctx), t, kt("DTrail", "", 0, 0, [t]), dg_text(kc(String, String.eq(ce(r), "constructor requires a datatype goal") && String.eq(dk(lookup(cb(e), nm(t))), "ADT") && String.eq(dg_family(cb(e), nm(t)), ""), u => "Note: " ++ nm(t) ++ " is a datatype: write its arguments as <>", u => ""))]), cy(r), cs(r), ce(r)}

@unsafe
def dg_reason(e, ctx, t, ty, code):
  kc(KTerm, String.eq(code, "undefined name"), u => dg_pair(dg_text("a defined name"), t),
   u => kc(KTerm, String.eq(code, "unbound variable"), u => dg_pair(dg_text("a bound variable"), kc(KTerm, String.eq(tg(t), "FUnboundVar"), u => dg_text(nm(t) ++ kc(String, kp_bound(dg_scope(ctx, Nil{}), nm(t)), u => "^-1", u => "")), u => t)),
   u => kc(KTerm, String.eq(code, "nondecreasing self-call"), u => dg_pair(dg_text("a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)"), t),
   u => kc(KTerm, String.eq(code, "live use of an unfilled law"), u => dg_pair(dg_text("a filled definition (an unfilled law is a dead claim: live code cannot use it)"), t),
   u => kc(KTerm, String.eq(code, "a family requires angle-bracket parameters"), u => dg_pair(dg_text("a family instance (write " ++ nm(t) ++ "<..>)"), t),
   u => kc(KTerm, String.eq(code, "unresolved hole"), u => dg_pair(ty, t),
   u => kc(KTerm, String.eq(code, "cannot infer: annotation required"), u => dg_pair(dg_text(kc(String, (String.eq(tg(t), "Ctr") || core_literal(t)) && String.eq(dg_family(cb(e), nm(kc(KTerm, core_literal(t), u => core_literal_step(t), u => t))), ""), u => "a declared constructor", u => "an annotated term (cannot infer)")), t),
   u => kc(KTerm, String.eq(code, "lambda requires a function type") || String.eq(code, "matcher requires a function type") || String.eq(code, "reflexivity requires equality goal"), u => dg_pair(ty, dg_text("non-inferrable term")),
   u => kc(KTerm, String.eq(code, "constructor requires a datatype goal"), u => dg_pair(ty, kc(KTerm, String.eq(dg_family(cb(e), nm(t)), ""), u => dg_text("non-inferrable term"), u => ref(dg_family(cb(e), nm(t))))),
   u => kt("DDetail", "", 0, 0, [dg_text(code), atom("Absent")]))))))))))

@unsafe
def dg_as_expr(
  +t: KTerm,
) -> DExpr:
  kc(DExpr, String.eq(tg(t), "DText"), u => DText{nm(t)}, u => DTerm{t})

@unsafe
def dg_no_report(
  +name: String,
  +message: String,
) -> DDiagnostic:
  DDiagnostic{DText{message}, DText{""}, False{}, Nil{}, name, DNoSpan{}, "", Nil{}}

@unsafe
def dg_report(
  +r: KChecked,
  +name: String,
) -> DDiagnostic:
  kc(DDiagnostic, String.eq(tg(ct(r)), "DTrace"), u => DDiagnostic{dg_as_expr(kid(ct(r), 0)), dg_as_expr(kid(ct(r), 1)), U32.is_eq(qt(ct(r)), 1), ks(kid(ct(r), 2)), nm(ct(r)), DNoSpan{}, nm(kid(ct(r), 5)), ks(kid(ct(r), 4))}, u => dg_no_report(name, ce(r)))


# Keep the original closed-argument error, except an actual caller variable.
@unsafe
def dg_template_result(+e: KEnv, +ctx: List<&2, KTerm>, +t: KTerm, +r: KChecked) -> KChecked:
  kc(KChecked, String.eq(ce(r), "unbound variable") && String.eq(tg(ct(r)), "DTrace") && String.eq(tg(kid(ct(r), 1)), "Var") && Bool.not(String.eq(tg(ctx_get(ctx, ix(kid(ct(r), 1)))), "Absent")), u => dg_trace(e, ctx, t, atom("Absent"), dg_bad_detail(ce(r), dg_text("a template applied to closed ~ arguments (" ++ nm(kid(ct(r), 1)) ++ " is a variable here, not comptime: pass it at run time)"), t)), u => r)

@unsafe
def dg_kind_check(+e: KEnv, +ctx: List<&2, KTerm>, +t: KTerm, +q: U32, +name: String) -> KChecked:
  dg_kind_at(e, ctx, t, q, name, t)

@unsafe
def dg_kind_at(+e: KEnv, +ctx: List<&2,KTerm>, +t: KTerm, +q: U32, +name: String, +site: KTerm) -> KChecked:
  +kind = typ(kindq(e, q))
  dg_kind_result(t, q, name, site, kind, check(e, ctx, t, 0, kind))

@unsafe
def dg_kind_result(+t: KTerm, +q: U32, +name: String, +site: KTerm, +kind: KTerm, +r: KChecked) -> KChecked:
  kc(KChecked, String.eq(ce(r), "type mismatch") && String.eq(tg(ct(r)), "DTrace") && norm_exact(kid(ct(r), 0), kind) && norm_exact(kid(ct(r), 3), t) && (U32.is_eq(kb(t), 0) || U32.is_eq(kb(kid(ct(r), 3)), 0) || (U32.is_eq(kb(t), kb(kid(ct(r), 3))) && U32.is_eq(ke(t), ke(kid(ct(r), 3))))), u => KChecked{kt("DTrace", nm(ct(r)), ix(ct(r)), qt(ct(r)), [kid(ct(r), 0), kid(ct(r), 1), kid(ct(r), 2), site, kt("DTrail", "", 0, 0, Con{site, ks(kid(ct(r), 4))}), kc(KTerm, U32.is_eq(q, 2), u => dg_text("Note: +" ++ name ++ " can be used many times, so its type must be Data."), u => kid(ct(r), 5))]), cy(r), cs(r), ce(r)}, u => r)
