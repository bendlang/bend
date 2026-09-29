# Simultaneous bindings preserve separate values and the full binder scope.

law f_parallel_pat:
  for +p: FParsed
  for +pats: List<&2, KTerm>
  FParsed

law f_parallel_values:
  for +ts: List<&2, FToken>
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

law f_scope_parallel:
  for +t: KTerm
  for +env: List<&2, KTerm>
  for +book: List<&2,KDef>
  KTerm

law f_scope_parallel_pats:
  for +t: KTerm
  for +pats: List<&2, KTerm>
  for +env: List<&2, KTerm>
  for +book: List<&2,KDef>
  KTerm

law f_scope_parallel_valid:
  for +t: KTerm
  for +pats: List<&2, KTerm>
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  for +err: Maybe<&2,KTerm>
  KTerm

law f_parallel_binds:
  for +pats: List<&2, KTerm>
  for +vals: List<&2, KTerm>
  List<&2, KTerm>

law f_unlamb:
  for +body: KTerm
  for +n: U32
  KTerm

law f_flat_parallel:
  for +t: KTerm
  for +vars: List<&2, KTerm>
  KTerm

law f_statement_more:
  for +p: FParsed
  FParsed

law f_typed_let_try:
  for +n: KTerm
  for +old: List<&2, FToken>
  for +p: FParsed
  FParsed

@unsafe
def f_parallel(
  +ts: List<&2, FToken>,
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
  f_choose(FParsed, U32.is_eq(left, 0), u => f_parallel_body(pats, List.reverse(&2, KTerm, vals), f_body(ts)), u => f_parallel_value(f_expr(ts, 0), pats, left, vals))

@unsafe
def f_parallel_value(p, pats, left, vals):
  match p:
    case FParsed{+n, ts}:
      f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_parallel_values(ts, pats, U32.sub(left, 1), Con{n, vals}))

@unsafe
def f_parallel_body(pats, vals, p):
  match p:
    case FParsed{body, ts}:
      FParsed{kt("Parallel", "", 0, 1, [kt("Patterns", "", 0, 1, pats), kt("Values", "", 0, 1, vals), body]), ts}

@unsafe
def f_scope_parallel(t, env, book):
  f_scope_parallel_pats(t, f_patterns(ks(kid(t, 0)), env, book), env, book)

@unsafe
def f_scope_parallel_pats(t, pats, env, book):
  f_scope_parallel_valid(t, pats, env, book, f_valid_patterns_mode(pats, book, True{}))

@unsafe
def f_scope_parallel_valid(t, pats, env, book, err):
  match err:
    case None{}: kt_span("Parallel", "", 0, 1, [kt("Patterns", "", 0, 1, pats), kt("Values", "", 0, 1, f_scope_terms(ks(kid(t, 1)), env, book)), f_scope_body(kid(t, 2), f_pattern_env(pats, env), book)], kb(t), ke(t))
    case Some{error}: error

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
def f_flat_parallel(t, vars):
  f_lbind(vars, kt_span("Let", "", 0, 1, norm_join(f_parallel_binds(ks(kid(t, 0)), ks(kid(t, 1))), [f_unlamb(f_flat(kid(t, 2), ks(kid(t, 0))), terms_len(ks(kid(t, 0))))]), kb(t), ke(t)))

@unsafe
def f_statement_more(p):
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, f_eq(tg(n), "Write"), u => f_write_statement(n, ts), u => f_choose(FParsed, f_binding_head(ts), u => f_parallel(ts, [n]), u => FParsed{n, ts}))

@unsafe
def f_typed_let_try(n, old, p):
  match p:
    case FParsed{ty, +ts}:
      f_choose(FParsed, f_eq(tg(ty), "Error"), u => FParsed{ty, ts}, u => f_choose(FParsed, f_eq(f_tx(ts), "="), u => f_choose(FParsed, f_eq(tg(n), "Ref"), u => f_let_value(n, f_let_ann(ty, f_expr(f_tl(ts), 0))), u => FParsed{fpe_message_at(n, nm(f_pn(f_err(ts, "a name (a parallel or typed let binds names; destructure in its body)"))), "a name (a parallel or typed let binds names; destructure in its body)"), Nil{}}), u => FParsed{n, old}))

@unsafe
def f_binding_head(+ts: List<&2,FToken>) -> Bool:
  (f_ascii_alpha(f_head(f_tx(ts))) || Char.is_eq(f_head(f_tx(ts)), '_') || f_eq(f_tx(ts), "+bind")) && Bool.not(f_reserved(f_tx(ts)))
