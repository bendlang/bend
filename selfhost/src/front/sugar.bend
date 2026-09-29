# Type-preserving surface desugaring and source error propagation.

law f_validate_result:
  for +r: FResult
  FResult

@unsafe
def f_last(
  +xs: List<&2, KTerm>,
) -> KTerm:
  match xs:
    case Nil{}:
      atom("Absent")
    case Con{+x, xt}:
      f_choose(KTerm, U32.is_eq(terms_len(xt), 0), u => x, u => f_last(xt))

@unsafe
def f_init(
  +xs: List<&2, KTerm>,
) -> List<&2, KTerm>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{x, +xt}:
      f_choose(List<&2, KTerm>, U32.is_eq(terms_len(xt), 0), u => Nil{}, u => Con{x, f_init(xt)})

# A single located monad term carries both the header name and type arguments.
@unsafe
def f_do_start(+ts: FInput, +begin: U32) -> FParsed:
  f_do_named(f_space(ts), begin)

@unsafe
def f_do_named(+ts: FInput, +begin: U32) -> FParsed:
  f_choose(FParsed, f_valid_name(f_tx(ts)), u => f_do_parameters(f_tx(ts), f_space(f_tl(ts)), begin), u => fpe_name_error(ts))

@unsafe
def f_do_parameters(+name: String, +ts: FInput, +begin: U32) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), "<>") || f_eq(f_tx(ts), "<"),
    u => f_do_parameters_resolved(name, ts, begin, f_do_header_name(name, ts)), u => fpe_error(ts, "expected <", "'<'"))

@unsafe
def f_do_header_name(+name: String, +input: FInput) -> KTerm:
  match input:
    case FInput{tokens, context}:
      match context:
        case FParseContext{scope, env, next}: f_context_resolve(kt_span("Ref", name, 0, 1, Nil{}, U32.add(f_begin(input), 1), U32.add(f_begin(input), 1)), scope)

@unsafe
def f_do_parameters_resolved(+name: String, +ts: FInput, +begin: U32, +resolved: KTerm) -> FParsed:
  f_choose(FParsed, f_context_stop(resolved), u => FParsed{resolved, ts},
    u => f_choose(FParsed, f_eq(f_tx(ts), "<>"), u => f_do_types(name, FParsed{kt("Args", "", 0, 1, Nil{}), f_tl(ts)}, begin, resolved), u => f_do_parameters_open(name, f_space(f_tl(ts)), begin, resolved)))

@unsafe
def f_do_parameters_open(+name: String, +ts: FInput, +begin: U32, +resolved: KTerm) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), ";"), u => fpe_error(ts, "expected term", "a term"), u => f_choose(FParsed, f_eq(f_tx(ts), ">") || f_eq(f_tx(ts), ">op"), u => f_do_types(name, FParsed{kt("Args", "", 0, 1, Nil{}), f_tl(ts)}, begin, resolved), u => f_do_types(name, f_args(ts, ">", Nil{}), begin, resolved)))

@unsafe
def f_do_bind_types(+types: List<&2,KTerm>, +ty: KTerm) -> List<&2,KTerm>:
  match types:
    case Nil{}: [ty]
    case Con{head, rest}: norm_join(f_init(types), [ty, f_last(types)])

@unsafe
def f_do_types(+name: String, +p: FParsed, +begin: U32, +resolved: KTerm) -> FParsed:
  match p:
    case FParsed{types, ts}:
      f_choose(FParsed, f_context_stop(types), u => p, u => f_do_header(kt_span("ADT", name, 0, 1, ks(types), begin, f_previous_end(ts)), f_space(ts), resolved))

@unsafe
def f_do_header(+monad: KTerm, +input: FInput, +resolved: KTerm) -> FParsed:
  match input:
    case FInput{tokens, context}:
      match context:
        case FParseContext{scope, env, next}: f_do_header_resolved(monad, input, scope, resolved)

@unsafe
def f_do_header_resolved(+monad: KTerm, +input: FInput, +scope: FParseScope, +resolved: KTerm) -> FParsed:
  match scope:
    case FParseScope{prior, index, ctorIndex, ns, aliases}:
      f_do_types_at(f_choose(KTerm, f_eq(dk(f_find(nm(resolved), prior)), "ADT"), u => f_adt(monad, ks(monad), f_find(nm(resolved), prior)), u => monad), input)

@unsafe
def f_do_types_at(+monad: KTerm, +ts: FInput) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_do(monad, f_space(f_tl(ts)), f_col(f_space(f_tl(ts)))), u => fpe_error(ts, "expected :", "':'"))

