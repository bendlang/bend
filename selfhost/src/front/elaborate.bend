# Name resolution, literal expansion, and ordered pattern-matrix compilation.

law f_elaborate:
  for +r: FResult
  FResult

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

law f_concat:
  for +xs: List<&2, KTerm>
  for +ys: List<&2, KTerm>
  List<&2, KTerm>

law f_vars:
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

law f_patterns:
  for +xs: List<&2, KTerm>
  List<&2, KTerm>

law f_penv:
  for +xs: List<&2, KTerm>
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

law f_sub:
  for +t: KTerm
  for +id: U32
  for +v: KTerm
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

law f_rowpat:
  for +r: KTerm
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
  KTerm

law f_flat_split:
  for +h: KTerm
  for +hs: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +v: KTerm
  for +vs: List<&2, KTerm>
  for +c: KTerm
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

law f_word:
  for +n: U32
  for +bits: U32
  KTerm

law f_u32:
  for +n: U32
  KTerm

law f_nat:
  for +n: U32
  KTerm

law f_number:
  for +s: String
  for +acc: U32
  KTerm

law f_literal:
  for +s: String
  KTerm

law f_string:
  for +s: String
  KTerm

law f_escape_code:
  for +c: Char
  U32

@unsafe
def f_elaborate(r):
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
def f_concat(xs, ys):
  match xs:
    case Nil{}:
      ys
    case Con{x, xt}:
      Con{x, f_concat(xt, ys)}

@unsafe
def f_vars(xs):
  match xs:
    case Nil{}:
      Nil{}
    case Con{+x, xt}:
      Con{kt("Var", nm(x), ix(x), 1, Nil{}), f_vars(xt)}

@unsafe
def f_scope_base(t, env, book):
  f_choose(KTerm, f_eq(tg(t), "Ref"), u => f_scope_ref(t, f_env(nm(t), env), book),
    u => f_choose(KTerm, f_eq(tg(t), "Literal"), u => f_literal(nm(t)),
    u => f_choose(KTerm, f_eq(tg(t), "All"), u => kt("All", nm(t), ix(t), qt(t), [f_scope(kid(t, 0), env, book), f_scope(kid(t, 1), Con{kt("Var", nm(t), ix(t), qt(t), Nil{}), env}, book)]),
    u => f_choose(KTerm, f_eq(tg(t), "Lam"), u => f_scope_lambda(t, env, book),
    u => f_choose(KTerm, f_eq(tg(t), "Body"), u => ff_term(ff_flat(f_scope_body(kid(t, 1), f_concat(f_vars(ks(kid(t, 0))), env), book), f_vars(ks(kid(t, 0))), ix(t))),
    u => f_choose(KTerm, f_eq(tg(t), "Local") || f_eq(tg(t), "Match"), u => f_flat(f_scope_body(t, env, book), Nil{}),
    u => KTerm{tg(t), nm(t), ix(t), qt(t), f_scope_terms(ks(t), env, book), rm(t)}))))))

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
def f_patterns(xs):
  match xs:
    case Nil{}:
      Nil{}
    case Con{+x, xt}:
      Con{f_choose(KTerm, f_eq(tg(x), "Ref"), u => kt("Var", nm(x), ix(x), qt(x), Nil{}), u => f_choose(KTerm, f_eq(tg(x), "Literal"), u => f_pattern_literal(nm(x)), u => kt(tg(x), nm(x), ix(x), qt(x), f_patterns(ks(x))))), f_patterns(xt)}

@unsafe
def f_penv(xs):
  match xs:
    case Nil{}:
      Nil{}
    case Con{+x, xt}:
      f_choose(List<&2, KTerm>, f_eq(tg(x), "Var"), u => Con{x, f_penv(xt)}, u => f_concat(f_penv(ks(x)), f_penv(xt)))

@unsafe
def f_scope_body_base(t, env, book):
  f_choose(KTerm, f_eq(tg(t), "Local"), u => f_scope_local(t, f_patterns([kid(t, 0)]), env, book), u => f_choose(KTerm, f_eq(tg(t), "Match"), u => kt("Match", "", 0, 1, Con{kt("Heads", "", 0, 1, f_scope_terms(ks(kid(t, 0)), env, book)), f_scope_rows(f_tail_terms(ks(t)), env, book)}), u => f_scope(t, env, book)))

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
      Con{f_scope_row(r, f_patterns(ks(kid(r, 0))), env, book), f_scope_rows(rs, env, book)}

@unsafe
def f_scope_row(r, pats, env, book):
  f_scope_row_valid(r, pats, env, book, f_valid_patterns(pats, book))

@unsafe
def f_sub(t, id, v):
  f_choose(KTerm, f_eq(tg(t), "Var") && U32.is_eq(ix(t), id), u => v, u => KTerm{tg(t), nm(t), ix(t), qt(t), f_subs(ks(t), id, v), rm(t)})

@unsafe
def f_subs(ts, id, v):
  match ts:
    case Nil{}:
      Nil{}
    case Con{t, rest}:
      Con{f_sub(t, id, v), f_subs(rest, id, v)}

