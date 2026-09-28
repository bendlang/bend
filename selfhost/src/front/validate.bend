# Pattern grammar and reserved binder checks precede core checking.

law f_reserved:
  for +s: String
  Bool

law f_ctor_lookup:
  for +name: String
  for +book: List<&2,KDef>
  KDef

law f_ctor_more:
  for +name: String
  for +found: KDef
  for +rest: List<&2,KDef>
  KDef

law f_valid_ctor_pattern:
  for +p: KTerm
  for +ctr: KDef
  for +book: List<&2,KDef>
  String

law f_valid_patterns:
  for +ps: List<&2, KTerm>
  for +book: List<&2,KDef>
  String

# Ordinary patterns and parallel binders share validation, with the latter
# restricted to names before the ordinary constructor-name check.
law f_valid_patterns_mode:
  for +ps: List<&2, KTerm>
  for +book: List<&2, KDef>
  for +names: Bool
  String

law f_valid_binding_pattern:
  for +p: KTerm
  for +book: List<&2, KDef>
  for +names: Bool
  String

law f_valid_patterns_mode_next:
  for +err: String
  for +ps: List<&2, KTerm>
  for +book: List<&2, KDef>
  for +names: Bool
  String

# Patterns open binders left-to-right. The body environment searches newest
# binders first; values and the original pattern lists retain source order.
law f_pattern_env:
  for +pats: List<&2, KTerm>
  for +env: List<&2, KTerm>
  List<&2, KTerm>

law f_scope_row_valid:
  for +r: KTerm
  for +pats: List<&2, KTerm>
  for +env: List<&2, KTerm>
  for +book: List<&2,KDef>
  for +err: String
  KTerm

law f_lambda_valid:
  for +a: KTerm
  for +body: KTerm
  KTerm

@unsafe
def f_reserved(s):
  f_eq(s, "def") || f_eq(s, "type") || f_eq(s, "law") || f_eq(s, "match") || f_eq(s, "case") || f_eq(s, "do") || f_eq(s, "return") || f_eq(s, "for") || f_eq(s, "exs") || f_eq(s, "where") || f_eq(s, "is") || f_eq(s, "import") || f_eq(s, "Type") || f_eq(s, "Data") || f_eq(s, "Kind") || f_eq(s, "Quant")

@unsafe
def f_ctor_lookup(name, book):
  match book:
    case Nil{}:
      f_find(name, Nil{})
    case Con{+d, ds}:
      f_choose(KDef, f_eq(dk(d), "Ctr") && f_eq(dn(d), name), u => d, u => f_ctor_more(name, f_ctor_lookup(name, dc(d)), ds))

@unsafe
def f_ctor_more(name, found, rest):
  f_choose(KDef, f_eq(dk(found), "Missing"), u => f_ctor_lookup(name, rest), u => found)

@unsafe
def f_valid_pattern(
  +p: KTerm,
  +book: List<&2,KDef>,
) -> String:
  f_choose(String, f_eq(tg(p), "Var"), u => f_choose(String, Bool.not(f_valid_name(nm(p))), u => "reserved pattern binder: " ++ nm(p), u => f_choose(String, f_eq(dk(f_ctor_lookup(nm(p), book)), "Missing"), u => "", u => "a constructor pattern requires braces: " ++ nm(p))), u => f_choose(String, f_eq(tg(p), "Ctr"), u => f_valid_ctor_pattern(p, f_ctor_lookup(nm(p), book), book), u => "expected a binder or constructor pattern"))

@unsafe
def f_valid_ctor_pattern(p, ctr, book):
  f_choose(String, f_eq(dk(ctr), "Missing"), u => "unknown constructor pattern: " ++ nm(p), u => f_choose(String, U32.is_eq(da(ctr), terms_len(ks(p))), u => f_valid_patterns(ks(p), book), u => "constructor pattern field count differs: " ++ nm(p)))

@unsafe
def f_valid_patterns(ps, book):
  f_valid_patterns_mode(ps, book, False{})

@unsafe
def f_valid_patterns_mode(ps, book, names):
  match ps:
    case Nil{}:
      ""
    case Con{p, rest}:
      f_valid_patterns_mode_next(f_valid_binding_pattern(p, book, names), rest, book, names)

@unsafe
def f_valid_binding_pattern(p, book, names):
  f_choose(String, names,
    u => f_choose(String, f_eq(tg(p), "Var"), u => f_valid_pattern(p, book), u => "a parallel let binds names; destructure in its body"),
    u => f_valid_pattern(p, book))

