# Declarations retain laws, telescopes, constructor fields and foreign paths.
type FResult is Data:
  FResult{+book: List<&2, KDef>, +error: String, +imports: List<&2, KTerm>}

# Internal parser transport only; public FResult remains unchanged.
type FRawResult is Data:
  FRawResult{+book: List<&2, KDef>, +error: KTerm, +imports: List<&2, KTerm>}

law f_parse:
  for +source: String
  FResult

law f_result:
  for +book: List<&2, KDef>
  for +err: KTerm
  for +imports: List<&2, KTerm>
  FRawResult

law f_len:
  for +xs: List<&2, KTerm>
  U32

law f_find:
  for +name: String
  for +book: List<&2, KDef>
  KDef

law f_dn:
  for +d: KDef
  String

law f_dt:
  for +d: KDef
  KTerm

law f_dk:
  for +d: KDef
  String

law f_dx:
  for +d: KDef
  U32

law f_put:
  for +d: KDef
  for +book: List<&2, KDef>
  List<&2, KDef>

law f_tops:
  for +ts0: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
  FRawResult

law f_top:
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
  FRawResult

law f_top_ready:
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
  FRawResult

law f_import:
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
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

law f_tele_binder:
  for +name: String
  for +id: U32
  for +q: U32
  for +temp: Bool
  for +ts: List<&2, FToken>
  for +end: String
  for +acc: List<&2, KTerm>
  FParsed

law f_tele_type:
  for +name: String
  for +id: U32
  for +q: U32
  for +temp: Bool
  for +p: FParsed
  for +end: String
  for +acc: List<&2, KTerm>
  FParsed

law f_tbind:
  for +pars: List<&2, KTerm>
  for +result: KTerm
  KTerm

law f_lbind:
  for +pars: List<&2, KTerm>
  for +body: KTerm
  KTerm

law f_templates:
  for +pars: List<&2, KTerm>
  U32

law f_def:
  for +name: String
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
  FRawResult

law f_def_type:
  for +name: String
  for +pars: List<&2, KTerm>
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
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
  FRawResult

law f_law:
  for +name: String
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +clauses: List<&2, KTerm>
  FRawResult

law f_law_clause:
  for +name: String
  for +exi: Bool
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +clauses: List<&2, KTerm>
  FRawResult

law f_law_type:
  for +name: String
  for +binder: KTerm
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +clauses: List<&2, KTerm>
  FRawResult

law f_law_bind:
  for +clauses: List<&2, KTerm>
  for +ty: KTerm
  KTerm

law f_law_end:
  for +name: String
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +clauses: List<&2, KTerm>
  FRawResult

law f_type:
  for +name: String
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  FRawResult

law f_type_params:
  for +name: String
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  FRawResult

law f_type_kind:
  for +name: String
  for +pars: List<&2, KTerm>
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  FRawResult

law f_type_ctors:
  for +name: String
  for +pars: List<&2, KTerm>
  for +ty: KTerm
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +ctors: List<&2, KDef>
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
  FRawResult

law f_param_refs:
  for +pars: List<&2, KTerm>
  List<&2, KTerm>

law f_body:
  for +ts: List<&2, FToken>
  FParsed

law f_body_at:
  for +ts: List<&2, FToken>
  FParsed

law f_statement:
  for +p: FParsed
  FParsed

law f_let_ann:
  for +ty: KTerm
  for +p: FParsed
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

law f_match_cases:
  for +ts: List<&2, FToken>
  for +indent: U32
  for +heads: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  FParsed

law f_case_pats:
  for +ts: List<&2, FToken>
  for +indent: U32
  for +heads: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +pats: List<&2, KTerm>
  FParsed

law f_case_pat:
  for +p: FParsed
  for +indent: U32
  for +heads: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +pats: List<&2, KTerm>
  FParsed

law f_case_body:
  for +p: FParsed
  for +indent: U32
  for +heads: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +pats: List<&2, KTerm>
  FParsed

@unsafe
def f_parse(source):
  fpe_finish(source, f_tops(f_lex(source, 1, 0, 0, Nil{}), Nil{}, Nil{}, False{}))

