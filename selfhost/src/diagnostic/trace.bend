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
def dg_typeless(
  +book: List<&2, KDef>,
  +ctx: List<&2, KTerm>,
  +t: KTerm,
) -> KTerm:
  dg_text("non-inferrable term '" ++ dg_expr(book, DTerm{t}, dg_scope(List.reverse(&2, KTerm, ctx), Nil{})) ++ "'" ++ kc(String, String.eq(tg(t), "Ctr") && String.eq(dk(lookup(book, nm(t))), "ADT"), u => " (" ++ nm(t) ++ " is a datatype: write its arguments as <>)", u => ""))

@unsafe
def dg_trace(e, ctx, t, ty, r):
  kc(KChecked, good(r), u => r, u => kc(KChecked, String.eq(tg(ct(r)), "DTrace"), u => KChecked{kt("DTrace", nm(ct(r)), ix(ct(r)), qt(ct(r)), [kid(ct(r), 0), kid(ct(r), 1), kid(ct(r), 2), kid(ct(r), 3), kt("DTrail", "", 0, 0, norm_join(ks(kid(ct(r), 4)), [t]))]), cy(r), cs(r), ce(r)}, u => dg_trace_detail(e, ctx, t, r, kc(KTerm, String.eq(tg(ct(r)), "DDetail"), u => ct(r), u => dg_reason(e, ctx, t, ty, ce(r))))))

@unsafe
def dg_trace_detail(e, ctx, t, r, detail):
  KChecked{kt("DTrace", cn(e), 0, qt(detail), [kid(detail, 0), kid(detail, 1), kt("DCtx", "", 0, 0, ctx), t, kt("DTrail", "", 0, 0, [t])]), cy(r), cs(r), ce(r)}

@unsafe
def dg_reason(e, ctx, t, ty, code):
  kc(KTerm, String.eq(code, "undefined name"), u => dg_pair(dg_text("a defined name"), t),
   u => kc(KTerm, String.eq(code, "unbound variable"), u => dg_pair(dg_text("a bound variable"), t),
   u => kc(KTerm, String.eq(code, "nondecreasing self-call"), u => dg_pair(dg_text("a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)"), t),
   u => kc(KTerm, String.eq(code, "live use of an unfilled law"), u => dg_pair(dg_text("a filled definition (an unfilled law is a dead claim: live code cannot use it)"), t),
   u => kc(KTerm, String.eq(code, "a family requires angle-bracket parameters"), u => dg_pair(dg_text("a family instance (write " ++ nm(t) ++ "<..>)"), t),
   u => kc(KTerm, String.eq(code, "unresolved hole"), u => dg_pair(ty, t),
   u => kc(KTerm, String.eq(code, "cannot infer: annotation required"), u => dg_pair(dg_text(kc(String, String.eq(tg(t), "Ctr") && String.eq(dg_family(cb(e), nm(t)), ""), u => "a declared constructor", u => "an annotated term (cannot infer)")), t),
   u => kc(KTerm, String.eq(code, "lambda requires a function type") || String.eq(code, "matcher requires a function type") || String.eq(code, "reflexivity requires equality goal"), u => dg_pair(ty, dg_typeless(cb(e), ctx, t)),
   u => kc(KTerm, String.eq(code, "constructor requires a datatype goal"), u => dg_pair(ty, kc(KTerm, String.eq(dg_family(cb(e), nm(t)), ""), u => dg_typeless(cb(e), ctx, t), u => ref(dg_family(cb(e), nm(t))))),
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
  kc(DDiagnostic, String.eq(tg(ct(r)), "DTrace"), u => DDiagnostic{dg_as_expr(kid(ct(r), 0)), dg_as_expr(kid(ct(r), 1)), U32.is_eq(qt(ct(r)), 1), ks(kid(ct(r), 2)), nm(ct(r)), DNoSpan{}, "", ks(kid(ct(r), 4))}, u => dg_no_report(name, ce(r)))

