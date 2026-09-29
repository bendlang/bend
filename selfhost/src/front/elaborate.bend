# Name resolution, literal expansion, and ordered pattern-matrix compilation.

law f_elab_defs:
  for +ds: List<&2, KDef>
  for +book: List<&2, KDef>
  List<&2, KDef>

law f_elab_def:
  for +d: KDef
  for +book: List<&2, KDef>
  KDef

law f_env:
  for +name: String
  for +env: List<&2, KTerm>
  KTerm

law f_tail_terms:
  for +xs: List<&2, KTerm>
  List<&2, KTerm>

law f_scope:
  for +t: KTerm
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  KTerm

law f_scope_ref:
  for +t: KTerm
  for +bound: KTerm
  for +book: List<&2, KDef>
  KTerm

law f_scope_terms:
  for +xs: List<&2, KTerm>
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  List<&2, KTerm>

law f_scope_body:
  for +t: KTerm
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  KTerm

law f_scope_local:
  for +t: KTerm
  for +pats: List<&2, KTerm>
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  KTerm

law f_scope_rows:
  for +rows: List<&2, KTerm>
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  List<&2, KTerm>

law f_scope_row:
  for +r: KTerm
  for +pats: List<&2, KTerm>
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  KTerm

law f_subs:
  for +ts: List<&2, KTerm>
  for +id: U32
  for +v: KTerm
  List<&2, KTerm>

law f_flat:
  for +t: KTerm
  for +vars: List<&2, KTerm>
  KTerm

law f_flat_local:
  for +t: KTerm
  for +vars: List<&2, KTerm>
  KTerm

law f_flat_let:
  for +t: KTerm
  for +vars: List<&2, KTerm>
  for +body: KTerm
  KTerm

law f_first_ctor:
  for +rows: List<&2, KTerm>
  KTerm

law f_has_id:
  for +vars: List<&2, KTerm>
  for +id: U32
  Bool

law f_flat_match:
  for +heads: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +vars: List<&2, KTerm>
  for +origin: KTerm
  KTerm

law f_var_rows:
  for +rows: List<&2, KTerm>
  for +v: KTerm
  List<&2, KTerm>

law f_flat_column:
  for +h: KTerm
  for +hs: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +vars: List<&2, KTerm>
  for +origin: KTerm
  KTerm

law f_flat_split:
  for +h: KTerm
  for +hs: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +v: KTerm
  for +vs: List<&2, KTerm>
  for +c: KTerm
  for +origin: KTerm
  KTerm

law f_fresh_fields:
  for +ps: List<&2, KTerm>
  for +id: U32
  List<&2, KTerm>

law f_flat_fields:
  for +h: KTerm
  for +hs: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +v: KTerm
  for +vs: List<&2, KTerm>
  for +c: KTerm
  for +fields: List<&2, KTerm>
  for +origin: KTerm
  KTerm

law f_hit_rows:
  for +rows: List<&2, KTerm>
  for +c: KTerm
  for +fields: List<&2, KTerm>
  for +v: KTerm
  List<&2, KTerm>

law f_hit_row:
  for +r: KTerm
  for +c: KTerm
  for +fields: List<&2, KTerm>
  for +v: KTerm
  KTerm

law f_miss_rows:
  for +rows: List<&2, KTerm>
  for +name: String
  List<&2, KTerm>

law f_literal:
  for +s: String
  KTerm

law f_string:
  for +s: String
  KTerm

@unsafe
def f_elaborate(
  +r: FResult,
) -> FResult:
  match r:
    case FResult{+book, err, imports}:
      f_validate_result(FResult{f_elab_defs(book, f_family_book(book)), err, imports})

@unsafe
def f_elab_defs(ds, book):
  match ds:
    case Nil{}:
      Nil{}
    case Con{d, rest}:
      Con{f_elab_def(d, book), f_elab_defs(rest, book)}

