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
  Maybe<&2,KTerm>

law f_valid_patterns:
  for +ps: List<&2, KTerm>
  for +book: List<&2,KDef>
  Maybe<&2,KTerm>

# Ordinary patterns and parallel binders share validation, with the latter
# restricted to names before the ordinary constructor-name check.
law f_valid_patterns_mode:
  for +ps: List<&2, KTerm>
  for +book: List<&2, KDef>
  for +names: Bool
  Maybe<&2,KTerm>

law f_valid_binding_pattern:
  for +p: KTerm
  for +book: List<&2, KDef>
  for +names: Bool
  Maybe<&2,KTerm>

law f_valid_patterns_mode_next:
  for +err: Maybe<&2,KTerm>
  for +ps: List<&2, KTerm>
  for +book: List<&2, KDef>
  for +names: Bool
  Maybe<&2,KTerm>

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
  for +err: Maybe<&2,KTerm>
  KTerm

law f_lambda_valid:
  for +a: KTerm
  for +body: KTerm
  for +cursor: U32
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
def f_valid_pattern(+p: KTerm, +book: List<&2,KDef>) -> Maybe<&2,KTerm>:
  f_choose(Maybe<&2,KTerm>, f_eq(tg(p), "Error"), u => Some{p}, u => f_choose(Maybe<&2,KTerm>, f_eq(tg(p), "Var"),
    u => f_choose(Maybe<&2,KTerm>, Bool.not(f_valid_name(nm(p))), u => Some{kt("Error", "reserved pattern binder: " ++ nm(p), 0, 0, Nil{})},
      u => f_choose(Maybe<&2,KTerm>, f_eq(dk(f_ctor_lookup(nm(p), book)), "Missing"), u => None{}, u => Some{fpe_message_at(p, "a constructor pattern requires braces: " ++ nm(p), "a braced constructor pattern (" ++ nm(p) ++ " is a constructor: write " ++ nm(p) ++ "{}, or rename the binder)")})),
    u => f_choose(Maybe<&2,KTerm>, f_eq(tg(p), "Ctr"), u => f_valid_ctor_pattern(p, f_ctor_lookup(nm(p), book), book), u => Some{fpe_expected_at(p, "expected a binder or constructor pattern", "a pattern (a binder or a constructor)", kp_show(f_scope(p, Nil{}, book)))})))

@unsafe
def f_valid_ctor_pattern(p, ctr, book):
  f_choose(Maybe<&2,KTerm>, f_eq(dk(ctr), "Missing"), u => Some{fpe_message_at(p, "unknown constructor pattern: " ++ nm(p), "a declared constructor (unknown: " ++ nm(p) ++ ")")},
    u => f_choose(Maybe<&2,KTerm>, U32.is_eq(da(ctr), terms_len(ks(p))), u => f_valid_patterns(ks(p), book), u => Some{fpe_message_at(p, "constructor pattern field count differs: " ++ nm(p), "a " ++ nm(p) ++ " pattern with " ++ U32.show(da(ctr)) ++ f_choose(String, U32.is_eq(da(ctr), 1), u => " field", u => " fields"))}))

@unsafe
def f_valid_patterns(ps, book):
  f_valid_patterns_mode(ps, book, False{})

@unsafe
def f_valid_patterns_mode(ps, book, names):
  match ps:
    case Nil{}: None{}
    case Con{p, rest}: f_valid_patterns_mode_next(f_valid_binding_pattern(p, book, names), rest, book, names)

@unsafe
def f_valid_binding_pattern(p, book, names):
  f_choose(Maybe<&2,KTerm>, names && Bool.not(f_eq(tg(p), "Var")), u => Some{fpe_message_at(p, "a parallel let binds names; destructure in its body", "a name (a parallel or typed let binds names; destructure in its body)")}, u => f_valid_pattern(p, book))

@unsafe
def f_valid_patterns_mode_next(err, ps, book, names):
  match err:
    case None{}: f_valid_patterns_mode(ps, book, names)
    case Some{error}: Some{error}

