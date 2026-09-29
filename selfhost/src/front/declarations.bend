# Declarations retain laws, telescopes, constructor fields and foreign paths.
type FResult is Data:
  FResult{+book: List<&2, KDef>, +error: String, +imports: List<&2, KTerm>}

# Internal parser transport only; public FResult remains unchanged.
type FRawResult is Data:
  FRawResult{+book: List<&2, KDef>, +error: KTerm, +imports: List<&2, KTerm>}

law f_put:
  for +d: KDef
  for +book: List<&2, KDef>
  List<&2, KDef>

law f_tops:
  for +ts0: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
  for +scope: FParseScope
  FRawResult

law f_top:
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
  for +scope: FParseScope
  FRawResult

law f_top_ready:
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
  for +scope: FParseScope
  FRawResult

law f_tele:
  for +ts0: List<&2, FToken>
  for +end: String
  for +acc: List<&2, KTerm>
  FParsed

law f_tele_at:
  for +ts: List<&2, FToken>
  for +end: String
  for +acc: List<&2, KTerm>
  FParsed

law f_tele_type:
  for +binder: KTerm
  for +temp: Bool
  for +p: FParsed
  for +end: String
  for +acc: List<&2, KTerm>
  FParsed

law f_def_type:
  for +name: String
  for +pars: List<&2, KTerm>
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
  for +scope: FParseScope
  FRawResult

law f_def_signature:
  for +name: String
  for +pars: List<&2, KTerm>
  for +ty: KTerm
  for +book: List<&2, KDef>
  KTerm

law f_def_body:
  for +name: String
  for +pars: List<&2, KTerm>
  for +ty: KTerm
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
  for +scope: FParseScope
  FRawResult

law f_foreign:
  for +name: String
  for +pars: List<&2, KTerm>
  for +ty: KTerm
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
  for +paths: List<&2, KTerm>
  for +scope: FParseScope
  FRawResult

law f_law:
  for +name: String
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +clauses: List<&2, KTerm>
  for +scope: FParseScope
  FRawResult

law f_law_clause:
  for +name: String
  for +exi: Bool
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +clauses: List<&2, KTerm>
  for +scope: FParseScope
  FRawResult

law f_law_type:
  for +name: String
  for +binder: KTerm
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +clauses: List<&2, KTerm>
  for +scope: FParseScope
  FRawResult

law f_law_end:
  for +name: String
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +clauses: List<&2, KTerm>
  for +scope: FParseScope
  FRawResult

law f_type:
  for +name: String
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +scope: FParseScope
  FRawResult

law f_type_params:
  for +name: String
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +scope: FParseScope
  FRawResult

law f_type_kind:
  for +name: String
  for +pars: List<&2, KTerm>
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +scope: FParseScope
  FRawResult

law f_type_ctors:
  for +name: String
  for +pars: List<&2, KTerm>
  for +ty: KTerm
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +ctors: List<&2, KDef>
  for +scope: FParseScope
  FRawResult

law f_type_ctor:
  for +name: String
  for +pars: List<&2, KTerm>
  for +ty: KTerm
  for +ctor: String
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +ctors: List<&2, KDef>
  for +scope: FParseScope
  FRawResult

law f_param_refs:
  for +pars: List<&2, KTerm>
  List<&2, KTerm>

law f_body:
  for +ts: List<&2, FToken>
  FParsed

law f_statement:
  for +p: FParsed
  for +begin: U32
  FParsed

law f_let_value:
  for +pat: KTerm
  for +p: FParsed
  FParsed

law f_let_body:
  for +pat: KTerm
  for +v: KTerm
  for +p: FParsed
  FParsed

law f_match_heads:
  for +ts: List<&2, FToken>
  for +indent: U32
  for +acc: List<&2, KTerm>
  FParsed

law f_match_head:
  for +p: FParsed
  for +indent: U32
  for +acc: List<&2, KTerm>
  FParsed

law f_case_pats:
  for +ts: List<&2, FToken>
  for +indent: U32
  for +heads: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +pats: List<&2, KTerm>
  for +start: List<&2,FToken>
  FParsed

law f_case_pat:
  for +p: FParsed
  for +indent: U32
  for +heads: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +pats: List<&2, KTerm>
  for +start: List<&2,FToken>
  FParsed

law f_case_body:
  for +p: FParsed
  for +indent: U32
  for +heads: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +pats: List<&2, KTerm>
  FParsed

@unsafe
def f_parse(
  +source: String,
) -> FResult:
  fpe_finish(source, f_tops(f_lex(source, 1, 0, 0, Nil{}), Nil{}, Nil{}, False{}, f_parse_scope_empty()))

@unsafe
def f_result(
  +book: List<&2, KDef>,
  +err: KTerm,
  +imports: List<&2, KTerm>,
) -> FRawResult:
  FRawResult{List.reverse(&2, KDef, book), err, List.reverse(&2, KTerm, imports)}