@unsafe
def f_result(book, err, imports):
  FRawResult{List.reverse(&2, KDef, book), err, List.reverse(&2, KTerm, imports)}

@unsafe
def f_len(xs):
  match xs:
    case Nil{}:
      0
    case Con{x, xt}:
      U32.add(1, f_len(xt))

@unsafe
def f_find(name, book):
  match book:
    case Nil{}:
      KDef{name, "Missing", 0, 0, atom("Absent"), atom("Absent"), Nil{}, False{}, False{}}
    case Con{+d, ds}:
      f_choose(KDef, f_eq(name, f_dn(d)), u => d, u => f_find(name, ds))

@unsafe
def f_dn(d):
  match d:
    case KDef{name, kind, arity, templates, typ, value, ctors, native, unsafe}:
      name

@unsafe
def f_dt(d):
  match d:
    case KDef{name, kind, arity, templates, typ, value, ctors, native, unsafe}:
      typ

@unsafe
def f_dk(d):
  match d:
    case KDef{name, kind, arity, templates, typ, value, ctors, native, unsafe}:
      kind

@unsafe
def f_dx(d):
  match d:
    case KDef{name, kind, arity, templates, typ, value, ctors, native, unsafe}:
      templates

@unsafe
def f_tops(ts0, book, imports, unsafe):
  f_top(f_skip(ts0), book, imports, unsafe)

@unsafe
def f_top(ts, book, imports, unsafe):
  f_choose(FRawResult, unsafe,
    u => f_choose(FRawResult, f_eq(f_tx(ts), "def"), u => f_top_ready(ts, book, imports, unsafe), u => f_result(book, f_pn(f_err(ts, "expected def after @unsafe")), imports)),
    u => f_top_ready(ts, book, imports, unsafe))

@unsafe
def f_top_ready(ts, book, imports, unsafe):
  f_choose(FRawResult, f_eq(f_tx(ts), "<eof>"), u => f_result(book, atom("Absent"), imports),
    u => f_choose(FRawResult, f_eq(f_tx(ts), "@") && f_eq(f_tx(f_tl(ts)), "unsafe"), u => f_tops(f_tl(f_tl(ts)), book, imports, True{}),
    u => f_choose(FRawResult, f_eq(f_tx(ts), "import"), u => f_import_leading(ts, book, imports, unsafe),
    u => f_choose(FRawResult, f_eq(f_tx(ts), "law"), u => f_law(f_tx(f_tl(ts)), f_skip(f_tl(f_tl(f_tl(ts)))), book, imports, Nil{}),
    u => f_choose(FRawResult, f_eq(f_tx(ts), "def"), u => f_def(f_tx(f_tl(ts)), f_tele(f_tl(f_tl(f_tl(ts))), ")", Nil{}), book, imports, unsafe),
    u => f_choose(FRawResult, f_eq(f_tx(ts), "type"), u => f_type(f_tx(f_tl(ts)), f_tl(f_tl(ts)), book, imports),
    u => f_result(book, f_pn(f_choose(FParsed, f_eq(f_tx(ts), "@"), u => f_err(ts, "expected def, law, type or import"), u => fpe_error(ts, "expected def, law, type or import", "'def', 'type' or 'law'"))), imports)))))))

@unsafe
def f_import(ts, book, imports):
  f_import_path(ts, "", book, imports)

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
      f_choose(FRawResult, unsafe, u => f_result(book, f_pn(f_err(ts, "expected def after @unsafe")), imports), u => f_import(f_tl(ts), book, imports))
    case Con{d, rest}:
      f_result(book, f_pn(fpe_error(ts, "expected def, law or type; imports must precede declarations", "'def', 'type' or 'law'")), imports)

@unsafe
def f_tele(ts0, end, acc):
  f_tele_at(f_skip(ts0), end, acc)

@unsafe
def f_tele_at(ts, end, acc):
  f_choose(FParsed, f_eq(f_tx(ts), end), u => FParsed{kt("Tele", "", 0, 0, List.reverse(&2, KTerm, acc)), f_tl(ts)}, u => f_validate_param(ts, end, acc))