@unsafe
def f_pattern_env(pats, env):
  norm_join(List.reverse(&2, KTerm, f_penv(pats)), env)

@unsafe
def f_scope_row_valid(r, pats, env, book, err):
  match err:
    case None{}: f_scoped_row(pats, f_scope_body(kid(r, 1), f_pattern_env(pats, env), book))
    case Some{error}: kt("Row", "", 0, 1, [kt("Patterns", "", 0, 1, pats), error])

@unsafe
def f_lambda_valid(a, body, cursor):
  f_choose(KTerm, f_eq(tg(a), "Ref") && f_valid_name(nm(a)),
    u => f_choose(KTerm, String.contains(nm(a), "."),
      u => kt_span("FLambda", nm(a), ix(a), qt(a), [body, a, kt_span("LambdaCursor", "", 0, 0, Nil{}, cursor, cursor)], kb(a), ke(a)),
      u => k_lam(nm(a), ix(a), qt(a), [body], kb(a), ke(a), True{})),
    u => fpe_point_at(kt_span("LambdaCursor", "", 0, 0, Nil{}, cursor, cursor), "a lambda binder must be a non-reserved name", "a lambda binder (one name: k => body)"))

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
  +start: List<&2, FToken>,
  +path: String,
  +book: List<&2,KDef>,
  +imports: List<&2,KTerm>,
  +header: List<&2,FToken>,
) -> FRawResult:
  +alias = f_tx(f_tl(ts))
  +rest = f_tl(f_tl(ts))
  f_choose(FRawResult, f_alias_valid(alias) && (f_eq(f_tx(rest), "\n") || f_eq(f_tx(rest), "<eof>")) && U32.is_eq(f_line(ts), f_line(f_tl(ts))) && U32.is_gt(f_col(ts), U32.add(f_col(start), U32.from_nat(String.length(path)))),
    u => f_choose(FRawResult, String.ends_with(path, ".bend"),
      u => f_choose(FRawResult, f_import_used(alias, imports),
        u => f_result(book, fpe_line(start, "expected a fresh alias (" ++ alias ++ " names an earlier import)", "a fresh alias (" ++ alias ++ " names an earlier import)"), imports),
        u => f_choose(FRawResult, f_import_valid(path),
          u => f_tops(rest, book, Con{kt("Import", path, f_line(start), f_col(start), [kt("Alias", alias, 0, 0, Nil{})]), imports}, False{}, f_parse_scope_empty()),
          u => f_result(book, f_import_raw(f_pn(fpe_span(start, start, "invalid import path", "an import path of plain names (letters, digits, _ and -; the hub's files import the hub's)", "'" ++ path ++ "'"))), imports))),
      u => f_result(book, f_import_raw(f_pn(fpe_span(start, start, "an import requires a .bend path and a valid alias", "an import of a .bend file", "'" ++ path ++ "'"))), imports)),
    u => f_result(book, f_import_header_error(header), imports))