@unsafe
def f_find(
  +name: String,
  +book: List<&2, KDef>,
) -> KDef:
  match book:
    case Nil{}:
      KDef{name, "Missing", 0, 0, atom("Absent"), atom("Absent"), Nil{}, False{}, False{}}
    case Con{+d, ds}:
      f_find_next(name, d, ds, f_eq(name, dn(d)))

@unsafe
def f_find_next(
  +name: String, +d: KDef, +ds: List<&2, KDef>, +same: Bool,
) -> KDef:
  match same:
    case True{}: d
    case False{}: f_find(name, ds)

@unsafe
def f_tops(ts0, book, imports, unsafe, scope):
  f_top(f_skip(ts0), book, imports, unsafe, scope)

@unsafe
def f_top(ts, book, imports, unsafe, scope):
  f_choose(FRawResult, unsafe,
    u => f_choose(FRawResult, f_eq(f_tx(ts), "def"), u => f_top_ready(ts, book, imports, unsafe, scope), u => f_result(book, f_pn(fpe_error(ts, "expected def after @unsafe", "'def' (@unsafe marks the def below it)")), imports)),
    u => f_top_ready(ts, book, imports, unsafe, scope))

@unsafe
def f_top_ready(ts, book, imports, unsafe, scope):
  f_choose(FRawResult, f_eq(f_tx(ts), "<eof>"), u => f_result(book, atom("Absent"), imports),
    u => f_choose(FRawResult, f_eq(f_tx(ts), "@") && f_eq(f_tx(f_tl(ts)), "unsafe"), u => f_tops(f_tl(f_tl(ts)), book, imports, True{}, scope),
    u => f_choose(FRawResult, f_eq(f_tx(ts), "import"), u => f_import_leading(ts, book, imports, unsafe),
    u => f_choose(FRawResult, f_eq(f_tx(ts), "law"), u => f_named_top(f_space(f_tl(ts)), book, imports, False{}, scope),
    u => f_choose(FRawResult, f_eq(f_tx(ts), "def"), u => f_def_header(f_space(f_tl(ts)), book, imports, unsafe, scope),
    u => f_choose(FRawResult, f_eq(f_tx(ts), "type"), u => f_named_top(f_space(f_tl(ts)), book, imports, True{}, scope),
    u => f_result(book, f_pn(f_choose(FParsed, f_eq(f_tx(ts), "@"), u => f_err(ts, "expected def, law, type or import"), u => fpe_error(ts, "expected def, law, type or import", "'def', 'type' or 'law'"))), imports)))))))

@unsafe
def f_def_header(
  +ts: List<&2,FToken>,
  +book: List<&2,KDef>,
  +imports: List<&2,KTerm>,
  +unsafe: Bool, +scope: FParseScope
) -> FRawResult:
  +suffix = f_eq(f_tx(f_tl(ts)), "?") && U32.is_eq(f_line(ts), f_line(f_tl(ts))) && U32.is_eq(f_col(f_tl(ts)), U32.add(f_col(ts), U32.from_nat(String.length(f_tx(ts)))))
  +rest = f_space(f_choose(List<&2,FToken>, suffix, u => f_tl(f_tl(ts)), u => f_tl(ts)))
  f_choose(FRawResult, Bool.not(f_valid_name(f_tx(ts))),
    u => f_result(book, f_pn(fpe_name_error(ts)), imports),
    u => f_def_context_header(ts, rest, book, imports, unsafe || suffix, f_decl_find(f_tx(ts), book, scope), scope))

@unsafe
def f_import(
  +ts: List<&2, FToken>,
  +book: List<&2, KDef>,
  +imports: List<&2, KTerm>,
) -> FRawResult:
  f_import_path(f_tl(ts), f_tl(ts), "", book, imports, ts)

# The declaration book starts empty and grows on every law, def, or type.
# Imports leave it empty; a decorator also closes the leading-import region.
law f_import_leading:
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
  FRawResult

@unsafe
def f_import_leading(ts, book, imports, unsafe):
  match book:
    case Nil{}:
      f_choose(FRawResult, unsafe, u => f_result(book, f_pn(fpe_error(ts, "expected def after @unsafe", "'def' (@unsafe marks the def below it)")), imports), u => f_import(ts, book, imports))
    case Con{d, rest}:
      f_result(book, f_pn(fpe_error(ts, "expected def, law or type; imports must precede declarations", "'def', 'type' or 'law'")), imports)

@unsafe
def f_tele(ts0, end, acc):
  f_tele_at(f_skip(ts0), end, acc)

@unsafe
def f_tele_at(ts, end, acc):
  f_choose(FParsed, f_eq(f_tx(ts), end), u => FParsed{kt("Tele", "", 0, 0, List.reverse(&2, KTerm, acc)), f_tl(ts)}, u => f_validate_param(ts, end, acc))