@unsafe
def f_valid_patterns_mode_next(err, ps, book, names):
  f_choose(String, String.is_empty(err), u => f_valid_patterns_mode(ps, book, names), u => err)

@unsafe
def f_pattern_env(pats, env):
  norm_join(List.reverse(&2, KTerm, f_penv(pats)), env)

@unsafe
def f_scope_row_valid(r, pats, env, book, err):
  f_choose(KTerm, String.is_empty(err), u => f_scoped_row(pats, f_scope_body(kid(r, 1), f_pattern_env(pats, env), book)), u => kt("Row", "", 0, 1, [kt("Patterns", "", 0, 1, pats), kt("Error", err, 0, 0, Nil{})]))

@unsafe
def f_lambda_valid(a, body):
  f_choose(KTerm, f_eq(tg(a), "Ref") && f_valid_name(nm(a)), u => kt("Lam", nm(a), ix(a), qt(a), [body]), u => kt("Error", "a lambda binder must be a non-reserved name", 0, 0, Nil{}))

law f_alias_valid:
  for +s: String
  Bool

law f_alias_chars:
  for +s: String
  Bool

law f_validate_param:
  for +ts: List<&2, FToken>
  for +end: String
  for +acc: List<&2, KTerm>
  FParsed

@unsafe
def f_alias_valid(s):
  (Char.is_alpha(f_head(s)) || Char.is_eq(f_head(s), '_')) && f_alias_chars(s) && Bool.not(f_reserved(s))

@unsafe
def f_alias_chars(s):
  f_choose(Bool, String.is_empty(s), u => True{}, u => (Char.is_alpha(f_head(s)) || Char.is_digit(f_head(s)) || Char.is_eq(f_head(s), '_')) && f_alias_chars(f_tail(s)))

@unsafe
def f_import_alias(
  +ts: List<&2, FToken>,
  +path: String,
  +book: List<&2,KDef>,
  +imports: List<&2, KTerm>,
) -> FRawResult:
  f_choose(FRawResult, String.ends_with(path, ".bend") && f_alias_valid(f_tx(f_tl(ts))), u => f_choose(FRawResult, f_import_used(f_tx(f_tl(ts)), imports), u => f_result(book, kt("Error", "expected a fresh alias (" ++ f_tx(f_tl(ts)) ++ " names an earlier import)", 0, 0, Nil{}), imports), u => f_tops(f_tl(f_tl(ts)), book, Con{kt("Import", path, 0, 0, [kt("Alias", f_tx(f_tl(ts)), 0, 0, Nil{})]), imports}, False{})), u => f_result(book, kt("Error", "an import requires a .bend path and a valid alias", 0, 0, Nil{}), imports))

@unsafe
def f_validate_param(ts, end, acc):
  f_choose(FParsed, f_eq(f_tx(ts), "~") && Bool.not(f_eq(end, ")")), u => f_err(ts, "~ is only allowed on def or law template parameters"), u => f_choose(FParsed, Bool.not(f_valid_name(f_tx(f_unmark(ts)))), u => f_err(ts, "reserved parameter name"), u => f_choose(FParsed, f_eq(end, "}") && f_named_field(f_tx(f_unmark(ts)), acc), u => fpe_error(f_unmark(ts), "duplicate constructor field", "a fresh field name (duplicate declaration: " ++ f_tx(f_unmark(ts)) ++ ")"), u => f_choose(FParsed, f_eq(f_tx(ts), "~") && U32.is_lt(f_templates(acc), terms_len(acc)), u => f_err(ts, "only leading parameters may use ~"), u => f_tele_binder(f_tx(f_unmark(ts)), f_atid(ts), f_quant(ts), f_eq(f_tx(ts), "~"), f_tl(f_unmark(ts)), end, acc)))))

@unsafe
def f_named_field(+name: String, +fields: List<&2,KTerm>) -> Bool:
  match fields:
    case Nil{}: False{}
    case Con{field, rest}: f_eq(name, nm(field)) || f_named_field(name, rest)


law f_valid_name:
  for +s: String
  Bool

law f_name_chars:
  for +s: String
  Bool

@unsafe
def f_valid_name(s):
  (f_ascii_alpha(f_head(s)) || Char.is_eq(f_head(s), '_')) && f_name_chars(s) && Bool.not(f_reserved(s))