@unsafe
def f_elab_def(d, book):
  match d:
    case KDef{name, kind, arity, templates, ty, value, ctors, native, unsafe}:
      KDef{name, kind, arity, templates, f_scope(ty, Nil{}, book), f_scope(value, Nil{}, book), f_elab_defs(ctors, book), native, unsafe}

@unsafe
def f_env(name, env):
  match env:
    case Nil{}:
      atom("Absent")
    case Con{+x, xs}:
      f_choose(KTerm, f_eq(name, nm(x)) && (Bool.not(f_eq(name, "_")) || f_eq(tg(x), "RewriteVar")), u => x, u => f_env(name, xs))

@unsafe
def f_tail_terms(xs):
  match xs:
    case Nil{}:
      Nil{}
    case Con{x, xt}:
      xt

@unsafe
def f_vars(
  +xs: List<&2, KTerm>,
) -> List<&2, KTerm>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+x, xt}:
      Con{kt_span("Var", nm(x), ix(x), 1, Nil{}, kb(x), ke(x)), f_vars(xt)}

@unsafe
def f_scope_base(
  +t: KTerm,
  +env: List<&2, KTerm>,
  +book: List<&2, KDef>,
) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "Ref"), u => f_scope_ref(t, f_env(nm(t), env), book),
    u => f_choose(KTerm, f_eq(tg(t), "Literal"), u => f_literal_at(t),
    u => f_choose(KTerm, f_eq(tg(t), "All"), u => kt_span("All", nm(t), ix(t), qt(t), [f_scope(kid(t, 0), env, book), f_scope(kid(t, 1), Con{kt_span("Var", nm(t), ix(t), qt(t), Nil{}, kb(t), ke(t)), env}, book)], kb(t), ke(t)),
    u => f_choose(KTerm, f_eq(tg(t), "Lam") || f_eq(tg(t), "FLambda"), u => f_scope_lambda_eligible(t, env, book),
    u => f_choose(KTerm, f_eq(tg(t), "Body"), u => ff_term(ff_flat(f_scope_body(kid(t, 1), norm_join(f_vars(ks(kid(t, 0))), env), book), f_vars(ks(kid(t, 0))), ix(t))),
    u => f_choose(KTerm, f_eq(tg(t), "Local") || f_eq(tg(t), "Match"), u => f_flat(f_scope_body(t, env, book), Nil{}),
    u => k_with_children(t, f_scope_terms(ks(t), env, book))))))))

@unsafe
def f_scope_ref(t, bound, book):
  f_scope_reference(t, bound, book)

@unsafe
def f_scope_terms(xs, env, book):
  match xs:
    case Nil{}:
      Nil{}
    case Con{x, xt}:
      Con{f_scope(x, env, book), f_scope_terms(xt, env, book)}

@unsafe
def f_patterns(
  +xs: List<&2, KTerm>,
  +env: List<&2,KTerm>,
  +book: List<&2,KDef>,
) -> List<&2, KTerm>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+x, xt}:
      Con{f_choose(KTerm, U32.is_eq(qt(x), 2) && (f_eq(tg(x), "Ref") || f_eq(tg(x), "FAliasRef") || (f_eq(tg(x), "Call") && U32.is_eq(terms_len(ks(x)), 1))), u => f_pattern_marked(x, f_scope(x, env, book)), u => f_choose(KTerm, f_eq(tg(x), "Ref") || f_eq(tg(x), "FAliasRef"), u => f_pattern_reference(x, env), u => f_choose(KTerm, f_eq(tg(x), "Literal"), u => f_span_created(f_pattern_literal(nm(x)), kb(x), ke(x)), u => f_choose(KTerm, f_eq(tg(x), "Ctr"), u => k_with_children(x, f_patterns(ks(x), env, book)), u => f_choose(KTerm, f_eq(tg(x), "Call") && U32.is_eq(qt(x), 1) && U32.is_eq(terms_len(ks(x)), 1), u => f_pattern_empty_call(x, kid(x, 0), env), u => x))))), f_patterns(xt, env, book)}