@unsafe
def f_do(+monad: KTerm, +ts: FInput, +indent: U32) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), "return"), u => f_do_return(monad, f_atid(ts), f_begin(ts), f_expr(f_tl(ts), 0)), u => f_do_statement(monad, f_expr(ts, 0), indent, f_begin(ts)))

@unsafe
def f_do_return(+monad: KTerm, +position: U32, +begin: U32, +p: FParsed) -> FParsed:
  match p:
    case FParsed{n, ts}:
      f_choose(FParsed, f_context_stop(n), u => p, u => f_do_result(kt_span("FDo", nm(monad), position, 1, [monad, n], begin, f_begin(f_space(ts))), ts))

@unsafe
def f_do_var(+term: KTerm, +input: FInput) -> Bool:
  f_eq(tg(term), "Var") || f_eq(tg(term), "FName")

@unsafe
def f_do_statement(+monad: KTerm, +p: FParsed, +indent: U32, +begin: U32) -> FParsed:
  match p:
    case FParsed{n, ts}:
      f_choose(FParsed, f_context_stop(n), u => p, u => f_do_statement_at(monad, n, f_space(ts), indent, begin))

@unsafe
def f_do_statement_at(+monad: KTerm, +n: KTerm, +ts: FInput, +indent: U32, +begin: U32) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), ":") && f_do_var(n, ts),
    u => f_do_annotated(monad, n, f_expr(f_tl(ts), 1), indent, begin),
    u => f_choose(FParsed, f_eq(f_tx(ts), ";") || (U32.is_eq(f_col(ts), indent) && Bool.not(f_eq(f_tx(ts), "<eof>"))),
      u => f_do_step(monad, n, ts, indent, begin),
      u => f_choose(FParsed, f_eq(f_tx(ts), "<-"),
        u => f_do_value(monad, kt_span("Var", "_", 0, 1, Nil{}, 0, 0), n, False{}, f_expr(f_tl(ts), 0), indent, begin),
        u => f_do_result(kt_span("FDo", nm(monad), ix(n), 0, [monad, n], kb(n), ke(n)), ts))))

@unsafe
def f_do_step(+monad: KTerm, +value: KTerm, +input: FInput, +indent: U32, +begin: U32) -> FParsed:
  f_do_step_type(monad, value, indent, begin, f_context_name(k_with_span(ref("Unit"), kb(value), ke(value)), input))

@unsafe
def f_do_step_type(+monad: KTerm, +value: KTerm, +indent: U32, +begin: U32, +p: FParsed) -> FParsed:
  match p:
    case FParsed{ty, ts}:
      f_choose(FParsed, f_context_stop(ty), u => p, u => f_do_value(monad, kt_span("Var", "_", 0, 1, Nil{}, 0, 0), ty, False{}, FParsed{value, ts}, indent, begin))

@unsafe
def f_do_annotated(+monad: KTerm, +binder: KTerm, +p: FParsed, +indent: U32, +begin: U32) -> FParsed:
  match p:
    case FParsed{ty, raw}:
      +ts = f_space(raw)
      f_choose(FParsed, f_context_stop(ty), u => p, u => f_choose(FParsed, f_eq(f_tx(ts), "=") || f_eq(f_tx(ts), "<-"), u => f_do_value(monad, binder, ty, f_eq(f_tx(ts), "="), f_expr(f_tl(ts), 0), indent, begin), u => fpe_error(ts, "expected <-", "'<-'")))

@unsafe
def f_do_value(+monad: KTerm, +binder: KTerm, +ty: KTerm, +pure: Bool, +p: FParsed, +indent: U32, +begin: U32) -> FParsed:
  match p:
    case FParsed{v, raw}:
      +ts = f_space(raw)
      +semi = f_eq(f_tx(ts), ";")
      +end = f_choose(U32, semi, u => f_end(ts), u => f_begin(ts))
      f_choose(FParsed, f_context_stop(v), u => p, u => f_do_open(monad, binder, ty, pure, v, end, indent, begin, f_space(f_choose(FInput, semi, u => f_tl(ts), u => ts))))

@unsafe
def f_do_open(+monad: KTerm, +binder: KTerm, +ty: KTerm, +pure: Bool, +value: KTerm, +end: U32, +indent: U32, +begin: U32, +input: FInput) -> FParsed:
  match input:
    case FInput{tokens, context}:
      match context:
        case FParseContext{scope, env, next}: f_do_opened(monad, ty, pure, value, begin, end, indent, env, f_context_open(binder, input))