@unsafe
def f_validate_param(ts, end, acc):
  f_choose(FParsed, f_eq(f_tx(ts), "~") && Bool.not(f_eq(end, ")")), u => fpe_name_error(ts), u => f_choose(FParsed, Bool.not(f_valid_name(f_tx(f_unmark(ts)))), u => fpe_name_error(f_choose(List<&2,FToken>, f_eq(f_tx(ts), "->"), u => Con{FToken{">", f_line(ts), U32.add(f_col(ts), 1), 0, f_cursor_add(f_begin(ts), 1), f_end(ts), f_cursor_add(f_begin(ts), 1)}, f_tl(ts)}, u => f_unmark(ts))), u => f_choose(FParsed, f_eq(end, "}") && f_named_field(f_tx(f_unmark(ts)), acc), u => fpe_word(f_unmark(ts), "duplicate constructor field", "a fresh field name (duplicate declaration: " ++ f_tx(f_unmark(ts)) ++ ")"), u => f_choose(FParsed, f_eq(f_tx(ts), "~") && U32.is_lt(f_templates(acc), terms_len(acc)), u => fpe_error(ts, "only leading parameters may use ~", "a plain binder (only leading binders take ~)"), u => f_tele_binder(kt_span("Bind", f_tx(f_unmark(ts)), f_atid(ts), f_quant(ts), Nil{}, f_begin(f_unmark(ts)), f_end(f_unmark(ts))), f_eq(f_tx(ts), "~"), f_tl(f_unmark(ts)), end, acc)))))

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
  for +nameTokens: List<&2,FToken>
  for +scope: FParseScope
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
def f_def_prior(name, p, book, imports, unsafe, old, nameTokens, scope):
  f_choose(FRawResult, f_eq(tg(f_pn(p)), "Error"), u => f_result(book, f_pn(p), imports),
    u => f_choose(FRawResult, f_eq(dk(old), "Missing"),
      u => f_choose(FRawResult, Bool.not(f_eq(f_alias(name, imports), name)) && f_eq(f_tx(f_pr(p)), "->"),
        u => f_result(book, f_pn(fpe_word(nameTokens, "an import alias can only name a law fill without a return annotation", "a fresh name (" ++ f_import_alias_head(name) ++ " is an import's alias)")), imports),
        u => f_def_base(name, p, book, imports, unsafe, scope)),
      u => f_choose(FRawResult, Bool.not(f_bare_params(ks(f_pn(p)))),
        u => f_result(book, f_pn(fpe_error(f_pr(p), "a law fill requires plain parameter names", "a name")), imports),
        u => f_choose(FRawResult, U32.is_lt(terms_len(ks(f_pn(p))), dx(old)),
          u => f_result(book, f_pn(fpe_error(f_pr(p), "a law fill requires its template parameters", "a name for each ~ clause of the law (" ++ U32.show(dx(old)) ++ ")")), imports),
          u => f_choose(FRawResult, f_eq(f_tx(f_pr(p)), ":"),
            u => f_def_base(name, p, book, imports, unsafe, scope),
            u => f_result(book, f_pn(fpe_error(f_pr(p), "expected : (a definition filling a law has no return annotation)", "':'")), imports))))))

law f_scope_local_valid:
  for +t: KTerm
  for +pats: List<&2, KTerm>
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  for +err: Maybe<&2,KTerm>
  KTerm

@unsafe
def f_scope_local_valid(t, pats, env, book, err):
  match err:
    case None{}: kt_span("Local", "", 0, qt(t), [terms_at(pats, 0), f_scope(kid(t, 1), env, book), f_scope_body(kid(t, 2), f_pattern_env(pats, env), book)], kb(t), ke(t))
    case Some{error}: error

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
  f_choose(FParsed, f_eq(tg(n), "Ref") && f_eq(f_tx(f_tl(ts)), "("), u => f_grow(FParsed{kt_span("Ref", nm(n), ix(n), 3, ks(n), kb(n), ke(n)), f_tl(ts)}, min), u => fpe_error(ts, "! must follow a named definition and precede call parentheses", "'def', 'type' or 'law'"))

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

@unsafe
def f_match_error(+head: KTerm, +origin: KTerm) -> KTerm:
  +legacy : String = "match requires an unconsumed parameter or constructor field"
  f_choose(KTerm, f_eq(tg(head), "Var") || f_eq(tg(head), "Ref"),
    u => fpe_message_at(head, legacy, "a match on a parameter or field (this name is a def or a consumed binder: give the value its own def)"),
    u => f_choose(KTerm, f_eq(tg(head), "Ctr") || f_eq(tg(head), "Literal") || core_literal(head),
      u => fpe_message_at(origin, legacy, "an undestructed scrutinee (this value is already a constructor: bind its fields directly; if an outer match destructed it, fold the pattern into the outer case)"),
      u => fpe_message_at(f_choose(KTerm, U32.is_gt(kb(head), 0), u => head, u => origin), legacy, "a parameter or field scrutinee (a match cannot scrutinize a computed value: give it its own def)")))
