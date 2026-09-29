# Simultaneous bindings preserve separate values and the full binder scope.

law f_parallel_pat:
  for +p: FParsed
  for +pats: List<&2, KTerm>
  FParsed

law f_parallel_values:
  for +ts: FInput
  for +pats: List<&2, KTerm>
  for +left: U32
  for +vals: List<&2, KTerm>
  FParsed

law f_parallel_value:
  for +p: FParsed
  for +pats: List<&2, KTerm>
  for +left: U32
  for +vals: List<&2, KTerm>
  FParsed

law f_parallel_body:
  for +pats: List<&2, KTerm>
  for +vals: List<&2, KTerm>
  for +p: FParsed
  FParsed

law f_parallel_binds:
  for +pats: List<&2, KTerm>
  for +vals: List<&2, KTerm>
  List<&2, KTerm>

law f_unlamb:
  for +body: KTerm
  for +n: U32
  KTerm

law f_statement_more:
  for +p: FParsed
  FParsed

law f_typed_let_try:
  for +n: KTerm
  for +old: FInput
  for +p: FParsed
  for +begin: U32
  FParsed

@unsafe
def f_parallel(
  +ts: FInput,
  +pats: List<&2, KTerm>,
) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), "="), u => f_parallel_values(f_tl(ts), List.reverse(&2, KTerm, pats), terms_len(pats), Nil{}), u => f_choose(FParsed, f_binding_head(ts), u => f_parallel_pat(f_expr(ts, 0), pats), u => fpe_error(ts, "expected =", "'='")))

@unsafe
def f_parallel_pat(p, pats):
  match p:
    case FParsed{+n, ts}:
      f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_parallel(ts, Con{n, pats}))

@unsafe
def f_parallel_values(ts, pats, left, vals):
  f_choose(FParsed, U32.is_eq(left, 0), u => f_context_parallel(pats, List.reverse(&2, KTerm, vals), ts), u => f_parallel_value(f_expr(ts, 0), pats, left, vals))

@unsafe
def f_parallel_value(p, pats, left, vals):
  match p:
    case FParsed{+n, ts}:
      f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_parallel_values(ts, pats, U32.sub(left, 1), Con{n, vals}))

@unsafe
def f_parallel_body(pats, vals, p):
  match p:
    case FParsed{body, ts}:
      FParsed{f_choose(KTerm, f_context_stop(body), u => body, u => kt("Parallel", "", 0, 1, [kt("Patterns", "", 0, 1, pats), kt("Values", "", 0, 1, vals), body])), ts}

@unsafe
def f_parallel_binds(pats, vals):
  match pats:
    case Nil{}:
      Nil{}
    case Con{+p, ps}:
      Con{kt_span("Bind", nm(p), ix(p), qt(p), [terms_at(vals, 0)], kb(p), ke(p)), f_parallel_binds(ps, f_tail_terms(vals))}

@unsafe
def f_unlamb(body, n):
  f_choose(KTerm, U32.is_eq(n, 0), u => body, u => f_choose(KTerm, f_eq(tg(body), "Lam"), u => f_unlamb(kid(body, 0), U32.sub(n, 1)), u => kt("Error", "cannot match a parallel let binding", 0, 0, Nil{})))

@unsafe
def f_statement_more(p):
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, f_eq(tg(n), "Write"), u => f_write_statement(n, ts), u => f_choose(FParsed, f_binding_head(ts), u => f_parallel(ts, [n]), u => FParsed{n, ts}))

@unsafe
def f_typed_let_try(n, old, p, begin):
  match p:
    case FParsed{ty, ts}:
      f_choose(FParsed, f_context_stop(ty), u => p, u => f_choose(FParsed, f_eq(f_tx(ts), "="),
        u => f_context_typed_value(n, f_let_ann(ty, f_expr(f_tl(ts), 0), begin)),
        u => FParsed{n, f_context_rewind(old, ts)}))

@unsafe
def f_binding_head(+ts: FInput) -> Bool:
  (f_ascii_alpha(f_head(f_tx(ts))) || Char.is_eq(f_head(f_tx(ts)), '_') || f_eq(f_tx(ts), "+bind")) && Bool.not(f_reserved(f_tx(ts)))