@unsafe
def f_do_opened(+monad: KTerm, +ty: KTerm, +pure: Bool, +value: KTerm, +begin: U32, +end: U32, +indent: U32, +outer: List<&2,KTerm>, +opened: FParsed) -> FParsed:
  match opened:
    case FParsed{binder, input}:
      f_choose(FParsed, f_context_stop(binder), u => opened, u => f_do_tail(monad, binder, ty, pure, value, begin, end, f_context_close_done(f_do(monad, input, indent), outer)))

@unsafe
def f_do_tail(+monad: KTerm, +binder: KTerm, +ty: KTerm, +pure: Bool, +v: KTerm, +begin: U32, +end: U32, +p: FParsed) -> FParsed:
  match p:
    case FParsed{body, ts}:
      f_choose(FParsed, f_context_stop(body), u => p,
        u => f_choose(FParsed, pure,
          u => FParsed{kt_span("Let", "", 0, 1, [kt_span("Bind", nm(binder), ix(binder), qt(binder), [kt_span("Ann", "", 0, 1, [v, ty], begin, end)], kb(binder), ke(binder)), body], begin, end), ts},
          u => f_do_result(kt_span("FDo", nm(monad), ix(binder), 2, [monad, ty, v, k_lam(nm(binder), ix(binder), qt(binder), [body], begin, end, True{})], begin, end), ts)))

@unsafe
def f_do_result(+term: KTerm, +input: FInput) -> FParsed:
  match input:
    case FInput{tokens, context}:
      match context:
        case FParseContext{scope, env, next}:
          +name = nm(term) ++ f_choose(String, U32.is_eq(qt(term), 0), u => "", u => f_choose(String, U32.is_eq(qt(term), 1), u => ".pure", u => ".bind"))
          f_do_resolved(term, input, scope, f_context_resolve(kt_span("Ref", name, 0, 1, Nil{}, f_begin(f_space(input)), f_begin(f_space(input))), scope))

@unsafe
def f_do_resolved(+term: KTerm, +input: FInput, +scope: FParseScope, +resolved: KTerm) -> FParsed:
  match scope:
    case FParseScope{prior, index, ctorIndex, ns, aliases}:
      +head = k_with_span(resolved, kb(term), ke(term))
      +types = ks(kid(term, 0))
      f_choose(FParsed, f_context_stop(resolved), u => FParsed{resolved, input},
        u => FParsed{f_choose(KTerm, U32.is_eq(qt(term), 0),
          u => kt_span("Ann", "", 0, 1, [kid(term, 1), f_choose(KTerm, f_eq(dk(f_find(nm(resolved), prior)), "ADT"), u => kt_span("ADT", nm(resolved), 0, 1, types, kb(term), ke(term)), u => f_scope_apply_span(head, types, kb(term), ke(term)))], kb(term), ke(term)),
          u => f_scope_apply_span(head, f_choose(List<&2,KTerm>, U32.is_eq(qt(term), 1), u => norm_join(types, [kid(term, 1)]), u => norm_join(f_do_bind_types(types, kid(term, 1)), [kid(term, 2), kid(term, 3)])), kb(term), ke(term))), input})

@unsafe
def f_error_term(
  +t: KTerm,
) -> String:
  nm(fpe_term(t))

@unsafe
def f_error_defs(
  +ds: List<&2,KDef>,
) -> String:
  nm(fpe_defs(ds))

@unsafe
def f_validate_result(r):
  match r:
    case FResult{+book, +err, imports}:
      FResult{book, f_choose(String, String.is_empty(err), u => f_error_defs(book), u => err), imports}

@unsafe
def f_rewrite(+ts: FInput, +begin: U32) -> FParsed:
  f_rewrite_head(f_expr(ts, 0), begin)

@unsafe
def f_rewrite_head(+p: FParsed, +begin: U32) -> FParsed:
  match p:
    case FParsed{e, raw}:
      +ts = f_space(raw)
      f_choose(FParsed, f_context_stop(e), u => p,
        u => f_choose(FParsed, f_eq(f_tx(ts), "@"),
          u => f_choose(FParsed, f_eq(tg(e), "FName") || f_eq(tg(e), "Var"),
            u => f_rewrite_proof(e, begin, f_expect(f_expr(f_tl(ts), 0), ":")),
            u => fpe_error(f_tl(ts), "expected a rewrite binder", "a name before @ (a rewrite binder is one name: %e@E : P)")),
          u => f_rewrite_proof(kt_span("Var", "", ix(e), 1, Nil{}, kb(e), ke(e)), begin, f_expect(FParsed{e, ts}, ":"))))

@unsafe
def f_rewrite_proof(+binder: KTerm, +begin: U32, +p: FParsed) -> FParsed:
  match p:
    case FParsed{e, input}:
      f_choose(FParsed, f_context_stop(e), u => p, u => f_rewrite_open(binder, begin, e, input))