# parse_bind turns the marked-variable sentinel into a Many binder.
@unsafe
def f_pattern_marked(+origin: KTerm, +scoped: KTerm) -> KTerm:
  f_choose(KTerm, f_eq(tg(scoped), "FUnboundVar"),
    u => kt_span("Var", nm(scoped), ix(scoped), 2, Nil{}, kb(origin), ke(origin)),
    u => scoped)

# Empty ordinary calls keep a bound name a binder; unbound calls keep scope validation.
@unsafe
def f_pattern_empty_call(+original: KTerm, +head: KTerm, +env: List<&2,KTerm>) -> KTerm:
  f_choose(KTerm, f_eq(tg(head), "Call") && U32.is_eq(qt(head), 1) && U32.is_eq(terms_len(ks(head)), 1),
    u => f_pattern_empty_call(original, kid(head, 0), env),
    u => f_choose(KTerm, (f_eq(tg(head), "Ref") || f_eq(tg(head), "FAliasRef")) && U32.is_eq(qt(head), 1),
      u => f_choose(KTerm, f_eq(tg(f_env(nm(head), env)), "Absent"),
        u => k_with_span(original, kb(head), ke(head)),
        u => kt_span("Var", nm(head), ix(head), qt(head), Nil{}, kb(head), ke(head))),
      u => original))

@unsafe
def f_penv(
  +xs: List<&2, KTerm>,
) -> List<&2, KTerm>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+x, xt}:
      f_choose(List<&2, KTerm>, f_eq(tg(x), "Var"), u => Con{x, f_penv(xt)}, u => norm_join(f_penv(ks(x)), f_penv(xt)))

@unsafe
def f_scope_body_base(
  +t: KTerm,
  +env: List<&2, KTerm>,
  +book: List<&2, KDef>,
) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "Local"), u => f_scope_local(t, f_patterns([kid(t, 0)], env, book), env, book), u => f_choose(KTerm, f_eq(tg(t), "Match"), u => kt_span("Match", "", 0, 1, Con{kt("Heads", "", 0, 1, f_scope_terms(ks(kid(t, 0)), env, book)), f_scope_rows(f_tail_terms(ks(t)), env, book)}, kb(t), ke(t)), u => f_scope(t, env, book)))

# A qualified spelling is a binder only when parse_var would find it in scope.
@unsafe
def f_pattern_reference(+t: KTerm, +env: List<&2,KTerm>) -> KTerm:
  f_choose(KTerm, f_choose(Bool, String.contains(nm(t), "."), u => Bool.not(f_eq(tg(f_env(nm(t), env)), "Absent")), u => True{}),
    u => kt_span("Var", nm(t), ix(t), qt(t), Nil{}, kb(t), ke(t)),
    u => f_choose(KTerm, f_eq(tg(t), "FAliasRef"), u => kid(t, 0), u => t))

@unsafe
def f_scope_local(t, pats, env, book):
  # Do assignments bind one name; ordinary locals may destructure constructors.
  f_scope_local_valid(t, pats, env, book, f_valid_patterns(pats, f_choose(List<&2, KDef>, f_eq(nm(t), "Do"), u => Nil{}, u => book)))

@unsafe
def f_scope_rows(rows, env, book):
  match rows:
    case Nil{}:
      Nil{}
    case Con{r, rs}:
      Con{f_scope_row(r, f_patterns(ks(kid(r, 0)), env, book), env, book), f_scope_rows(rs, env, book)}

@unsafe
def f_scope_row(r, pats, env, book):
  f_scope_row_valid(r, pats, env, book, f_valid_patterns(pats, book))

@unsafe
def f_sub(
  +t: KTerm,
  +id: U32,
  +v: KTerm,
) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "Var") && U32.is_eq(ix(t), id), u => v, u => k_with_children(t, f_subs(ks(t), id, v)))

