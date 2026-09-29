# Type-preserving surface desugaring and source error propagation.

law f_validate_result:
  for +r: FResult
  FResult

law f_rewrite:
  for +ts: List<&2, FToken>
  FParsed

law f_rewrite_head:
  for +p: FParsed
  FParsed

law f_rewrite_proof:
  for +name: String
  for +id: U32
  for +p: FParsed
  FParsed

law f_rewrite_motive:
  for +name: String
  for +id: U32
  for +e: KTerm
  for +p: FParsed
  FParsed

law f_rewrite_body:
  for +e: KTerm
  for +motive: KTerm
  for +p: FParsed
  FParsed

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
def f_do_start(+ts: List<&2,FToken>, +begin: U32) -> FParsed:
  f_do_named(f_space(ts), begin)

@unsafe
def f_do_named(+ts: List<&2,FToken>, +begin: U32) -> FParsed:
  f_choose(FParsed, f_valid_name(f_tx(ts)), u => f_do_parameters(f_tx(ts), f_space(f_tl(ts)), begin), u => fpe_name_error(ts))

@unsafe
def f_do_parameters(+name: String, +ts: List<&2,FToken>, +begin: U32) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), "<>"), u => f_do_types(name, FParsed{kt("Args", "", 0, 1, Nil{}), f_tl(ts)}, begin), u => f_choose(FParsed, f_eq(f_tx(ts), "<"), u => f_do_parameters_open(name, f_space(f_tl(ts)), begin), u => fpe_error(ts, "expected <", "'<'")))

@unsafe
def f_do_parameters_open(+name: String, +ts: List<&2,FToken>, +begin: U32) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), ";"), u => fpe_error(ts, "expected term", "a term"), u => f_choose(FParsed, f_eq(f_tx(ts), ">") || f_eq(f_tx(ts), ">op"), u => f_do_types(name, FParsed{kt("Args", "", 0, 1, Nil{}), f_tl(ts)}, begin), u => f_do_types(name, f_args(ts, ">", Nil{}), begin)))

@unsafe
def f_do_bind_types(+types: List<&2,KTerm>, +ty: KTerm) -> List<&2,KTerm>:
  match types:
    case Nil{}: [ty]
    case Con{head, rest}: norm_join(f_init(types), [ty, f_last(types)])

@unsafe
def f_do_types(+name: String, +p: FParsed, +begin: U32) -> FParsed:
  match p:
    case FParsed{types, ts}:
      f_choose(FParsed, f_eq(tg(types), "Error"), u => FParsed{types, ts}, u => f_do_types_at(kt_span("ADT", name, 0, 1, ks(types), begin, f_previous_end(ts)), f_space(ts)))

@unsafe
def f_do_types_at(+monad: KTerm, +ts: List<&2,FToken>) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_do(monad, f_skip(f_tl(ts)), f_col(f_skip(f_tl(ts)))), u => f_err(ts, "expected :"))

@unsafe
def f_do(+monad: KTerm, +ts: List<&2,FToken>, +indent: U32) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), "return"), u => f_do_return(monad, f_atid(ts), f_begin(ts), f_expr(f_tl(ts), 0)), u => f_do_statement(monad, f_expr(ts, 0), indent))

@unsafe
def f_do_return(+monad: KTerm, +position: U32, +begin: U32, +p: FParsed) -> FParsed:
  match p:
    case FParsed{n, ts}:
      FParsed{kt_span("FDo", nm(monad), position, 1, [kt_span("ADT", nm(monad), position, 1, ks(monad), kb(monad), ke(monad)), n], f_choose(U32, U32.is_eq(f_begin(f_space(ts)), 0), u => 0, u => begin), f_begin(f_space(ts))), ts}

@unsafe
def f_do_statement(+monad: KTerm, +p: FParsed, +indent: U32) -> FParsed:
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, f_eq(f_tx(ts), ":") && f_eq(tg(n), "Ref") && f_alias_valid(nm(n)), u => f_do_annotated(monad, n, f_expr(f_tl(ts), 1), indent), u => f_choose(FParsed, f_eq(f_tx(ts), "<-"), u => f_do_value(monad, kt_span("Ref", "_", ix(n), 1, Nil{}, kb(n), ke(n)), n, False{}, f_expr(f_tl(ts), 0), indent), u => f_choose(FParsed, (f_eq(f_tx(ts), ";") || U32.is_eq(f_col(f_skip(ts)), indent)) && Bool.not(f_eq(f_tx(f_skip(ts)), "<eof>")), u => f_do_value(monad, kt_span("Ref", "_", ix(n), 1, Nil{}, kb(n), ke(n)), k_with_span(ref("Unit"), kb(n), ke(n)), False{}, FParsed{n, ts}, indent), u => FParsed{kt_span("FDo", nm(monad), ix(n), 0, [kt_span("ADT", nm(monad), ix(n), 1, ks(monad), kb(monad), ke(monad)), n], kb(n), ke(n)), ts})))

