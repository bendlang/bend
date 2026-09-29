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

law f_scope_app:
  for +f: KTerm
  for +x: KTerm
  KTerm

law f_mark_rows:
  for +rows: List<&2, KTerm>
  for +q: U32
  U32

law f_mark_vars:
  for +vars: List<&2, KTerm>
  for +id: U32
  for +q: U32
  List<&2, KTerm>

law f_mark_fields:
  for +vars: List<&2, KTerm>
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
def f_scope_app(f, x):
  f_scope_app_span(f, x, 0, 0)

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

@unsafe
def f_mark_fields(vars, q):
  match vars:
    case Nil{}:
      Nil{}
    case Con{+v, vs}:
      Con{kt_span("Var", nm(v), ix(v), f_choose(U32, U32.is_eq(q, 2), u => 2, u => qt(v)), Nil{}, kb(v), ke(v)), f_mark_fields(vs, q)}


law f_scope_call:
  for +t: KTerm
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  KTerm

law f_scope_call_head:
  for +t: KTerm
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  for +head: KTerm
  KTerm

law f_templates_valid:
  for +args: List<&2, KTerm>
  for +left: U32
  for +ordinary: Bool
  Bool

law f_scope_call_args:
  for +args: List<&2, KTerm>
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  List<&2, KTerm>

law f_scope_apply_many:
  for +head: KTerm
  for +args: List<&2, KTerm>
  KTerm

law f_scope_reference:
  for +t: KTerm
  for +bound: KTerm
  for +book: List<&2, KDef>
  KTerm

law f_scope_lambda:
  for +t: KTerm
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  KTerm

law f_scope_lambda_var:
  for +t: KTerm
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  for +v: KTerm
  KTerm

@unsafe
def f_scope_call(t, env, book):
  f_choose(KTerm, U32.is_eq(qt(t), 2), u => f_scope_marked_call(kid(t, 0), env, book), u => f_scope_call_head(t, env, book, f_scope(kid(t, 0), env, book)))

@unsafe
def f_scope_call_head(t, env, book, head):
  f_choose(KTerm, f_templates_valid(f_tail_terms(ks(t)), f_choose(U32, f_eq(tg(head), "Ref") && (f_eq(tg(kid(t, 0)), "Ref") || f_eq(tg(kid(t, 0)), "FAliasRef")), u => dx(f_find(nm(head), book)), u => 0), False{}), u => f_scope_apply_span(head, f_scope_call_args(f_tail_terms(ks(t)), env, book), kb(t), ke(t)), u => f_templates_error(f_tail_terms(ks(t)), f_choose(U32, f_eq(tg(head), "Ref") && (f_eq(tg(kid(t, 0)), "Ref") || f_eq(tg(kid(t, 0)), "FAliasRef")), u => dx(f_find(nm(head), book)), u => 0), 0, False{}, nm(head)))

@unsafe
def f_templates_valid(args, left, ordinary):
  match args:
    case Nil{}:
      True{}
    case Con{+a, rest}:
      f_choose(Bool, f_eq(tg(a), "TemplateArg"), u => Bool.not(ordinary) && U32.is_gt(left, 0) && f_templates_valid(rest, U32.sub(left, 1), False{}), u => f_templates_valid(rest, left, True{}))

@unsafe
def f_scope_call_args(args, env, book):
  match args:
    case Nil{}:
      Nil{}
    case Con{+a, rest}:
      Con{f_scope(f_choose(KTerm, f_eq(tg(a), "TemplateArg"), u => kid(a, 0), u => a), env, book), f_scope_call_args(rest, env, book)}

@unsafe
def f_scope_apply_many(head, args):
  match args:
    case Nil{}:
      head
    case Con{a, rest}:
      f_scope_apply_many(f_scope_app(head, a), rest)

@unsafe
def f_scope_reference(t, bound, book):
  f_choose(KTerm, U32.is_eq(qt(t), 2), u => f_scope_marked(t, bound, f_find(nm(t), book), False{}), u => f_choose(KTerm, f_choose(Bool, U32.is_eq(qt(t), 3), u => f_choose(Bool, Bool.not(f_eq(tg(bound), "Absent")), u => True{}, u => f_eq(dk(f_find(nm(t), book)), "ADT")), u => False{}), u => kt("Error", "offload requires a named definition", 0, 0, Nil{}), u => f_choose(KTerm, Bool.not(f_eq(tg(bound), "Absent")), u => kt_span("Var", nm(bound), ix(bound), qt(bound), Nil{}, kb(t), ke(t)), u => f_choose(KTerm, f_eq(dk(f_find(nm(t), book)), "ADT") && U32.is_eq(da(f_find(nm(t), book)), 0), u => f_adt(t, Nil{}, f_find(nm(t), book)), u => f_choose(KTerm, Char.is_eq(f_head(nm(t)), '.') && Bool.not(Char.is_eq(f_head(f_tail(nm(t))), '.')), u => f_operator_error(t), u => t)))))

# A bare marked value is an unbound variable. Empty calls turn an unbound
# spelling into a reference, while a lexical binder remains a variable.
@unsafe
def f_scope_marked(+t: KTerm, +bound: KTerm, +definition: KDef, +called: Bool) -> KTerm:
  f_choose(KTerm, f_eq(dk(definition), "ADT"), u => f_adt(KTerm{tg(t), nm(t), ix(t), 2, ks(t), rm(t), kb(t), ke(t)}, Nil{}, definition),
    u => f_choose(KTerm, Bool.not(f_eq(tg(bound), "Absent")) || (Bool.not(called) && Bool.not(String.contains(nm(t), "."))),
      u => kt_span("FUnboundVar", nm(t), ix(t), 0, Nil{}, kb(t), ke(t)),
      u => kt("Error", "a quantified datatype after + (+D<..> sets D's leading quantities to &2)", ix(t), 0, Nil{})))