@unsafe
def f_flat_base(t, vars):
  f_choose(KTerm, f_eq(tg(t), "Match"), u => f_flat_match(ks(kid(t, 0)), f_tail_terms(ks(t)), vars), u => f_choose(KTerm, f_eq(tg(t), "Local"), u => f_flat_local(t, vars), u => f_lbind(vars, t)))

@unsafe
def f_flat_local(t, vars):
  f_choose(KTerm, f_eq(tg(kid(t, 0)), "Ctr"), u => f_flat_match([kid(t, 1)], [kt("Row", "", 0, 1, [kt("Patterns", "", 0, 1, [kid(t, 0)]), kid(t, 2)])], vars), u => f_flat_let(t, vars, f_flat(kid(t, 2), [kid(t, 0)])))

@unsafe
def f_flat_let(t, vars, body):
  f_choose(KTerm, f_eq(tg(body), "Lam"), u => f_lbind(vars, kt("Let", "", 0, 1, [kt("Bind", nm(kid(t, 0)), ix(kid(t, 0)), qt(kid(t, 0)), [kid(t, 1)]), kid(body, 0)])), u => kt("Error", "a match cannot scrutinize a local binding", 0, 0, Nil{}))

@unsafe
def f_rowpat(r):
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
def f_flat_match(heads, rows, vars):
  match heads:
    case Nil{}:
      f_choose(KTerm, U32.is_eq(f_len(rows), 0), u => atom("Efq"), u => f_flat(kid(terms_at(rows, 0), 1), vars))
    case Con{+h, hs}:
      f_choose(KTerm, f_eq(tg(f_first_ctor(rows)), "Absent") && U32.is_gt(f_len(rows), 0) && f_has_id(vars, ix(h)), u => f_flat_match(hs, f_var_rows(rows, h), f_mark_vars(vars, ix(h), f_mark_rows(rows, qt(h)))), u => f_flat_column(h, hs, rows, vars))

@unsafe
def f_var_rows(rows, v):
  match rows:
    case Nil{}:
      Nil{}
    case Con{+r, rs}:
      Con{kt("Row", "", 0, qt(r), [kt("Patterns", "", 0, 1, f_tail_terms(ks(kid(r, 0)))), f_choose(KTerm, U32.is_eq(qt(r), 0), u => kid(r, 1), u => f_sub(kid(r, 1), ix(f_rowpat(r)), v))]), f_var_rows(rs, v)}

@unsafe
def f_flat_column(h, hs, rows, vars):
  match vars:
    case Nil{}:
      kt("Error", "match requires an unconsumed parameter or constructor field", 0, 0, Nil{})
    case Con{+v, vs}:
      f_choose(KTerm, U32.is_eq(ix(h), ix(v)), u => f_flat_split(h, hs, rows, v, vs, f_first_ctor(rows)), u => kt("Lam", nm(v), ix(v), qt(v), [f_flat_match(Con{h, hs}, rows, vs)]))

@unsafe
def f_flat_split(h, hs, rows, v, vs, c):
  f_choose(KTerm, f_eq(tg(c), "Absent"), u => atom("Efq"), u => f_flat_fields(h, hs, rows, v, vs, c, f_mark_fields(f_fresh_fields(ks(c), U32.add(2147483648, ix(c))), f_mark_rows(rows, qt(v)))))

@unsafe
def f_fresh_fields(ps, id):
  match ps:
    case Nil{}:
      Nil{}
    case Con{+p, rest}:
      Con{f_choose(KTerm, f_eq(tg(p), "Var"), u => p, u => kt("Var", "_field", id, 1, Nil{})), f_fresh_fields(rest, U32.add(id, 1))}

@unsafe
def f_flat_fields(h, hs, rows, v, vs, c, fields):
  kt("Mat", nm(c), 0, 1, [f_flat_match(f_concat(fields, hs), f_hit_rows(rows, c, fields, v), f_concat(fields, vs)), f_flat_match(Con{h, hs}, f_miss_rows(rows, nm(c)), Con{v, vs})])

@unsafe
def f_hit_rows(rows, c, fields, v):
  match rows:
    case Nil{}:
      Nil{}
    case Con{+r, rs}:
      f_choose(List<&2, KTerm>, f_eq(tg(f_rowpat(r)), "Var") || f_eq(nm(f_rowpat(r)), nm(c)), u => Con{f_hit_row(r, c, fields, v), f_hit_rows(rs, c, fields, v)}, u => f_hit_rows(rs, c, fields, v))

@unsafe
def f_hit_row(r, c, fields, v):
  kt("Row", "", 0, qt(r), [kt("Patterns", "", 0, 1, f_concat(f_choose(List<&2, KTerm>, f_eq(tg(f_rowpat(r)), "Var"), u => fields, u => ks(f_rowpat(r))), f_tail_terms(ks(kid(r, 0))))), f_choose(KTerm, U32.is_eq(qt(r), 0), u => kid(r, 1), u => f_sub(f_choose(KTerm, f_eq(tg(f_rowpat(r)), "Var"), u => f_sub(kid(r, 1), ix(f_rowpat(r)), v), u => kid(r, 1)), ix(v), kt("Ctr", nm(c), 0, 1, fields)))])