@unsafe
def f_subs(ts, id, v):
  match ts:
    case Nil{}:
      Nil{}
    case Con{t, rest}:
      Con{f_sub(t, id, v), f_subs(rest, id, v)}

@unsafe
def f_flat_base(
  +t: KTerm,
  +vars: List<&2, KTerm>,
) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "Match"), u => f_flat_match(ks(kid(t, 0)), f_tail_terms(ks(t)), vars, t), u => f_choose(KTerm, f_eq(tg(t), "Local"), u => f_flat_local(t, vars), u => f_lbind(vars, t)))

@unsafe
def f_flat_local(t, vars):
  f_choose(KTerm, f_eq(tg(kid(t, 0)), "Ctr"), u => f_flat_match([kid(t, 1)], [kt("Row", "", 0, 1, [kt("Patterns", "", 0, 1, [kid(t, 0)]), kid(t, 2)])], vars, kid(t, 1)), u => f_flat_let(t, vars, f_flat(kid(t, 2), [kid(t, 0)])))

@unsafe
def f_flat_let(t, vars, body):
  f_choose(KTerm, f_eq(tg(body), "Lam"), u => f_lbind(vars, kt_span("Let", "", 0, 1, [kt_span("Bind", nm(kid(t, 0)), ix(kid(t, 0)), qt(kid(t, 0)), [kid(t, 1)], kb(kid(t, 0)), ke(kid(t, 0))), kid(body, 0)], kb(t), ke(t))), u => fpe_message_at(kid(t, 0), "a match cannot scrutinize a local binding", "a parameter or field scrutinee (a match cannot scrutinize a local binder: give it its own def)"))

@unsafe
def f_rowpat(
  +r: KTerm,
) -> KTerm:
  kid(kid(r, 0), 0)

@unsafe
def f_first_ctor(rows):
  match rows:
    case Nil{}:
      atom("Absent")
    case Con{+r, rs}:
      f_choose(KTerm, f_eq(tg(f_rowpat(r)), "Ctr"), u => f_rowpat(r), u => f_first_ctor(rs))

@unsafe
def f_has_id(vars, id):
  match vars:
    case Nil{}:
      False{}
    case Con{v, vs}:
      U32.is_eq(ix(v), id) || f_has_id(vs, id)

@unsafe
def f_flat_match(heads, rows, vars, origin):
  match heads:
    case Nil{}:
      f_choose(KTerm, U32.is_eq(terms_len(rows), 0), u => kt_span("Efq", "", 0, 0, Nil{}, kb(origin), ke(origin)), u => f_flat(kid(terms_at(rows, 0), 1), vars))
    case Con{+h, hs}:
      f_choose(KTerm, f_eq(tg(f_first_ctor(rows)), "Absent") && U32.is_gt(terms_len(rows), 0) && f_has_id(vars, ix(h)), u => f_flat_match(hs, f_var_rows(rows, h), f_mark_vars(vars, ix(h), f_mark_rows(rows, qt(h))), origin), u => f_flat_column(h, hs, rows, vars, origin))

@unsafe
def f_var_rows(rows, v):
  match rows:
    case Nil{}:
      Nil{}
    case Con{+r, rs}:
      Con{kt("Row", "", 0, qt(r), [kt("Patterns", "", 0, 1, f_tail_terms(ks(kid(r, 0)))), f_choose(KTerm, U32.is_eq(qt(r), 0), u => kid(r, 1), u => f_pattern_sub(kid(r, 1), ix(f_rowpat(r)), v))]), f_var_rows(rs, v)}

@unsafe
def f_flat_column(h, hs, rows, vars, origin):
  match vars:
    case Nil{}:
      f_match_error(h, origin)
    case Con{+v, vs}:
      f_choose(KTerm, U32.is_eq(ix(h), ix(v)), u => f_flat_split(h, hs, rows, v, vs, f_first_ctor(rows), origin), u => k_lam(nm(v), ix(v), qt(v), [f_flat_match(Con{h, hs}, rows, vs, origin)], kb(v), ke(v), True{}))