@unsafe
def f_tele_binder(
  +binder: KTerm,
  +temp: Bool,
  +ts: List<&2, FToken>,
  +end: String,
  +acc: List<&2, KTerm>,
) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_tele_type(binder, temp, f_expr(f_tl(ts), 0), end, acc), u => f_choose(FParsed, U32.is_eq(qt(binder), 1) && Bool.not(temp), u => f_tele_type(kt_span(tg(binder), nm(binder), ix(binder), 0, Nil{}, kb(binder), ke(binder)), temp, FParsed{k_with_span(atom("Qnt"), kb(binder), ke(binder)), ts}, end, acc), u => fpe_error(ts, "expected : (a marked parameter requires its type)", "':'")))

@unsafe
def f_tele_type(binder, temp, p, end, acc):
  match p:
    case FParsed{+ty, +ts}:
      f_choose(FParsed, f_eq(tg(ty), "Error"), u => FParsed{ty, ts}, u => f_tele(f_choose(List<&2, FToken>, f_eq(f_tx(ts), ","), u => f_tl(ts), u => ts), end, Con{kt_span(f_choose(String, temp, u => "Template", u => "Bind"), nm(binder), ix(binder), qt(binder), [ty], kb(binder), ke(binder)), acc}))

@unsafe
def f_tbind(
  +pars: List<&2, KTerm>,
  +result: KTerm,
) -> KTerm:
  match pars:
    case Nil{}:
      result
    case Con{+p, ps}:
      kt_span("All", nm(p), ix(p), qt(p), [kid(p, 0), f_tbind(ps, result)], kb(p), ke(p))

@unsafe
def f_lbind(
  +pars: List<&2, KTerm>,
  +body: KTerm,
) -> KTerm:
  match pars:
    case Nil{}:
      body
    case Con{+p, ps}:
      k_lam(nm(p), ix(p), qt(p), [f_lbind(ps, body)], kb(p), ke(p), True{})

@unsafe
def f_templates(
  +pars: List<&2, KTerm>,
) -> U32:
  match pars:
    case Nil{}:
      0
    case Con{p, ps}:
      U32.add(f_choose(U32, f_eq(tg(p), "Template"), u => 1, u => 0), f_templates(ps))

@unsafe
def f_def_base(
  +name: String,
  +p: FParsed,
  +book: List<&2, KDef>,
  +imports: List<&2, KTerm>,
  +unsafe: Bool, +scope: FParseScope
) -> FRawResult:
  match p:
    case FParsed{+pars, +ts}:
      f_choose(FRawResult, f_eq(tg(pars), "Error"), u => f_result(book, pars, imports), u => f_choose(FRawResult, f_eq(f_tx(ts), "->"), u => f_def_type(name, ks(pars), f_expr(f_tl(ts), 0), book, imports, unsafe, scope), u => f_def_type(name, ks(pars), FParsed{f_choose(KTerm, f_eq(dk(f_find(name, book)), "Missing") && (Bool.not(f_eq(f_alias(name, imports), name)) || f_def_fillable(f_decl_find(name, book, scope))), u => kt("ImportLaw", name, 0, 0, ks(pars)), u => dt(f_find(name, book))), ts}, book, imports, unsafe, scope)))

@unsafe
def f_def_type(name, pars, p, book, imports, unsafe, scope):
  match p:
    case FParsed{+ty, +ts}:
      f_choose(FRawResult, f_eq(tg(ty), "Error"), u => f_result(book, ty, imports), u => f_choose(FRawResult, f_eq(tg(ty), "Absent"), u => f_result(book, f_pn(fpe_error(ts, "definition without return type needs a law: " ++ name, "'->' (a def with no return type fills a law; no law named " ++ name ++ " is in scope)")), imports), u => f_choose(FRawResult, f_eq(f_tx(f_skip(f_tl(ts))), "import"), u => f_foreign(name, pars, f_def_signature(name, pars, ty, book), f_skip(f_tl(ts)), book, imports, unsafe, Nil{}, scope), u => f_def_body(name, pars, f_def_signature(name, pars, ty, book), f_body_after(f_expect(FParsed{ty, ts}, ":")), book, imports, unsafe, scope))))

@unsafe
def f_def_signature(name, pars, ty, book):
  f_choose(KTerm, f_eq(dk(f_find(name, book)), "Missing") && Bool.not(f_eq(tg(ty), "ImportLaw")), u => f_tbind(pars, ty), u => ty)

@unsafe
def f_def_body(name, pars, ty, p, book, imports, unsafe, scope):
  match p:
    case FParsed{+body, ts}:
      f_choose(FRawResult, f_eq(tg(body), "Error"), u => f_result(book, body, imports), u => f_tops(ts, f_put(KDef{name, "Def", terms_len(pars), f_choose(U32, f_eq(dk(f_find(name, book)), "Missing"), u => f_templates(pars), u => dx(f_find(name, book))), ty, kt("Body", "", fc_start(pars, ty, body, Bool.not(f_eq(dk(f_find(name, book)), "Missing"))), 0, [kt("Params", "", 0, 0, pars), body]), Nil{}, False{}, unsafe}, book), imports, False{}, scope))