@unsafe
def f_miss_rows(rows, name):
  match rows:
    case Nil{}:
      Nil{}
    case Con{+r, rs}:
      f_choose(List<&2, KTerm>, f_eq(tg(f_rowpat(r)), "Ctr") && f_eq(nm(f_rowpat(r)), name), u => f_miss_rows(rs, name), u => Con{r, f_miss_rows(rs, name)})

@unsafe
def f_word(n, bits):
  f_choose(KTerm, U32.is_eq(bits, 0), u => kt("Ctr", "WNil", 0, 1, Nil{}), u => kt("Ctr", "WCon", 0, 1, [kt("Ctr", f_choose(String, U32.is_eq(U32.and(n, 1), 0), u => "False", u => "True"), 0, 1, Nil{}), f_word(U32.shrn(n, 1n), U32.sub(bits, 1))]))

@unsafe
def f_u32(n):
  kt("Ctr", "U32", 0, 1, [f_word(n, 32)])

@unsafe
def f_nat(n):
  f_choose(KTerm, U32.is_gt(n, 256), u => app(ref("U32.to_nat"), f_u32(n)), u => f_choose(KTerm, U32.is_eq(n, 0), u => kt("Ctr", "Zero", 0, 1, Nil{}), u => kt("Ctr", "Succ", 0, 1, [f_nat(U32.sub(n, 1))])))

@unsafe
def f_number(s, acc):
  f_choose(KTerm, String.is_empty(s), u => f_u32(acc), u => f_choose(KTerm, f_eq(s, "n"), u => f_nat(acc), u => f_choose(KTerm, Char.is_digit(f_head(s)) && (U32.is_lt(acc, 429496729) || (U32.is_eq(acc, 429496729) && U32.is_le(Char.to_u32(f_head(s)), 53))), u => f_number(f_tail(s), U32.add(U32.mul(acc, 10), U32.sub(Char.to_u32(f_head(s)), 48))), u => kt("Error", "invalid or unsupported numeric literal", 0, 0, Nil{}))))

@unsafe
def f_literal(s):
  f_choose(KTerm, Char.is_eq(f_head(s), '"'), u => f_string(f_tail(s)), u => f_choose(KTerm, Char.is_eq(f_head(s), '\''), u => f_char_literal(f_tail(s)), u => f_choose(KTerm, f_contains(s, '.'), u => f_float(s), u => f_number(s, 0))))

@unsafe
def f_string(s):
  f_choose(KTerm, Char.is_eq(f_head(s), '"'), u => kt("Ctr", "SNil", 0, 1, Nil{}), u => f_string_decoded(f_decode_char(s)))

@unsafe
def f_escape_code(c):
  f_choose(U32, Char.is_eq(c, 'n'), u => 10, u => f_choose(U32, Char.is_eq(c, 't'), u => 9, u => f_choose(U32, Char.is_eq(c, 'r'), u => 13, u => f_choose(U32, Char.is_eq(c, '0'), u => 0, u => Char.to_u32(c)))))


law f_scope_body_base:
  for +t: KTerm
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  KTerm

law f_flat_base:
  for +t: KTerm
  for +vars: List<&2, KTerm>
  KTerm

@unsafe
def f_scope_body(t, env, book):
  f_choose(KTerm, f_eq(tg(t), "Parallel"), u => f_scope_parallel(t, env, book), u => f_scope_body_base(t, env, book))

@unsafe
def f_flat(t, vars):
  f_choose(KTerm, f_eq(tg(t), "Parallel"), u => f_flat_parallel(t, vars), u => f_flat_base(t, vars))

law f_scope_base:
  for +t: KTerm
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  KTerm

@unsafe
def f_scope_lower(t, env, book):
  f_choose(KTerm, f_eq(tg(t), "Write"), u => f_scope(kid(t, 0), env, book), u => f_choose(KTerm, f_eq(tg(t), "ADT"), u => f_adt(t, f_scope_terms(ks(t), env, book), f_find(nm(t), book)), u => f_choose(KTerm, f_eq(tg(t), "App"), u => f_scope_app(f_scope(kid(t, 0), env, book), f_scope(kid(t, 1), env, book)), u => f_scope_base(t, env, book))))

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

law f_scope_lower:
  for +t: KTerm
  for +env: List<&2, KTerm>
  for +book: List<&2, KDef>
  KTerm

@unsafe
def f_scope(t, env, book):
  f_choose(KTerm, f_eq(tg(t), "Call"), u => f_scope_call(t, env, book), u => f_choose(KTerm, f_eq(tg(t), "TemplateArg"), u => kt("Error", "~ is only valid in a named template call", 0, 0, Nil{}), u => f_scope_lower(t, env, book)))