@unsafe
def f_rewrite_open(+binder: KTerm, +begin: U32, +proof: KTerm, +input: FInput) -> FParsed:
  match input:
    case FInput{tokens, context}:
      match context:
        case FParseContext{scope, env, next}:
          f_rewrite_opened(binder, begin, proof, next, env, f_context_open(kt_span("Var", nm(binder), 0, 1, Nil{}, kb(binder), ke(binder)), FInput{tokens, FParseContext{scope, Con{kt("RewriteVar", "_", next, 1, Nil{}), env}, U32.add(next, 1)}}))

@unsafe
def f_rewrite_opened(+origin: KTerm, +begin: U32, +proof: KTerm, +xi: U32, +outer: List<&2,KTerm>, +p: FParsed) -> FParsed:
  match p:
    case FParsed{binder, input}:
      f_rewrite_context_motive(origin, begin, proof, xi, binder, f_context_close_done(f_expr(input, 0), outer))

@unsafe
def f_rewrite_context_motive(+origin: KTerm, +begin: U32, +proof: KTerm, +xi: U32, +binder: KTerm, +p: FParsed) -> FParsed:
  match p:
    case FParsed{motive, raw}:
      +ts = f_space(raw)
      f_choose(FParsed, f_context_stop(motive), u => p,
        u => f_rewrite_context_body(origin, begin, proof, xi, binder, motive, f_context_flat(f_body(f_choose(FInput, f_eq(f_tx(ts), ";"), u => f_tl(ts), u => ts)), Nil{})))

@unsafe
def f_rewrite_context_body(+origin: KTerm, +begin: U32, +proof: KTerm, +xi: U32, +binder: KTerm, +motive: KTerm, +p: FParsed) -> FParsed:
  match p:
    case FParsed{body, ts}:
      +end = f_begin(f_space(ts))
      f_choose(FParsed, f_context_stop(body), u => p,
        u => FParsed{kt_span("Rwt", "", 0, 1, [proof, k_lam("_", xi, 1, [k_lam(nm(binder), ix(binder), 1, [motive], kb(origin), ke(origin), False{})], begin, end, False{}), body], begin, end), ts})

law f_law_where:
  for +name: String
  for +binder: KTerm
  for +ty: KTerm
  for +p: FParsed
  for +book: List<&2,KDef>
  for +imports: List<&2, KTerm>
  for +clauses: List<&2, KTerm>
  for +scope: FParseScope
  FRawResult

law f_erased_local:
  for +ts: FInput
  for +begin: U32
  for +column: U32
  FParsed

@unsafe
def f_law_where(name, binder, ty, p, book, imports, clauses, scope):
  match p:
    case FParsed{predicate, ts}:
      f_choose(FRawResult, f_context_stop(predicate), u => f_result(book, predicate, imports),
        u => f_law(name, f_skip(ts), book, imports, Con{k_with_children(binder, [f_app_span(k_with_span(ref("Exists"), kb(binder), ke(binder)), [ty, k_lam(nm(binder), ix(binder), 1, [predicate], kb(binder), ke(binder), False{})], kb(binder), ke(binder))]), clauses}, scope))

@unsafe
def f_erased_local(ts, begin, column):
  f_choose(FParsed, f_valid_name(f_tx(ts)), u => f_statement(FParsed{kt_span("Var", f_tx(ts), f_atid(ts), 0, Nil{}, begin, f_end(ts)), f_tl(ts)}, begin, column), u => fpe_error(ts, "expected a name", "a name"))

@unsafe
def f_write_statement(
  +n: KTerm,
  +ts: FInput,
) -> FParsed:
  f_choose(FParsed, (f_eq(f_tx(ts), ";") || U32.is_eq(f_col(f_skip(ts)), U32.and(ix(n), 65535))) && Bool.not(f_eq(f_tx(f_skip(ts)), "<eof>")), u => f_let_value(kt("Ref", nm(n), ix(n), 1, Nil{}), FParsed{kid(n, 0), ts}), u => FParsed{kid(n, 0), ts})

law f_group_namespace:
  for +n: KTerm
  for +p: FParsed
  FParsed

@unsafe
def f_group_namespace(n, p):
  match p:
    case FParsed{ty, ts}:
      f_choose(FParsed, f_eq(tg(ty), "Error"),
        u => FParsed{f_choose(KTerm, String.is_empty(f_error_term(n)), u => ty, u => n), ts},
        u => f_expect(FParsed{f_context_namespace_at(n, ty, ts, f_begin(f_space(ts))), ts}, ")"))