@unsafe
def f_name_chars(s):
  f_choose(Bool, String.is_empty(s), u => True{}, u => f_ident(f_head(s)) && (Bool.not(Char.is_eq(f_head(s), '.')) || f_ascii_alpha(f_head(f_tail(s))) || Char.is_eq(f_head(f_tail(s)), '_')) && f_name_chars(f_tail(s)))

law f_def_prior:
  for +name: String
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
  for +old: KDef
  FRawResult

@unsafe
def f_bare_params(
  +params: List<&2, KTerm>,
) -> Bool:
  match params:
    case Nil{}:
      True{}
    case Con{+p, rest}:
      f_eq(tg(kid(p, 0)), "Qnt") && Bool.not(f_eq(tg(p), "Template")) && f_bare_params(rest)

@unsafe
def f_def_prior(name, p, book, imports, unsafe, old):
  f_choose(FRawResult, f_eq(dk(old), "Missing"), u => f_def_base(name, p, book, imports, unsafe), u => f_choose(FRawResult, f_eq(dk(old), "Def") && f_eq(tg(dv(old)), "Absent") && f_bare_params(ks(f_pn(p))) && U32.is_ge(terms_len(ks(f_pn(p))), dx(old)), u => f_choose(FRawResult, f_eq(f_tx(f_pr(p)), ":"), u => f_def_base(name, p, book, imports, unsafe), u => f_result(book, f_pn(f_err(f_pr(p), "expected : (a definition filling a law has no return annotation)")), imports)), u => f_result(book, kt("Error", "a definition must uniquely fill its law with plain parameter names", 0, 0, Nil{}), imports)))

law f_scope_local_valid:
  for +t: KTerm
  for +pats: List<&2, KTerm>
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  for +err: String
  KTerm

@unsafe
def f_scope_local_valid(t, pats, env, book, err):
  f_choose(KTerm, String.is_empty(err),
    u => kt("Local", "", 0, qt(t), [terms_at(pats, 0), f_scope(kid(t, 1), env, book), f_scope_body(kid(t, 2), f_pattern_env(pats, env), book)]),
    u => kt("Error", err, 0, 0, Nil{}))

law f_bang:
  for +n: KTerm
  for +ts: List<&2, FToken>
  for +min: U32
  FParsed

law f_foreign_path_valid:
  for +ts: List<&2, FToken>
  Bool

@unsafe
def f_bang(n, ts, min):
  f_choose(FParsed, f_eq(tg(n), "Ref") && f_eq(f_tx(f_tl(ts)), "("), u => f_grow(FParsed{kt("Ref", nm(n), ix(n), 3, ks(n)), f_tl(ts)}, min), u => f_err(ts, "! must follow a named definition and precede call parentheses"))

@unsafe
def f_foreign_path_valid(ts):
  U32.is_eq(f_kind(f_tl(ts)), 2) && Char.is_eq(f_head(f_tx(f_tl(ts))), '"') && (String.ends_with(f_unquote(f_tx(f_tl(ts))), ".c") || String.ends_with(f_unquote(f_tx(f_tl(ts))), ".js"))


# Row quantity is internal flattening metadata: zero proves the body contains
# no Var nodes, so every later column substitution is the identity. Open rows
# remain conservatively marked even if their remaining variables disappear.
law f_scoped_row:
  for +pats: List<&2,KTerm>
  for +body: KTerm
  KTerm

law f_contains_var:
  for +t: KTerm
  Bool

law f_contains_var_terms:
  for +ts: List<&2,KTerm>
  Bool

@unsafe
def f_scoped_row(pats, body):
  kt("Row", "", 0, f_choose(U32, f_contains_var(body), u => 1, u => 0), [kt("Patterns", "", 0, 1, pats), body])

@unsafe
def f_contains_var(t):
  f_eq(tg(t), "Var") || f_contains_var_terms(ks(t))

@unsafe
def f_contains_var_terms(ts):
  match ts:
    case Nil{}:
      False{}
    case Con{+t, rest}:
      f_contains_var(t) || f_contains_var_terms(rest)

@unsafe
def f_import_used(+name: String, +imports: List<&2,KTerm>) -> Bool:
  match imports:
    case Nil{}: False{}
    case Con{im, rest}: String.eq(name, nm(kid(im, 0))) || f_import_used(name, rest)