@unsafe
def f_foreign(name, pars, ty, ts, book, imports, unsafe, paths, scope):
  f_choose(FRawResult, f_eq(f_tx(ts), "import"), u => f_choose(FRawResult, f_foreign_path_valid(ts), u => f_foreign(name, pars, ty, f_skip(f_tl(f_tl(ts))), book, imports, unsafe, Con{kt("Path", f_unquote(f_tx(f_tl(ts))), 0, 0, Nil{}), paths}, scope), u => f_result(book, fpe_foreign(f_space(f_tl(ts))), imports)), u => f_tops(ts, f_put(KDef{name, "Def", terms_len(pars), 0, ty, kt("Foreign", name, 0, 0, List.reverse(&2, KTerm, paths)), Nil{}, False{}, unsafe}, book), imports, False{}, scope))

@unsafe
def f_law_base(
  +name: String,
  +ts: List<&2, FToken>,
  +book: List<&2, KDef>,
  +imports: List<&2, KTerm>,
  +clauses: List<&2, KTerm>, +scope: FParseScope
) -> FRawResult:
  f_choose(FRawResult, f_eq(f_tx(ts), "for") || f_eq(f_tx(ts), "exs"), u => f_law_clause(name, f_eq(f_tx(ts), "exs"), f_tl(ts), book, imports, clauses, scope), u => f_law_end(name, f_expr(ts, 0), book, imports, List.reverse(&2, KTerm, clauses), scope))

@unsafe
def f_law_clause(name, exi, ts, book, imports, clauses, scope):
  f_choose(FRawResult, Bool.not(exi) && f_eq(f_tx(ts), "~") && U32.is_lt(f_templates(clauses), terms_len(clauses)),
    u => f_result(book, f_pn(fpe_error(ts, "expected a plain clause (only leading clauses take ~)", "a plain clause (only leading clauses take ~)")), imports),
    u => f_law_type(name, kt_span(f_choose(String, exi, u => "Exists", u => f_choose(String, f_eq(f_tx(ts), "~"), u => "Template", u => "Bind")), f_tx(f_unmark(ts)), f_atid(ts), f_quant(ts), Nil{}, f_begin(f_unmark(ts)), f_end(f_unmark(ts))), f_expr(f_tl(f_tl(f_unmark(ts))), 0), book, imports, clauses, scope))

@unsafe
def f_law_type(name, binder, p, book, imports, clauses, scope):
  match p:
    case FParsed{+ty, ts}:
      f_choose(FRawResult, f_eq(tg(ty), "Error"), u => f_result(book, ty, imports), u => f_choose(FRawResult, f_eq(f_tx(f_skip(ts)), "where"), u => f_law_where(name, binder, ty, f_expr(f_tl(f_skip(ts)), 0), book, imports, clauses, scope), u => f_law(name, f_skip(ts), book, imports, Con{k_with_children(binder, [ty]), clauses}, scope)))

@unsafe
def f_law_bind(
  +clauses: List<&2, KTerm>,
  +ty: KTerm,
) -> KTerm:
  match clauses:
    case Nil{}:
      ty
    case Con{+c, cs}:
      f_choose(KTerm, f_eq(tg(c), "Exists"), u => f_app_span(kt_span("Ref", "Exists", 0, 1, Nil{}, kb(c), ke(c)), [kid(c, 0), k_lam(nm(c), ix(c), 1, [f_law_bind(cs, ty)], kb(c), ke(c), False{})], kb(c), ke(c)), u => kt_span("All", nm(c), ix(c), qt(c), [kid(c, 0), f_law_bind(cs, ty)], kb(c), ke(c)))

@unsafe
def f_law_end(name, p, book, imports, clauses, scope):
  match p:
    case FParsed{+ty, ts}:
      f_choose(FRawResult, f_eq(tg(ty), "Error"), u => f_result(book, ty, imports), u => f_tops(ts, Con{KDef{name, "Def", f_law_arity(clauses), f_templates(clauses), f_law_bind(clauses, ty), atom("Absent"), Nil{}, False{}, False{}}, book}, imports, False{}, scope))

@unsafe
def f_type_base(
  +name: String,
  +ts: List<&2, FToken>,
  +book: List<&2, KDef>,
  +imports: List<&2, KTerm>, +scope: FParseScope
) -> FRawResult:
  f_choose(FRawResult, f_eq(f_tx(ts), "<") || f_eq(f_tx(ts), "<-"), u => f_type_params(name, f_tele(f_choose(List<&2, FToken>, f_eq(f_tx(ts), "<-"), u => Con{FToken{"-", f_line(ts), U32.add(f_col(ts), 1), 0, f_cursor_add(f_begin(ts), 1), f_end(ts), f_cursor_add(f_begin(ts), 1)}, f_tl(ts)}, u => f_tl(ts)), ">", Nil{}), book, imports, scope), u => f_type_params(name, FParsed{kt("Tele", "", 0, 0, Nil{}), ts}, book, imports, scope))

