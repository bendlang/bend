# Family quantity inference, beta normalization and pattern quantity joins.

law f_adt:
  for +t: KTerm
  for +args: List<&2, KTerm>
  for +d: KDef
  KTerm

law f_adt_fill:
  for +t: KTerm
  for +args: List<&2, KTerm>
  for +arity: U32
  for +g: U32
  KTerm

law f_drop_terms:
  for +ts: List<&2, KTerm>
  for +n: U32
  List<&2, KTerm>

law f_mark_rows:
  for +rows: List<&2, KTerm>
  for +q: U32
  U32

law f_mark_vars:
  for +vars: List<&2, KTerm>
  for +id: U32
  for +q: U32
  List<&2, KTerm>

@unsafe
def f_leading_quants(
  +ty: KTerm,
) -> U32:
  f_choose(U32, f_eq(tg(ty), "All") && f_eq(tg(kid(ty, 0)), "Qnt"), u => U32.add(1, f_leading_quants(kid(ty, 1))), u => 0)

@unsafe
def f_quants(
  +n: U32,
  +q: U32,
  +origin: KTerm,
) -> List<&2, KTerm>:
  f_choose(List<&2, KTerm>, U32.is_eq(n, 0), u => Nil{}, u => Con{kt_span("Qua", "", 0, q, Nil{}, kb(origin), ke(origin)), f_quants(U32.sub(n, 1), q, origin)})

@unsafe
def f_adt(t, args, d):
  f_choose(KTerm, U32.is_eq(qt(t), 2) && (Bool.not(f_eq(dk(d), "ADT")) || U32.is_eq(f_leading_quants(dt(d)), 0) || (Bool.not(f_eq(tg(t), "ADT")) && U32.is_lt(f_leading_quants(dt(d)), da(d)))),
    u => kt("Error", "a quantified datatype after + (+D<..> sets D's leading quantities to &2)", ix(t), 0, Nil{}),
    u => f_adt_fill(t, args, da(d), f_leading_quants(dt(d))))

@unsafe
def f_adt_fill(t, args, arity, g):
  f_choose(KTerm, U32.is_eq(U32.add(terms_len(args), g), arity), u => KTerm{"ADT", nm(t), ix(t), qt(t), norm_join(f_quants(g, f_choose(U32, U32.is_eq(qt(t), 2), u => 2, u => 1), t), args), rm(t), kb(t), ke(t)}, u => KTerm{"ADT", nm(t), ix(t), qt(t), f_choose(List<&2,KTerm>, U32.is_eq(qt(t), 2), u => norm_join(f_quants(g, 2, t), f_drop_terms(args, g)), u => args), rm(t), kb(t), ke(t)})

@unsafe
def f_drop_terms(ts, n):
  f_choose(List<&2,KTerm>, U32.is_eq(n, 0), u => ts, u => f_drop_terms(f_tail_terms(ts), U32.sub(n, 1)))

@unsafe
def f_scope_app_span(+f: KTerm, +x: KTerm, +begin: U32, +end: U32) -> KTerm:
  f_choose(KTerm, f_eq(tg(f), "Lam"), u => f_sub(kid(f, 0), ix(f), x), u => kt_span("App", "", 0, 0, [f, x], begin, end))

@unsafe
def f_mark_rows(rows, q):
  match rows:
    case Nil{}:
      q
    case Con{+r, rs}:
      f_mark_rows(rs, f_choose(U32, f_eq(tg(f_rowpat(r)), "Var") && U32.is_eq(qt(f_rowpat(r)), 2), u => 2, u => q))

@unsafe
def f_mark_vars(vars, id, q):
  match vars:
    case Nil{}:
      Nil{}
    case Con{+v, vs}:
      Con{f_choose(KTerm, U32.is_eq(ix(v), id), u => kt_span("Var", nm(v), ix(v), q, Nil{}, kb(v), ke(v)), u => v), f_mark_vars(vs, id, q)}

law f_operator_display:
  for +name: String
  for +ops: List<&2,String>
  String

@unsafe
def f_operator_display(name, ops):
  match ops:
    case Nil{}:
      name
    case Con{+op, rest}:
      f_choose(String, f_eq(f_operator(op), name), u => f_choose(String, f_eq(op, ">op"), u => ">", u => f_choose(String, f_eq(op, ">>op"), u => ">>", u => op)), u => f_operator_display(name, rest))

# Do headers need the same chronological datatype quantities as written types.
# Keep their raw arguments until this pass, before choosing pure/bind/Ann.
@unsafe
def f_scope_apply_span(+head: KTerm, +args: List<&2,KTerm>, +begin: U32, +end: U32) -> KTerm:
  match args:
    case Nil{}: head
    case Con{a, rest}: f_scope_apply_span(f_scope_app_span(head, a, begin, end), rest, begin, end)

@unsafe
def f_operator_error(+t: KTerm) -> KTerm:
  +message = "a type for this operator (write (a " ++ f_operator_display(nm(t), ["+", "-", "*", "/", "%", "<", ">op", "<=", ">=", "<<", ">>op", ".&.", ".|.", ".^."]) ++ " b : Nat))"
  fpe_message_note_at(t, message, message, "we broke this after launch, sorry. Until 2.0.16 a bare operator meant Nat.\nThat was a bug: operators demand annotation. Wrap the expression and it'll work again.")

# Only failed calls revisit arguments to retain the first bad marker.