@unsafe
def f_tele_binder(name, id, q, temp, ts, end, acc):
  f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_tele_type(name, id, q, temp, f_expr(f_tl(ts), 0), end, acc), u => f_choose(FParsed, U32.is_eq(q, 1) && Bool.not(temp), u => f_tele_type(name, id, 0, temp, FParsed{atom("Qnt"), ts}, end, acc), u => f_err(ts, "expected : (a marked parameter requires its type)")))

@unsafe
def f_tele_type(name, id, q, temp, p, end, acc):
  match p:
    case FParsed{+ty, +ts}:
      f_choose(FParsed, f_eq(tg(ty), "Error"), u => FParsed{ty, ts}, u => f_tele(f_choose(List<&2, FToken>, f_eq(f_tx(ts), ","), u => f_tl(ts), u => ts), end, Con{kt(f_choose(String, temp, u => "Template", u => "Bind"), name, id, q, [ty]), acc}))

@unsafe
def f_tbind(pars, result):
  match pars:
    case Nil{}:
      result
    case Con{+p, ps}:
      kt("All", nm(p), ix(p), qt(p), [kid(p, 0), f_tbind(ps, result)])

@unsafe
def f_lbind(pars, body):
  match pars:
    case Nil{}:
      body
    case Con{+p, ps}:
      kt("Lam", nm(p), ix(p), qt(p), [f_lbind(ps, body)])

@unsafe
def f_templates(pars):
  match pars:
    case Nil{}:
      0
    case Con{p, ps}:
      U32.add(f_choose(U32, f_eq(tg(p), "Template"), u => 1, u => 0), f_templates(ps))

@unsafe
def f_def_base(name, p, book, imports, unsafe):
  match p:
    case FParsed{+pars, +ts}:
      f_choose(FRawResult, f_eq(tg(pars), "Error"), u => f_result(book, pars, imports), u => f_choose(FRawResult, f_eq(f_tx(ts), "->"), u => f_def_type(name, ks(pars), f_expr(f_tl(ts), 0), book, imports, unsafe), u => f_def_type(name, ks(pars), FParsed{f_dt(f_find(name, book)), ts}, book, imports, unsafe)))

@unsafe
def f_def_type(name, pars, p, book, imports, unsafe):
  match p:
    case FParsed{+ty, +ts}:
      f_choose(FRawResult, f_eq(tg(ty), "Absent"), u => f_result(book, kt("Error", "definition without return type needs a law: " ++ name, 0, 0, Nil{}), imports), u => f_choose(FRawResult, f_eq(f_tx(f_skip(f_tl(ts))), "import"), u => f_foreign(name, pars, f_def_signature(name, pars, ty, book), f_skip(f_tl(ts)), book, imports, unsafe, Nil{}), u => f_def_body(name, pars, f_def_signature(name, pars, ty, book), f_body(f_pr(f_expect(FParsed{ty, ts}, ":"))), book, imports, unsafe)))

@unsafe
def f_def_signature(name, pars, ty, book):
  f_choose(KTerm, f_eq(f_dk(f_find(name, book)), "Missing"), u => f_tbind(pars, ty), u => ty)

@unsafe
def f_def_body(name, pars, ty, p, book, imports, unsafe):
  match p:
    case FParsed{+body, ts}:
      f_choose(FRawResult, f_eq(tg(body), "Error"), u => f_result(book, body, imports), u => f_tops(ts, f_put(KDef{name, "Def", f_len(pars), f_choose(U32, f_eq(f_dk(f_find(name, book)), "Missing"), u => f_templates(pars), u => f_dx(f_find(name, book))), ty, kt("Body", "", fc_start(pars, ty, body, Bool.not(f_eq(f_dk(f_find(name, book)), "Missing"))), 0, [kt("Params", "", 0, 0, pars), body]), Nil{}, False{}, unsafe}, book), imports, False{}))