@unsafe
def f_flat_split(h, hs, rows, v, vs, c, origin):
  f_choose(KTerm, f_eq(tg(c), "Absent"), u => kt_span("Efq", "", 0, 0, Nil{}, kb(origin), ke(origin)), u => f_flat_fields(h, hs, rows, v, vs, c, f_mark_fields(f_fresh_fields(ks(c), U32.add(2147483648, ix(c))), f_mark_rows(rows, qt(v))), origin))

@unsafe
def f_fresh_fields(ps, id):
  match ps:
    case Nil{}:
      Nil{}
    case Con{+p, rest}:
      Con{f_choose(KTerm, f_eq(tg(p), "Var"), u => p, u => kt("Var", "_field", id, 1, Nil{})), f_fresh_fields(rest, U32.add(id, 1))}

@unsafe
def f_flat_fields(h, hs, rows, v, vs, c, fields, origin):
  kt_span("Mat", nm(c), 0, 1, [f_flat_match(norm_join(fields, hs), f_hit_rows(rows, c, fields, v), norm_join(fields, vs), origin), f_flat_match(Con{h, hs}, f_miss_rows(rows, nm(c)), Con{v, vs}, origin)], kb(c), ke(c))

@unsafe
def f_hit_rows(rows, c, fields, v):
  match rows:
    case Nil{}:
      Nil{}
    case Con{+r, rs}:
      f_choose(List<&2, KTerm>, f_eq(tg(f_rowpat(r)), "Var") || f_eq(nm(f_rowpat(r)), nm(c)), u => Con{f_hit_row(r, c, fields, v), f_hit_rows(rs, c, fields, v)}, u => f_hit_rows(rs, c, fields, v))

@unsafe
def f_hit_row(r, c, fields, v):
  kt("Row", "", 0, qt(r), [kt("Patterns", "", 0, 1, norm_join(f_choose(List<&2, KTerm>, f_eq(tg(f_rowpat(r)), "Var"), u => fields, u => ks(f_rowpat(r))), f_tail_terms(ks(kid(r, 0))))), f_choose(KTerm, U32.is_eq(qt(r), 0), u => kid(r, 1), u => f_pattern_sub(f_choose(KTerm, f_eq(tg(f_rowpat(r)), "Var"), u => f_pattern_sub(kid(r, 1), ix(f_rowpat(r)), v), u => kid(r, 1)), ix(v), kt_span("Ctr", nm(c), 0, 1, fields, kb(c), ke(c))))])

@unsafe
def f_miss_rows(rows, name):
  match rows:
    case Nil{}:
      Nil{}
    case Con{+r, rs}:
      f_choose(List<&2, KTerm>, f_eq(tg(f_rowpat(r)), "Ctr") && f_eq(nm(f_rowpat(r)), name), u => f_miss_rows(rs, name), u => Con{r, f_miss_rows(rs, name)})

@unsafe
def f_u32(
  +n: U32,
) -> KTerm:
  kl_make("U32", n, "")

@unsafe
def f_nat(
  +n: U32,
) -> KTerm:
  core_nat_make(n)

@unsafe
def f_number(
  +s: String,
  +acc: U32,
) -> KTerm:
  f_choose(KTerm, String.is_empty(s), u => f_u32(acc), u => f_choose(KTerm, f_eq(s, "n"), u => f_nat(acc), u => f_choose(KTerm, Char.is_digit(f_head(s)) && (U32.is_lt(acc, 429496729) || (U32.is_eq(acc, 429496729) && U32.is_le(Char.to_u32(f_head(s)), 53))), u => f_number(f_tail(s), U32.add(U32.mul(acc, 10), U32.sub(Char.to_u32(f_head(s)), 48))), u => kt("Error", "invalid or unsupported numeric literal", 0, 0, Nil{}))))