@unsafe
def f_type_params(name, p, book, imports, scope):
  match p:
    case FParsed{pars, ts}:
      f_choose(FRawResult, f_eq(tg(pars), "Error"), u => f_result(book, pars, imports), u => f_type_kind(name, ks(pars), f_expect(f_expr_after(f_expect(FParsed{pars, ts}, "is"), 0), ":"), book, imports, scope))

@unsafe
def f_type_kind(name, pars, p, book, imports, scope):
  match p:
    case FParsed{ty, ts}:
      f_choose(FRawResult, f_eq(tg(ty), "Error"), u => f_result(book, ty, imports), u => f_type_ctors(name, pars, ty, f_space(ts), book, imports, Nil{}, scope))

@unsafe
def f_type_ctors(name, pars, ty, ts, book, imports, ctors, scope):
  f_choose(FRawResult, (f_ascii_alpha(f_head(f_tx(ts))) || Char.is_eq(f_head(f_tx(ts)), '_')) && Bool.not(f_eq(f_tx(ts), "def") || f_eq(f_tx(ts), "type") || f_eq(f_tx(ts), "law")),
    u => f_type_ctor_header(name, pars, ty, ts, book, imports, ctors, scope),
    u => f_top(ts, Con{KDef{name, "ADT", terms_len(pars), 0, f_tbind(pars, ty), atom("Absent"), List.reverse(&2, KDef, ctors), False{}, False{}}, book}, imports, False{}, scope))

@unsafe
def f_type_ctor_header(
  +name: String, +pars: List<&2,KTerm>, +ty: KTerm, +ts: List<&2,FToken>,
  +book: List<&2,KDef>, +imports: List<&2,KTerm>, +ctors: List<&2,KDef>, +scope: FParseScope,
) -> FRawResult:
  f_choose(FRawResult, Bool.not(f_valid_name(f_tx(ts))),
    u => f_result(book, f_pn(fpe_name_error(ts)), imports),
    u => f_choose(FRawResult, Bool.not(f_eq(f_alias(f_tx(ts), imports), f_tx(ts))),
      u => f_result(book, f_pn(fpe_word(ts, "an import alias cannot name a constructor", "a fresh constructor name (" ++ f_import_alias_head(f_tx(ts)) ++ " is an import's alias)")), imports),
    u => f_choose(FRawResult, Bool.not(f_eq(dk(f_find(f_tx(ts), ctors)), "Missing")) || f_decl_ctor_taken(f_tx(ts), book, scope),
      u => f_result(book, f_pn(fpe_word(ts, "expected a fresh constructor name (duplicate declaration: " ++ f_tx(ts) ++ ")", "a fresh constructor name (duplicate declaration: " ++ f_tx(ts) ++ ")")), imports),
    u => f_choose(FRawResult, f_eq(f_tx(f_space(f_tl(ts))), "{"),
      u => f_type_ctor(name, pars, ty, f_tx(ts), f_tele(f_tl(f_space(f_tl(ts))), "}", Nil{}), book, imports, ctors, scope),
      u => f_result(book, f_pn(fpe_error(f_space(f_tl(ts)), "expected {", "'{'")), imports)))))

@unsafe
def f_type_ctor(name, pars, ty, ctor, p, book, imports, ctors, scope):
  match p:
    case FParsed{fields, ts}:
      f_choose(FRawResult, f_eq(tg(fields), "Error"), u => f_result(book, fields, imports), u => f_type_ctors(name, pars, ty, f_space(ts), book, imports, Con{KDef{ctor, "Ctr", terms_len(ks(fields)), 0, f_tbind(pars, f_tbind(ks(fields), kt("ADT", name, 0, 1, f_param_refs(pars)))), kt("Absent", ctor, 0, 0, Nil{}), Nil{}, False{}, False{}}, ctors}, scope))

@unsafe
def f_param_refs(pars):
  match pars:
    case Nil{}:
      Nil{}
    case Con{+p, ps}:
      Con{kt_span("Ref", nm(p), ix(p), qt(p), Nil{}, kb(p), ke(p)), f_param_refs(ps)}

@unsafe
def f_body(ts):
  f_body_context(ts, 0)

@unsafe
def f_body_at(
  +ts: List<&2, FToken>,
) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), "-"), u => f_erased_local(f_tl(ts), f_begin(ts)), u => f_choose(FParsed, f_eq(f_tx(ts), "match"), u => f_locate(f_match_heads(f_tl(ts), f_col(ts), Nil{}), f_begin(ts), False{}, True{}, False{}), u => f_statement(f_expr(ts, 0), f_begin(ts))))

@unsafe
def f_statement(p, begin):
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, f_eq(f_tx(ts), "="), u => f_let_value(n, f_expr(f_tl(ts), 0)), u => f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_typed_let_try(n, ts, f_expr(f_tl(ts), 0), begin), u => f_statement_more(FParsed{n, ts})))