@unsafe
def f_scope_marked_call(+t: KTerm, +env: List<&2,KTerm>, +book: List<&2,KDef>) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "FAliasRef") && Bool.not(U32.is_eq(qt(t), 3)), u => f_scope_alias(t, f_env(nm(t), env), book, True{}), u => f_choose(KTerm, f_eq(tg(t), "Call") && U32.is_eq(terms_len(ks(t)), 1), u => f_scope_marked_call(kid(t, 0), env, book),
    u => f_choose(KTerm, f_eq(tg(t), "Ref") && Bool.not(U32.is_eq(qt(t), 3)), u => f_scope_marked(t, f_env(nm(t), env), f_find(nm(t), book), True{}),
    u => f_choose(KTerm, f_eq(tg(t), "ADT"), u => f_adt(KTerm{tg(t), nm(t), ix(t), 2, ks(t), rm(t), kb(t), ke(t)}, f_scope_terms(ks(t), env, book), f_find(nm(t), book)),
    u => kt("Error", "a quantified datatype after + (+D<..> sets D's leading quantities to &2)", ix(t), 0, Nil{})))))

@unsafe
def f_scope_lambda_eligible(+t: KTerm, +env: List<&2,KTerm>, +book: List<&2,KDef>) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "FLambda"),
    u => f_choose(KTerm, f_eq(tg(f_env(nm(t), env)), "Absent"),
      u => f_scope_lambda_refused(t, f_choose(KTerm, f_eq(tg(kid(t, 1)), "FAliasRef"), u => kid(kid(t, 1), 0), u => kid(t, 1))),
      u => f_scope_lambda(t, env, book)),
    u => f_scope_lambda(t, env, book))

@unsafe
def f_scope_lambda_refused(+t: KTerm, +ref: KTerm) -> KTerm:
  f_choose(KTerm, f_eq(tg(ref), "Error"), u => ref,
    u => fpe_point_at(kid(t, 2), "a lambda binder must be a non-reserved name", "a lambda binder (one name: k => body)"))

@unsafe
def f_scope_lambda(t, env, book):
  f_scope_lambda_var(t, env, book, kt_span(f_choose(String, U32.is_eq(qt(t), 4), u => "RewriteVar", u => "Var"), nm(t), ix(t), f_choose(U32, U32.is_eq(qt(t), 4), u => 1, u => qt(t)), Nil{}, kb(t), ke(t)))

@unsafe
def f_scope_lambda_var(t, env, book, v):
  k_lambda_presence(f_flat(f_scope_body(kid(t, 0), Con{v, env}, book), [kt_span("Var", nm(v), ix(v), qt(v), Nil{}, kb(v), ke(v))]), f_eq(tg(t), "FLambda") || k_quantity_present(t))



# Only the rejected unresolved-operator path needs this reverse display lookup.
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
def f_scope_do(+t: KTerm, +env: List<&2,KTerm>, +book: List<&2,KDef>) -> KTerm:
  f_scope_do_args(t, env, book, f_scope_terms(ks(f_choose(KTerm, f_eq(dk(f_find(nm(t), book)), "ADT"),
    u => f_adt(kid(t, 0), ks(kid(t, 0)), f_find(nm(t), book)), u => kid(t, 0))), env, book))

@unsafe
def f_scope_do_args(+t: KTerm, +env: List<&2,KTerm>, +book: List<&2,KDef>, +types: List<&2,KTerm>) -> KTerm:
  f_choose(KTerm, U32.is_eq(qt(t), 0),
    u => kt_span("Ann", "", ix(t), 1, [f_scope(kid(t, 1), env, book), f_choose(KTerm, f_eq(dk(f_find(nm(t), book)), "ADT"), u => kt_span("ADT", nm(t), ix(t), 1, types, kb(t), ke(t)), u => f_scope_apply_span(kt_span("Ref", nm(t), 0, 0, Nil{}, kb(t), ke(t)), types, kb(t), ke(t)))], kb(t), ke(t)),
    u => f_choose(KTerm, U32.is_eq(qt(t), 1),
      u => f_scope_apply_span(kt_span("Ref", nm(t) ++ ".pure", ix(t), 1, Nil{}, kb(t), ke(t)), norm_join(types, [f_scope(kid(t, 1), env, book)]), kb(t), ke(t)),
      u => f_scope_apply_span(kt_span("Ref", nm(t) ++ ".bind", ix(t), 1, Nil{}, kb(t), ke(t)), norm_join(f_do_bind_types(types, f_scope(kid(t, 1), env, book)), [f_scope(kid(t, 2), env, book), f_scope(kid(t, 3), env, book)]), kb(t), ke(t))))

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
@unsafe
def f_templates_error(+args: List<&2,KTerm>, +left: U32, +count: U32, +ordinary: Bool, +name: String) -> KTerm:
  match args:
    case Nil{}: kt("Error", "~ arguments require leading template slots on a named template definition", 0, 0, Nil{})
    case Con{a, rest}:
      f_choose(KTerm, f_eq(tg(a), "TemplateArg"),
        u => f_choose(KTerm, Bool.not(ordinary) && U32.is_gt(left, 0), u => f_templates_error(rest, U32.sub(left, 1), U32.add(count, 1), False{}, name),
          u => fpe_expected_at(k_with_span(a, kb(a), kb(a)), "~ arguments require leading template slots on a named template definition", f_choose(String, Bool.not(ordinary) && U32.is_gt(count, 0), u => "a term (" ++ name ++ " takes " ++ U32.show(count) ++ " ~)", u => "a term"), "'~'")),
        u => f_templates_error(rest, left, count, True{}, name))