@unsafe
def f_literal(s):
  f_choose(KTerm, Char.is_eq(f_head(s), '"'), u => f_string(f_tail(s)), u => f_choose(KTerm, Char.is_eq(f_head(s), '\''), u => f_char_literal(f_tail(s)), u => f_choose(KTerm, f_contains(s, '.'), u => f_float(s), u => f_number(s, 0))))

@unsafe
def f_string(s):
  f_string_at(s, atom("Absent"))

@unsafe
def f_escape_code(
  +c: Char,
) -> U32:
  f_choose(U32, Char.is_eq(c, 'n'), u => 10, u => f_choose(U32, Char.is_eq(c, 't'), u => 9, u => f_choose(U32, Char.is_eq(c, 'r'), u => 13, u => f_choose(U32, Char.is_eq(c, '0'), u => 0, u => Char.to_u32(c)))))


@unsafe
def f_scope_body(t, env, book):
  f_choose(KTerm, f_eq(tg(t), "Parallel"), u => f_scope_parallel(t, env, book), u => f_scope_body_base(t, env, book))

@unsafe
def f_flat(t, vars):
  f_choose(KTerm, f_eq(tg(t), "Parallel"), u => f_flat_parallel(t, vars), u => f_flat_base(t, vars))

@unsafe
def f_scope_lower(
  +t: KTerm,
  +env: List<&2, KTerm>,
  +book: List<&2, KDef>,
) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "Write"), u => f_scope(kid(t, 0), env, book), u => f_choose(KTerm, f_eq(tg(t), "ADT"), u => f_adt(t, f_scope_terms(ks(t), env, book), f_find(nm(t), book)), u => f_choose(KTerm, f_eq(tg(t), "App"), u => f_scope_app_span(f_scope(kid(t, 0), env, book), f_scope(kid(t, 1), env, book), kb(t), ke(t)), u => f_scope_base(t, env, book))))

law f_family_book:
  for +book: List<&2, KDef>
  List<&2, KDef>

@unsafe
def f_family_book(book):
  match book:
    case Nil{}:
      Nil{}
    case Con{+d, rest}:
      f_choose(List<&2, KDef>, f_eq(dk(d), "ADT") || U32.is_gt(dx(d), 0), u => Con{d, f_family_book(rest)}, u => f_family_book(rest))

@unsafe
def f_scope(t, env, book):
  f_choose(KTerm, f_eq(tg(t), "FAliasRef"), u => f_scope_alias(t, f_env(nm(t), env), book, False{}), u => f_choose(KTerm, f_eq(tg(t), "FDo"), u => f_scope_do(t, env, book), u => f_choose(KTerm, f_eq(tg(t), "Call"), u => f_scope_call(t, env, book), u => f_choose(KTerm, f_eq(tg(t), "TemplateArg"), u => kt("Error", "~ is only valid in a named template call", 0, 0, Nil{}), u => f_scope_lower(t, env, book)))))

# Pattern substitution is renaming/destructuring, not beta substitution: each
# occurrence supplies the range for the substituted pattern and all its fields.
@unsafe
def f_pattern_sub(+t: KTerm, +id: U32, +value: KTerm) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "Var") && U32.is_eq(ix(t), id),
    u => f_pattern_value(value, kb(t), ke(t)),
    u => k_with_children(t, f_pattern_subs(ks(t), id, value)))

@unsafe
def f_pattern_subs(+terms: List<&2,KTerm>, +id: U32, +value: KTerm) -> List<&2,KTerm>:
  match terms:
    case Nil{}: Nil{}
    case Con{head, rest}: Con{f_pattern_sub(head, id, value), f_pattern_subs(rest, id, value)}