@unsafe
def f_let_ann(
  +ty: KTerm,
  +p: FParsed,
  +begin: U32,
) -> FParsed:
  match p:
    case FParsed{v, ts}:
      FParsed{kt_span("Ann", "", 0, 1, [v, ty], begin, f_begin(f_space(ts))), ts}

@unsafe
def f_let_value(pat, p):
  match p:
    case FParsed{v, ts}:
      f_choose(FParsed, f_eq(tg(v), "Error"), u => FParsed{v, ts}, u => f_let_body(pat, v, f_body(ts)))

@unsafe
def f_let_body(pat, v, p):
  match p:
    case FParsed{b, ts}:
      FParsed{f_choose(KTerm, f_eq(tg(b), "Error"), u => b, u => kt_span("Local", "", 0, 1, [pat, v, b], kb(pat), ke(pat))), ts}

@unsafe
def f_match_heads(ts, indent, acc):
  f_choose(FParsed, List.is_empty(&2, KTerm, acc) && (f_eq(f_tx(ts), ":") || f_eq(f_tx(ts), ",")), u => fpe_error(ts, "expected term", "a term"), u => f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_match_begin(f_skip(f_tl(ts)), indent, List.reverse(&2, KTerm, acc)), u => f_match_head(f_expr(f_choose(List<&2, FToken>, f_eq(f_tx(ts), ","), u => f_tl(ts), u => ts), 0), indent, acc)))

@unsafe
def f_match_head(p, indent, acc):
  match p:
    case FParsed{+n, ts}:
      f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_match_heads(ts, indent, Con{n, acc}))

@unsafe
def f_match_cases(
  +ts: List<&2, FToken>,
  +indent: U32,
  +heads: List<&2, KTerm>,
  +rows: List<&2, KTerm>,
) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), "case") && U32.is_gt(f_col(ts), indent), u => f_case_pats(f_tl(ts), indent, heads, rows, Nil{}, f_skip(f_tl(ts))), u => FParsed{kt("Match", "", 0, 1, Con{kt("Heads", "", 0, 1, heads), List.reverse(&2, KTerm, rows)}), ts})

@unsafe
def f_case_pats(ts, indent, heads, rows, pats, start):
  f_choose(FParsed, List.is_empty(&2, KTerm, pats) && (f_eq(f_tx(ts), ":") || f_eq(f_tx(ts), ",")), u => fpe_error(ts, "expected term", "a term"), u => f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_choose(FParsed, U32.is_eq(terms_len(pats), terms_len(heads)), u => f_case_body(f_body_context(f_tl(ts), U32.add(indent, 1)), indent, heads, rows, List.reverse(&2, KTerm, pats)), u => fpe_span(start, ts, "one pattern is required per match scrutinee", U32.show(terms_len(heads)) ++ " patterns (one per scrutinee)", "")), u => f_case_pat(f_expr(f_choose(List<&2, FToken>, f_eq(f_tx(ts), ","), u => f_tl(ts), u => ts), 0), indent, heads, rows, pats, start)))

@unsafe
def f_case_pat(p, indent, heads, rows, pats, start):
  match p:
    case FParsed{+n, ts}:
      f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_case_pats(ts, indent, heads, rows, Con{n, pats}, start))

@unsafe
def f_case_body(p, indent, heads, rows, pats):
  match p:
    case FParsed{+n, ts}:
      f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_match_cases(f_skip(ts), indent, heads, Con{kt("Row", "", 0, 1, [kt("Patterns", "", 0, 1, pats), n]), rows}))


@unsafe
def f_put(d, book):
  Con{d, book}

@unsafe
def f_type_named(
  +name: String,
  +ts: List<&2, FToken>,
  +book: List<&2, KDef>,
  +imports: List<&2, KTerm>, +scope: FParseScope
) -> FRawResult:
  f_choose(FRawResult, f_eq(f_tx(ts), "<>"), u => f_type_params(name, FParsed{kt("Tele", "", 0, 0, Nil{}), f_tl(ts)}, book, imports, scope), u => f_type_base(name, ts, book, imports, scope))

@unsafe
def f_def_header_prior(+nameTokens: List<&2,FToken>, +rest: List<&2,FToken>, +book: List<&2,KDef>, +imports: List<&2,KTerm>, +unsafe: Bool, +old: KDef, +scope: FParseScope) -> FRawResult:
  f_choose(FRawResult, f_eq(dk(old), "Missing") || f_def_fillable(old),
    u => f_choose(FRawResult, f_eq(f_tx(rest), "("),
      u => f_choose(FRawResult, f_def_fillable(old) && f_eq(f_tx(f_skip(f_tl(rest))), "~"),
        u => f_result(book, f_pn(fpe_name_error(f_skip(f_tl(rest)))), imports),
        u => f_def_prior(f_tx(nameTokens), f_tele(f_tl(rest), ")", Nil{}), book, imports, unsafe, old, nameTokens, scope)),
      u => f_result(book, f_pn(fpe_error(rest, "expected (", "'('")), imports)),
    u => f_result(book, f_pn(fpe_word(nameTokens, "a definition must uniquely fill its law with plain parameter names", "a fresh name (duplicate declaration: " ++ f_tx(nameTokens) ++ ")")), imports))