@unsafe
def f_foreign(name, pars, ty, ts, book, imports, unsafe, paths):
  f_choose(FRawResult, f_eq(f_tx(ts), "import"), u => f_choose(FRawResult, f_foreign_path_valid(ts), u => f_foreign(name, pars, ty, f_skip(f_tl(f_tl(ts))), book, imports, unsafe, Con{kt("Path", f_unquote(f_tx(f_tl(ts))), 0, 0, Nil{}), paths}), u => f_result(book, fpe_foreign(f_space(f_tl(ts))), imports)), u => f_tops(ts, f_put(KDef{name, "Def", f_len(pars), 0, ty, kt("Foreign", name, 0, 0, List.reverse(&2, KTerm, paths)), Nil{}, False{}, unsafe}, book), imports, False{}))

@unsafe
def f_law_base(name, ts, book, imports, clauses):
  f_choose(FRawResult, f_eq(f_tx(ts), "for") || f_eq(f_tx(ts), "exs"), u => f_law_clause(name, f_eq(f_tx(ts), "exs"), f_tl(ts), book, imports, clauses), u => f_law_end(name, f_expr(ts, 0), book, imports, List.reverse(&2, KTerm, clauses)))

@unsafe
def f_law_clause(name, exi, ts, book, imports, clauses):
  f_choose(FRawResult, Bool.not(exi) && f_eq(f_tx(ts), "~") && U32.is_lt(f_templates(clauses), f_len(clauses)),
    u => f_result(book, f_pn(fpe_error(ts, "expected a plain clause (only leading clauses take ~)", "a plain clause (only leading clauses take ~)")), imports),
    u => f_law_type(name, kt(f_choose(String, exi, u => "Exists", u => f_choose(String, f_eq(f_tx(ts), "~"), u => "Template", u => "Bind")), f_tx(f_unmark(ts)), f_atid(ts), f_quant(ts), Nil{}), f_expr(f_tl(f_tl(f_unmark(ts))), 0), book, imports, clauses))

@unsafe
def f_law_type(name, binder, p, book, imports, clauses):
  match p:
    case FParsed{+ty, ts}:
      f_choose(FRawResult, f_eq(tg(ty), "Error"), u => f_result(book, ty, imports), u => f_choose(FRawResult, f_eq(f_tx(f_skip(ts)), "where"), u => f_law_where(name, binder, ty, f_expr(f_tl(f_skip(ts)), 0), book, imports, clauses), u => f_law(name, f_skip(ts), book, imports, Con{kt(tg(binder), nm(binder), ix(binder), qt(binder), [ty]), clauses})))

@unsafe
def f_law_bind(clauses, ty):
  match clauses:
    case Nil{}:
      ty
    case Con{+c, cs}:
      f_choose(KTerm, f_eq(tg(c), "Exists"), u => f_app(kt("Ref", "Exists", 0, 1, Nil{}), [kid(c, 0), kt("Lam", nm(c), ix(c), 1, [f_law_bind(cs, ty)])]), u => kt("All", nm(c), ix(c), qt(c), [kid(c, 0), f_law_bind(cs, ty)]))

@unsafe
def f_law_end(name, p, book, imports, clauses):
  match p:
    case FParsed{+ty, ts}:
      f_choose(FRawResult, f_eq(tg(ty), "Error"), u => f_result(book, ty, imports), u => f_tops(ts, Con{KDef{name, "Def", f_law_arity(clauses), f_templates(clauses), f_law_bind(clauses, ty), atom("Absent"), Nil{}, False{}, False{}}, book}, imports, False{}))

@unsafe
def f_type_base(name, ts, book, imports):
  f_choose(FRawResult, f_eq(f_tx(ts), "<") || f_eq(f_tx(ts), "<-"), u => f_type_params(name, f_tele(f_choose(List<&2, FToken>, f_eq(f_tx(ts), "<-"), u => Con{FToken{"-", f_line(ts), U32.add(f_col(ts), 1), 0}, f_tl(ts)}, u => f_tl(ts)), ">", Nil{}), book, imports), u => f_type_params(name, FParsed{kt("Tele", "", 0, 0, Nil{}), ts}, book, imports))