@unsafe
def f_do_annotated(+monad: KTerm, +binder: KTerm, +p: FParsed, +indent: U32) -> FParsed:
  match p:
    case FParsed{ty, +ts}:
      f_choose(FParsed, f_eq(tg(ty), "Error"), u => FParsed{ty, ts}, u => f_choose(FParsed, f_eq(f_tx(ts), "=") || f_eq(f_tx(ts), "<-"), u => f_do_value(monad, binder, ty, f_eq(f_tx(ts), "="), f_expr(f_tl(ts), 0), indent), u => f_err(ts, "expected <-")))

@unsafe
def f_do_value(+monad: KTerm, +binder: KTerm, +ty: KTerm, +pure: Bool, +p: FParsed, +indent: U32) -> FParsed:
  match p:
    case FParsed{v, ts}:
      +end = f_choose(U32, f_eq(f_tx(f_space(ts)), ";"), u => f_end(f_space(ts)), u => f_begin(f_space(ts)))
      f_do_tail(monad, binder, ty, pure, v, end, f_do(monad, f_skip(ts), indent))

@unsafe
def f_do_tail(+monad: KTerm, +binder: KTerm, +ty: KTerm, +pure: Bool, +v: KTerm, +end: U32, +p: FParsed) -> FParsed:
  match p:
    case FParsed{body, ts}:
      FParsed{f_choose(KTerm, pure, u => kt_span("Local", "Do", 0, 1, [binder, kt_span("Ann", "", 0, 1, [v, ty], kb(binder), end), body], kb(binder), end), u => kt_span("FDo", nm(monad), ix(binder), 2, [kt_span("ADT", nm(monad), ix(binder), 1, ks(monad), kb(monad), ke(monad)), ty, v, k_lam(nm(binder), ix(binder), qt(binder), [body], kb(binder), end, True{})], kb(binder), end)), ts}

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
def f_rewrite(ts):
  f_rewrite_head(f_expr(ts, 0))

@unsafe
def f_rewrite_head(p):
  match p:
    case FParsed{+e, +ts}:
      f_choose(FParsed, f_eq(f_tx(ts), "@"), u => f_rewrite_proof(nm(e), ix(e), f_expect(f_expr(f_tl(ts), 0), ":")), u => f_rewrite_proof("", ix(e), f_expect(FParsed{e, ts}, ":")))

@unsafe
def f_rewrite_proof(name, id, p):
  match p:
    case FParsed{e, ts}:
      f_rewrite_motive(name, id, e, f_expr(ts, 0))

@unsafe
def f_rewrite_motive(name, id, e, p):
  match p:
    case FParsed{motive, ts}:
      f_rewrite_body(e, k_lam("_", U32.add(id, 2147483648), 4, [k_lam(name, id, 1, [motive], 0, 0, False{})], 0, 0, False{}), f_body(ts))

@unsafe
def f_rewrite_body(e, motive, p):
  match p:
    case FParsed{body, ts}:
      FParsed{kt("Rwt", "", 0, 1, [e, motive, body]), ts}


# Layout-sensitive locals and refinement clauses.

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
  for +ts: List<&2, FToken>
  for +begin: U32
  FParsed

@unsafe
def f_law_where(name, binder, ty, p, book, imports, clauses, scope):
  match p:
    case FParsed{predicate, ts}:
      f_law_type(name, binder, FParsed{f_app_span(k_with_span(ref("Exists"), kb(binder), ke(binder)), [ty, k_lam(nm(binder), ix(binder), 1, [predicate], kb(binder), ke(binder), False{})], kb(binder), ke(binder)), ts}, book, imports, clauses, scope)

@unsafe
def f_erased_local(ts, begin):
  f_choose(FParsed, f_valid_name(f_tx(ts)), u => f_statement(FParsed{kt_span("Ref", f_tx(ts), f_atid(ts), 0, Nil{}, begin, f_end(ts)), f_tl(ts)}), u => fpe_error(ts, "expected a name", "a name"))

@unsafe
def f_write_statement(
  +n: KTerm,
  +ts: List<&2, FToken>,
) -> FParsed:
  f_choose(FParsed, (f_eq(f_tx(ts), ";") || U32.is_eq(f_col(f_skip(ts)), U32.and(ix(n), 65535))) && Bool.not(f_eq(f_tx(f_skip(ts)), "<eof>")), u => f_let_value(kt("Ref", nm(n), ix(n), 1, Nil{}), FParsed{kid(n, 0), ts}), u => FParsed{kid(n, 0), ts})


law f_group_namespace:
  for +n: KTerm
  for +p: FParsed
  FParsed

law f_template_expr:
  for +p: FParsed
  FParsed

@unsafe
def f_group_namespace(n, p):
  match p:
    case FParsed{ty, ts}:
      f_choose(FParsed, f_eq(tg(ty), "Error"),
        u => FParsed{f_choose(KTerm, String.is_empty(f_error_term(n)), u => ty, u => n), ts},
        u => FParsed{f_namespace(n, ty), ts})

@unsafe
def f_template_expr(p):
  match p:
    case FParsed{t, ts}:
      FParsed{kt("TemplateArg", "", 0, 0, [t]), ts}