@unsafe
def f_def_fillable(+old: KDef) -> Bool:
  f_eq(dk(old), "Def") && f_eq(tg(dv(old)), "Absent") && Bool.not(db(old))

law f_body_context:
  for +ts: List<&2, FToken>
  for +outer: U32
  FParsed

law f_body_context_at:
  for +ts: List<&2, FToken>
  for +outer: U32
  FParsed

law f_match_begin:
  for +ts: List<&2, FToken>
  for +outer: U32
  for +heads: List<&2, KTerm>
  FParsed

@unsafe
def f_body_context(ts, outer):
  f_body_context_at(f_skip(ts), outer)

@unsafe
def f_body_context_at(ts, outer):
  f_choose(FParsed, f_eq(f_tx(ts), "match"), u => f_locate(f_match_heads(f_tl(ts), outer, Nil{}), f_begin(ts), False{}, True{}, False{}), u => f_body_at(ts))

@unsafe
def f_match_begin(ts, outer, heads):
  f_choose(FParsed, f_eq(f_tx(ts), "case") && U32.is_gt(f_col(ts), outer), u => f_match_cases(ts, U32.sub(f_col(ts), 1), heads, Nil{}), u => FParsed{kt("Match", "", 0, 1, [kt("Heads", "", 0, 1, heads)]), ts})

law f_law_arity:
  for +clauses: List<&2, KTerm>
  U32

@unsafe
def f_law_arity(clauses):
  match clauses:
    case Nil{}:
      0
    case Con{c, rest}:
      f_choose(U32, f_eq(tg(c), "Exists"), u => 0, u => U32.add(1, f_law_arity(rest)))

@unsafe
def f_law(name, ts, book, imports, clauses, scope):
  f_choose(FRawResult, f_valid_name(name) && f_eq(dk(f_find(name, book)), "Missing"), u => f_law_base(name, ts, book, imports, clauses, scope), u => f_result(book, kt("Error", "invalid or reserved law name: " ++ name, 0, 0, Nil{}), imports))

@unsafe
def f_type(name, ts, book, imports, scope):
  f_choose(FRawResult, f_valid_name(name) && f_eq(dk(f_find(name, book)), "Missing"), u => f_type_named(name, ts, book, imports, scope), u => f_result(book, kt("Error", "invalid or reserved datatype name: " ++ name, 0, 0, Nil{}), imports))

# The wrong-extension cursor follows the closing quote; keep that case legacy.
law fpe_foreign:
  for +ts: List<&2,FToken>
  KTerm

@unsafe
def fpe_foreign(ts):
  f_choose(KTerm, Char.is_eq(f_head(f_tx(ts)), '"'), u => kt("Error", "foreign import requires a quoted .c or .js path", 0, 0, Nil{}), u => f_pn(fpe_legacy(ts, "foreign import requires a quoted .c or .js path", "'\"'")))

@unsafe
def f_named_top(+ts: List<&2,FToken>, +book: List<&2,KDef>, +imports: List<&2,KTerm>, +datatype: Bool, +scope: FParseScope) -> FRawResult:
  f_choose(FRawResult, Bool.not(f_valid_name(f_tx(ts))), u => f_result(book, f_pn(fpe_name_error(ts)), imports),
    u => f_choose(FRawResult, Bool.not(f_eq(f_alias(f_tx(ts), imports), f_tx(ts))), u => f_result(book, f_pn(fpe_word(ts, "an import alias cannot name a new declaration", "a fresh name (" ++ f_import_alias_head(f_tx(ts)) ++ " is an import's alias)")), imports),
    u => f_choose(FRawResult, f_decl_taken(f_tx(ts), book, scope), u => f_result(book, f_pn(fpe_word(ts, "duplicate declaration", "a fresh name (duplicate declaration: " ++ f_tx(ts) ++ ")")), imports),
      u => f_choose(FRawResult, datatype, u => f_type(f_tx(ts), f_tl(ts), book, imports, scope), u => f_law_header(f_tx(ts), f_expect(FParsed{atom("Absent"), f_space(f_tl(ts))}, ":"), book, imports, scope)))))

@unsafe
def f_law_header(+name: String, +p: FParsed, +book: List<&2,KDef>, +imports: List<&2,KTerm>, +scope: FParseScope) -> FRawResult:
  match p:
    case FParsed{n, ts}: f_choose(FRawResult, f_eq(tg(n), "Error"), u => f_result(book, n, imports), u => f_law(name, f_skip(ts), book, imports, Nil{}, scope))

@unsafe
def f_parse_indexed(+start: U32, +source: String) -> FResult:
  fpe_finish_indexed(start, source, f_tops(f_lex_indexed(start, source), Nil{}, Nil{}, False{}, f_parse_scope_empty()))