@unsafe
def f_type_params(name, p, book, imports):
  match p:
    case FParsed{pars, ts}:
      f_choose(FRawResult, f_eq(tg(pars), "Error"), u => f_result(book, pars, imports), u => f_type_kind(name, ks(pars), f_expect(f_expr(f_pr(f_expect(FParsed{pars, ts}, "is")), 0), ":"), book, imports))

@unsafe
def f_type_kind(name, pars, p, book, imports):
  match p:
    case FParsed{ty, ts}:
      f_choose(FRawResult, f_eq(tg(ty), "Error"), u => f_result(book, ty, imports), u => f_type_ctors(name, pars, ty, f_skip(ts), book, imports, Nil{}))

@unsafe
def f_type_ctors(name, pars, ty, ts, book, imports, ctors):
  f_choose(FRawResult, U32.is_gt(f_col(ts), 0) && f_eq(f_tx(f_tl(ts)), "{"), u => f_choose(FRawResult, Bool.not(f_eq(dk(f_find(f_tx(ts), ctors)), "Missing")) || Bool.not(f_eq(dk(f_ctor_lookup(f_tx(ts), book)), "Missing")), u => f_result(book, f_pn(fpe_fresh(ts, "expected a fresh constructor name (duplicate declaration: " ++ f_tx(ts) ++ ")", "a fresh constructor name (duplicate declaration: " ++ f_tx(ts) ++ ")")), imports), u => f_type_ctor(name, pars, ty, f_tx(ts), f_tele(f_tl(f_tl(ts)), "}", Nil{}), book, imports, ctors)), u => f_tops(ts, Con{KDef{name, "ADT", f_len(pars), 0, f_tbind(pars, ty), atom("Absent"), List.reverse(&2, KDef, ctors), False{}, False{}}, book}, imports, False{}))

@unsafe
def f_type_ctor(name, pars, ty, ctor, p, book, imports, ctors):
  match p:
    case FParsed{fields, ts}:
      f_choose(FRawResult, f_eq(tg(fields), "Error"), u => f_result(book, fields, imports), u => f_type_ctors(name, pars, ty, f_skip(ts), book, imports, Con{KDef{ctor, "Ctr", f_len(ks(fields)), 0, f_tbind(pars, f_tbind(ks(fields), kt("ADT", name, 0, 1, f_param_refs(pars)))), kt("Absent", ctor, 0, 0, Nil{}), Nil{}, False{}, False{}}, ctors}))

@unsafe
def f_param_refs(pars):
  match pars:
    case Nil{}:
      Nil{}
    case Con{+p, ps}:
      Con{kt("Ref", nm(p), ix(p), qt(p), Nil{}), f_param_refs(ps)}

@unsafe
def f_body(ts):
  f_body_context(ts, 0)

@unsafe
def f_body_at(ts):
  f_choose(FParsed, f_eq(f_tx(ts), "-"), u => f_erased_local(f_tl(ts)), u => f_choose(FParsed, f_eq(f_tx(ts), "match"), u => f_match_heads(f_tl(ts), f_col(ts), Nil{}), u => f_statement(f_expr(ts, 0))))

@unsafe
def f_statement(p):
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, f_eq(f_tx(ts), "="), u => f_let_value(n, f_expr(f_tl(ts), 0)), u => f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_typed_let_try(n, ts, f_expr(f_tl(ts), 0)), u => f_statement_more(FParsed{n, ts})))

@unsafe
def f_let_ann(ty, p):
  match p:
    case FParsed{v, ts}:
      FParsed{kt("Ann", "", 0, 1, [v, ty]), ts}

@unsafe
def f_let_value(pat, p):
  match p:
    case FParsed{v, ts}:
      f_let_body(pat, v, f_body(ts))

@unsafe
def f_let_body(pat, v, p):
  match p:
    case FParsed{b, ts}:
      FParsed{kt("Local", "", 0, 1, [pat, v, b]), ts}

