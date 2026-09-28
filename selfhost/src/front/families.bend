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
) -> List<&2, KTerm>:
  f_choose(List<&2, KTerm>, U32.is_eq(n, 0), u => Nil{}, u => Con{qua(q), f_quants(U32.sub(n, 1), q)})

@unsafe
def f_adt(t, args, d):
  f_choose(KTerm, U32.is_eq(qt(t), 2) && (Bool.not(f_eq(dk(d), "ADT")) || U32.is_eq(f_leading_quants(dt(d)), 0) || (Bool.not(f_eq(tg(t), "ADT")) && U32.is_lt(f_leading_quants(dt(d)), da(d)))),
    u => kt("Error", "a quantified datatype after + (+D<..> sets D's leading quantities to &2)", ix(t), 0, Nil{}),
    u => f_adt_fill(t, args, da(d), f_leading_quants(dt(d))))

@unsafe
def f_adt_fill(t, args, arity, g):
  f_choose(KTerm, U32.is_eq(U32.add(terms_len(args), g), arity), u => KTerm{"ADT", nm(t), ix(t), qt(t), norm_join(f_quants(g, f_choose(U32, U32.is_eq(qt(t), 2), u => 2, u => 1)), args), rm(t)}, u => KTerm{"ADT", nm(t), ix(t), qt(t), f_choose(List<&2,KTerm>, U32.is_eq(qt(t), 2), u => norm_join(f_quants(g, 2), f_drop_terms(args, g)), u => args), rm(t)})

@unsafe
def f_drop_terms(ts, n):
  f_choose(List<&2,KTerm>, U32.is_eq(n, 0), u => ts, u => f_drop_terms(f_tail_terms(ts), U32.sub(n, 1)))

@unsafe
def f_scope_app(f, x):
  f_choose(KTerm, f_eq(tg(f), "Lam"), u => f_sub(kid(f, 0), ix(f), x), u => app(f, x))

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
      Con{f_choose(KTerm, U32.is_eq(ix(v), id), u => kt("Var", nm(v), ix(v), q, Nil{}), u => v), f_mark_vars(vs, id, q)}

@unsafe
def f_mark_fields(vars, q):
  match vars:
    case Nil{}:
      Nil{}
    case Con{+v, vs}:
      Con{kt("Var", nm(v), ix(v), f_choose(U32, U32.is_eq(q, 2), u => 2, u => qt(v)), Nil{}), f_mark_fields(vs, q)}


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
  f_choose(KTerm, f_templates_valid(f_tail_terms(ks(t)), f_choose(U32, f_eq(tg(head), "Ref") && f_eq(tg(kid(t, 0)), "Ref"), u => dx(f_find(nm(head), book)), u => 0), False{}), u => f_scope_apply_many(head, f_scope_call_args(f_tail_terms(ks(t)), env, book)), u => kt("Error", "~ arguments require leading template slots on a named template definition", 0, 0, Nil{}))

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
  f_choose(KTerm, U32.is_eq(qt(t), 2), u => f_scope_marked(t, bound, f_find(nm(t), book), False{}), u => f_choose(KTerm, U32.is_eq(qt(t), 3) && (Bool.not(f_eq(tg(bound), "Absent")) || f_eq(dk(f_find(nm(t), book)), "ADT")), u => kt("Error", "offload requires a named definition", 0, 0, Nil{}), u => f_choose(KTerm, Bool.not(f_eq(tg(bound), "Absent")), u => kt("Var", nm(bound), ix(bound), qt(bound), Nil{}), u => f_choose(KTerm, f_eq(dk(f_find(nm(t), book)), "ADT"), u => f_adt(t, Nil{}, f_find(nm(t), book)), u => f_choose(KTerm, Char.is_eq(f_head(nm(t)), '.') && Bool.not(Char.is_eq(f_head(f_tail(nm(t))), '.')), u => kt("Error", "a type for this operator (write (a " ++ f_operator_display(nm(t), ["+", "-", "*", "/", "%", "<", ">op", "<=", ">=", "<<", ">>op", ".&.", ".|.", ".^."]) ++ " b : Nat))", ix(t), 0, Nil{}), u => t)))))

# A bare marked value is an unbound variable. Empty calls turn an unbound
# spelling into a reference, while a lexical binder remains a variable.
@unsafe
def f_scope_marked(+t: KTerm, +bound: KTerm, +definition: KDef, +called: Bool) -> KTerm:
  f_choose(KTerm, f_eq(dk(definition), "ADT"), u => f_adt(KTerm{tg(t), nm(t), ix(t), 2, ks(t), rm(t)}, Nil{}, definition),
    u => f_choose(KTerm, Bool.not(f_eq(tg(bound), "Absent")) || (Bool.not(called) && Bool.not(String.contains(nm(t), "."))),
      u => kt("FUnboundVar", nm(t), ix(t), 0, Nil{}),
      u => kt("Error", "a quantified datatype after + (+D<..> sets D's leading quantities to &2)", ix(t), 0, Nil{})))

@unsafe
def f_scope_marked_call(+t: KTerm, +env: List<&2,KTerm>, +book: List<&2,KDef>) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "Call") && U32.is_eq(terms_len(ks(t)), 1), u => f_scope_marked_call(kid(t, 0), env, book),
    u => f_choose(KTerm, f_eq(tg(t), "Ref") && Bool.not(U32.is_eq(qt(t), 3)), u => f_scope_marked(t, f_env(nm(t), env), f_find(nm(t), book), True{}),
    u => f_choose(KTerm, f_eq(tg(t), "ADT"), u => f_adt(KTerm{tg(t), nm(t), ix(t), 2, ks(t), rm(t)}, f_scope_terms(ks(t), env, book), f_find(nm(t), book)),
    u => kt("Error", "a quantified datatype after + (+D<..> sets D's leading quantities to &2)", ix(t), 0, Nil{}))))

@unsafe
def f_scope_lambda(t, env, book):
  f_scope_lambda_var(t, env, book, kt(f_choose(String, U32.is_eq(qt(t), 4), u => "RewriteVar", u => "Var"), nm(t), ix(t), f_choose(U32, U32.is_eq(qt(t), 4), u => 1, u => qt(t)), Nil{}))

@unsafe
def f_scope_lambda_var(t, env, book, v):
  f_flat(f_scope_body(kid(t, 0), Con{v, env}, book), [kt("Var", nm(v), ix(v), qt(v), Nil{})])



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