# A module body sees completed dependencies; legacy parsers supply an empty scope.
type FParseScope is Data:
  FParseScope{+prior: List<&2,KDef>, +index: KDef, +ns: String, +aliases: List<&2,KTerm>, +enabled: Bool}

@unsafe
def f_parse_scope_empty() -> FParseScope:
  FParseScope{Nil{}, missing(), "", Nil{}, False{}}

@unsafe
def f_decl_prior(+name: String, +scope: FParseScope) -> KDef:
  match scope:
    case FParseScope{prior, index, ns, aliases, enabled}:
      +alias = f_alias(name, aliases)
      +own = f_choose(String, f_eq(alias, name), u => f_qual_name(name, ns), u => alias)
      +near = index_find(index, own, index_hash(own, 2166136261), 32)
      +far = index_find(index, name, index_hash(name, 2166136261), 32)
      +found = f_choose(KDef, Bool.not(f_eq(dk(near), "Absent")) || f_eq(dk(far), "Absent"), u => near,
        u => f_choose(KDef, Bool.not(f_eq(dk(f_ctor_lookup(own, prior)), "Missing")), u => missing(), u => far))
      f_choose(KDef, f_eq(dk(found), "Absent"), u => f_find(name, Nil{}), u => found)

@unsafe
def f_decl_find(+name: String, +book: List<&2,KDef>, +scope: FParseScope) -> KDef:
  +local = f_find(name, book)
  f_choose(KDef, f_eq(dk(local), "Missing"), u => f_decl_local_ctor(name, book, scope, f_decl_prior(name, scope)), u => local)

@unsafe
def f_decl_taken(+name: String, +book: List<&2,KDef>, +scope: FParseScope) -> Bool:
  match scope:
    case FParseScope{prior, index, ns, aliases, enabled}:
      Bool.not(f_eq(dk(f_find(name, book)), "Missing")) || Bool.not(f_eq(dk(index_find(index, name, index_hash(name, 2166136261), 32)), "Absent")) || Bool.not(f_eq(dk(index_find(index, f_qual_name(name, ns), index_hash(f_qual_name(name, ns), 2166136261), 32)), "Absent"))

@unsafe
def f_decl_ctor_taken(+name: String, +book: List<&2,KDef>, +scope: FParseScope) -> Bool:
  match scope:
    case FParseScope{prior, index, ns, aliases, enabled}:
      Bool.not(f_eq(dk(f_ctor_lookup(name, book)), "Missing")) || Bool.not(f_eq(dk(f_ctor_lookup(name, prior)), "Missing")) || Bool.not(f_eq(dk(f_ctor_lookup(f_qual_name(name, ns), prior)), "Missing"))

@unsafe
def f_def_context_header(+ts: List<&2,FToken>, +rest: List<&2,FToken>, +book: List<&2,KDef>, +imports: List<&2,KTerm>, +unsafe: Bool, +old: KDef, +scope: FParseScope) -> FRawResult:
  match scope:
    case FParseScope{prior, index, ns, aliases, enabled}:
      +name = f_tx(ts)
      +alias = f_alias(name, aliases)
      f_choose(FRawResult, enabled && Bool.not(f_eq(alias, name)) && f_declared(alias, prior) && f_declared(name, prior),
        u => f_result(book, fpe_point_at(kt_span("Ref", name, 0, 1, Nil{}, f_end(ts), f_end(ts)), "ambiguous imported declaration", "an unambiguous name (the alias " ++ f_import_alias_head(name) ++ " shadows " ++ name ++ ")"), imports),
        u => f_choose(FRawResult, enabled && Bool.not(f_def_fillable(old)) && Bool.not(f_eq(alias, name)),
          u => f_result(book, f_pn(fpe_word(ts, "an import alias cannot name a new declaration", "a fresh name (" ++ f_import_alias_head(name) ++ " is an import's alias)")), imports),
          u => f_choose(FRawResult, enabled && Bool.not(f_def_fillable(old)) && f_decl_taken(name, book, scope),
            u => f_result(book, f_pn(fpe_word(ts, "duplicate declaration", "a fresh name (duplicate declaration: " ++ name ++ ")")), imports),
            u => f_def_header_prior(ts, rest, book, imports, unsafe, old, scope))))

# A constructor in this module wins resolution over a far fillable law.
# Missing ordinary definitions do not pay for a local constructor scan.
@unsafe
def f_decl_local_ctor(+name: String, +book: List<&2,KDef>, +scope: FParseScope, +old: KDef) -> KDef:
  match scope:
    case FParseScope{prior, index, ns, aliases, enabled}:
      f_choose(KDef, f_def_fillable(old),
        u => f_choose(KDef, f_eq(f_alias(name, aliases), name) && Bool.not(f_eq(dk(f_ctor_lookup(name, book)), "Missing")), u => f_find(name, Nil{}), u => old),
        u => old)