@unsafe
def f_match_heads(ts, indent, acc):
  f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_match_begin(f_skip(f_tl(ts)), indent, List.reverse(&2, KTerm, acc)), u => f_match_head(f_expr(f_choose(List<&2, FToken>, f_eq(f_tx(ts), ","), u => f_tl(ts), u => ts), 0), indent, acc))

@unsafe
def f_match_head(p, indent, acc):
  match p:
    case FParsed{+n, ts}:
      f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_match_heads(ts, indent, Con{n, acc}))

@unsafe
def f_match_cases(ts, indent, heads, rows):
  f_choose(FParsed, f_eq(f_tx(ts), "case") && U32.is_gt(f_col(ts), indent), u => f_case_pats(f_tl(ts), indent, heads, rows, Nil{}), u => FParsed{kt("Match", "", 0, 1, Con{kt("Heads", "", 0, 1, heads), List.reverse(&2, KTerm, rows)}), ts})

@unsafe
def f_case_pats(ts, indent, heads, rows, pats):
  f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_case_body(f_body_context(f_tl(ts), U32.add(indent, 1)), indent, heads, rows, List.reverse(&2, KTerm, pats)), u => f_case_pat(f_expr(f_choose(List<&2, FToken>, f_eq(f_tx(ts), ","), u => f_tl(ts), u => ts), 0), indent, heads, rows, pats))

@unsafe
def f_case_pat(p, indent, heads, rows, pats):
  match p:
    case FParsed{+n, ts}:
      f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_case_pats(ts, indent, heads, rows, Con{n, pats}))

@unsafe
def f_case_body(p, indent, heads, rows, pats):
  f_case_checked(p, indent, heads, rows, pats)


@unsafe
def f_put(d, book):
  Con{d, book}

law f_type_base:
  for +name: String
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  FRawResult

@unsafe
def f_type_named(name, ts, book, imports):
  f_choose(FRawResult, f_eq(f_tx(ts), "<>"), u => f_type_params(name, FParsed{kt("Tele", "", 0, 0, Nil{}), f_tl(ts)}, book, imports), u => f_type_base(name, ts, book, imports))

law f_def_base:
  for +name: String
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
  FRawResult

@unsafe
def f_def(name, p, book, imports, unsafe):
  f_choose(FRawResult, Bool.not(f_valid_name(name)), u => f_result(book, kt("Error", "reserved definition name: " ++ name, 0, 0, Nil{}), imports), u => f_def_prior(name, p, book, imports, unsafe, f_find(name, book)))

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
  f_choose(FParsed, f_eq(f_tx(ts), "match"), u => f_match_heads(f_tl(ts), outer, Nil{}), u => f_body_at(ts))

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

law f_law_base:
  for +name: String
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +clauses: List<&2, KTerm>
  FRawResult

law f_type_named:
  for +name: String
  for +ts: List<&2, FToken>
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  FRawResult

@unsafe
def f_law(name, ts, book, imports, clauses):
  f_choose(FRawResult, f_valid_name(name) && f_eq(dk(f_find(name, book)), "Missing"), u => f_law_base(name, ts, book, imports, clauses), u => f_result(book, kt("Error", "invalid or reserved law name: " ++ name, 0, 0, Nil{}), imports))

@unsafe
def f_type(name, ts, book, imports):
  f_choose(FRawResult, f_valid_name(name) && f_eq(dk(f_find(name, book)), "Missing"), u => f_type_named(name, ts, book, imports), u => f_result(book, kt("Error", "invalid or reserved datatype name: " ++ name, 0, 0, Nil{}), imports))

# The wrong-extension cursor follows the closing quote; keep that case legacy.
law fpe_foreign:
  for +ts: List<&2,FToken>
  KTerm

@unsafe
def fpe_foreign(ts):
  f_choose(KTerm, Char.is_eq(f_head(f_tx(ts)), '"'), u => kt("Error", "foreign import requires a quoted .c or .js path", 0, 0, Nil{}), u => f_pn(fpe_legacy(ts, "foreign import requires a quoted .c or .js path", "'\"'")))