@unsafe
def f_pattern_value(+t: KTerm, +begin: U32, +end: U32) -> KTerm:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, oldBegin, oldEnd}:
      KTerm{tag, name, id, quant, f_pattern_values(kids, begin, end), removed,
        f_choose(U32, U32.is_gt(begin, 0), u => begin, u => oldBegin),
        f_choose(U32, U32.is_gt(begin, 0), u => end, u => oldEnd)}
    case KLambda{name, id, quant, kids, removed, oldBegin, oldEnd, present}:
      KLambda{name, id, quant, f_pattern_values(kids, begin, end), removed,
        f_choose(U32, U32.is_gt(begin, 0), u => begin, u => oldBegin),
        f_choose(U32, U32.is_gt(begin, 0), u => end, u => oldEnd), present}
    case KLiteral{kind, number, text, literalBegin, literalEnd}:
      f_choose(KTerm, U32.is_gt(begin, 0), u => k_with_span(t, begin, end), u => t)

@unsafe
def f_pattern_values(+terms: List<&2,KTerm>, +begin: U32, +end: U32) -> List<&2,KTerm>:
  match terms:
    case Nil{}: Nil{}
    case Con{head, rest}: Con{f_pattern_value(head, begin, end), f_pattern_values(rest, begin, end)}

@unsafe
def f_literal_at(+origin: KTerm) -> KTerm:
  f_choose(KTerm, Char.is_eq(f_head(nm(origin)), '"'),
    u => k_with_span(f_string_at(f_tail(nm(origin)), origin), kb(origin), ke(origin)),
    u => f_literal_value(origin, f_literal(nm(origin))))

@unsafe
def f_literal_value(+origin: KTerm, +value: KTerm) -> KTerm:
  f_choose(KTerm, f_eq(tg(value), "Error") && f_ascii_digit(f_head(nm(origin))) && U32.is_gt(kb(origin), 0),
    u => f_numeric_error(origin, nm(origin), 0, value), u => k_with_span(value, kb(origin), ke(origin)))

@unsafe
def f_numeric_error(+origin: KTerm, +rest: String, +offset: U32, +legacy: KTerm) -> KTerm:
  f_choose(KTerm, f_ascii_digit(f_head(rest)), u => f_numeric_error(origin, f_tail(rest), U32.add(offset, 1), legacy),
    u => f_choose(KTerm, String.is_empty(rest),
      u => fpe_expected_at(origin, nm(legacy), "a u32 literal up to 4294967295 (got " ++ nm(origin) ++ ")", "'" ++ nm(origin) ++ "'"),
      u => f_choose(KTerm, (Char.is_eq(f_head(rest), '.') && f_ascii_digit(f_head(f_tail(rest)))) || Char.is_eq(f_head(rest), 'n'),
        u => k_with_span(legacy, kb(origin), ke(origin)),
        u => fpe_expected_at(k_with_span(origin, U32.add(kb(origin), offset), U32.add(kb(origin), offset)), nm(legacy), "a numeric literal (NUMBER is U32, NUMBER n is Nat)", "'" ++ SCon{f_head(rest), ""} ++ "'"))))

@unsafe
def f_string_at(+s: String, +origin: KTerm) -> KTerm:
  f_choose(KTerm, Char.is_eq(f_head(s), '"'), u => kl_make("String", 0, ""), u => f_string_decoded_at(f_decode_char(s), origin))

@unsafe
def f_scope_alias(+t: KTerm, +bound: KTerm, +book: List<&2,KDef>, +called: Bool) -> KTerm:
  f_scope_alias_selected(f_choose(KTerm, f_eq(tg(bound), "Absent"), u => kid(t, 0), u => kt_span("Ref", nm(t), ix(t), qt(t), Nil{}, kb(t), ke(t))), bound, book, called)

@unsafe
def f_scope_alias_selected(+t: KTerm, +bound: KTerm, +book: List<&2,KDef>, +called: Bool) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "Error"), u => t,
    u => f_choose(KTerm, called, u => f_scope_marked(t, bound, f_find(nm(t), book), True{}), u => f_scope_reference(t, bound, book)))
