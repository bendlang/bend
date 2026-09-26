# Stateful pattern flattening preserves the upstream fresh-field order.
# The parser allocation count resets at each declaration; core alpha-renaming
# subsequently makes IDs global without changing these user-visible names.
type FFlatten is Data:
  FFlatten{+term: KTerm, next: U32}

type FFields is Data:
  FFields{+fields: List<&2, KTerm>, next: U32}

law ff_local:
  for +t: KTerm
  for +vars: List<&2, KTerm>
  for +next: U32
  FFlatten

law ff_let:
  for +t: KTerm
  for +vars: List<&2, KTerm>
  for +r: FFlatten
  FFlatten

law ff_parallel:
  for +t: KTerm
  for +vars: List<&2, KTerm>
  for +r: FFlatten
  FFlatten

law ff_match:
  for +heads: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +vars: List<&2, KTerm>
  for +next: U32
  FFlatten

law ff_column:
  for +h: KTerm
  for +hs: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +vars: List<&2, KTerm>
  for +next: U32
  FFlatten

law ff_lam:
  for +v: KTerm
  for +r: FFlatten
  FFlatten

law ff_split:
  for +h: KTerm
  for +hs: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +v: KTerm
  for +vs: List<&2, KTerm>
  for +c: KTerm
  for +next: U32
  FFlatten

law ff_fields:
  for +ps: List<&2, KTerm>
  for +q: U32
  for +next: U32
  FFields

law ff_field_cons:
  for +p: KTerm
  for +r: FFields
  FFields

law ff_fields_done:
  for +h: KTerm
  for +hs: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +v: KTerm
  for +vs: List<&2, KTerm>
  for +c: KTerm
  for +r: FFields
  FFlatten

law ff_hit_done:
  for +h: KTerm
  for +hs: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +v: KTerm
  for +vs: List<&2, KTerm>
  for +c: KTerm
  for +r: FFlatten
  FFlatten

law ff_miss_done:
  for +c: KTerm
  for +hit: KTerm
  for +r: FFlatten
  FFlatten

law fc_term:
  for +t: KTerm
  for +env: List<&2, KTerm>
  U32

law fc_rows:
  for +rs: List<&2, KTerm>
  for +env: List<&2, KTerm>
  U32

law fc_start:
  for +pars: List<&2, KTerm>
  for +ty: KTerm
  for +body: KTerm
  for +filled: Bool
  U32

@unsafe
def ff_term(
  +r: FFlatten,
) -> KTerm:
  match r:
    case FFlatten{t, next}:
      t

@unsafe
def ff_flat(
  +t: KTerm,
  +vars: List<&2, KTerm>,
  +next: U32,
) -> FFlatten:
  f_choose(FFlatten, f_eq(tg(t), "Match"), u => ff_match(ks(kid(t, 0)), f_tail_terms(ks(t)), vars, next), u => f_choose(FFlatten, f_eq(tg(t), "Local"), u => ff_local(t, vars, next), u => f_choose(FFlatten, f_eq(tg(t), "Parallel"), u => ff_parallel(t, vars, ff_flat(kid(t, 2), ks(kid(t, 0)), next)), u => FFlatten{f_lbind(vars, t), next})))

@unsafe
def ff_local(t, vars, next):
  f_choose(FFlatten, f_eq(tg(kid(t, 0)), "Ctr"), u => ff_match([kid(t, 1)], [kt("Row", "", 0, 1, [kt("Patterns", "", 0, 1, [kid(t, 0)]), kid(t, 2)])], vars, next), u => ff_let(t, vars, ff_flat(kid(t, 2), [kid(t, 0)], next)))

@unsafe
def ff_let(t, vars, r):
  match r:
    case FFlatten{+body, next}:
      FFlatten{f_choose(KTerm, f_eq(tg(body), "Lam"), u => f_lbind(vars, kt("Let", "", 0, 1, [kt("Bind", nm(kid(t, 0)), ix(kid(t, 0)), qt(kid(t, 0)), [kid(t, 1)]), kid(body, 0)])), u => kt("Error", "a match cannot scrutinize a local binding", 0, 0, Nil{})), next}

@unsafe
def ff_parallel(t, vars, r):
  match r:
    case FFlatten{body, next}:
      FFlatten{f_lbind(vars, kt("Let", "", 0, 1, norm_join(f_parallel_binds(ks(kid(t, 0)), ks(kid(t, 1))), [f_unlamb(body, terms_len(ks(kid(t, 0))))]))), next}

@unsafe
def ff_match(heads, rows, vars, next):
  match heads:
    case Nil{}:
      f_choose(FFlatten, U32.is_eq(terms_len(rows), 0), u => FFlatten{atom("Efq"), next}, u => ff_flat(kid(terms_at(rows, 0), 1), vars, next))
    case Con{+h, hs}:
      f_choose(FFlatten, f_eq(tg(f_first_ctor(rows)), "Absent") && U32.is_gt(terms_len(rows), 0) && f_has_id(vars, ix(h)), u => ff_match(hs, f_var_rows(rows, h), f_mark_vars(vars, ix(h), f_mark_rows(rows, qt(h))), next), u => ff_column(h, hs, rows, vars, next))

@unsafe
def ff_column(h, hs, rows, vars, next):
  match vars:
    case Nil{}:
      FFlatten{kt("Error", "match requires an unconsumed parameter or constructor field", 0, 0, Nil{}), next}
    case Con{+v, vs}:
      f_choose(FFlatten, U32.is_eq(ix(h), ix(v)), u => ff_split(h, hs, rows, v, vs, f_first_ctor(rows), next), u => ff_lam(v, ff_match(Con{h, hs}, rows, vs, next)))

@unsafe
def ff_lam(v, r):
  match r:
    case FFlatten{body, next}:
      FFlatten{kt("Lam", nm(v), ix(v), qt(v), [body]), next}

@unsafe
def ff_split(h, hs, rows, v, vs, c, next):
  f_choose(FFlatten, f_eq(tg(c), "Absent"), u => FFlatten{atom("Efq"), next}, u => ff_fields_done(h, hs, rows, v, vs, c, ff_fields(ks(c), f_mark_rows(rows, qt(v)), next)))

@unsafe
def ff_fields(ps, q, next):
  match ps:
    case Nil{}:
      FFields{Nil{}, next}
    case Con{+p, rest}:
      f_choose(FFields, f_eq(tg(p), "Var"), u => ff_field_cons(kt("Var", nm(p), ix(p), f_choose(U32, U32.is_eq(q, 2), u => 2, u => qt(p)), Nil{}), ff_fields(rest, q, next)), u => ff_field_cons(kt("Var", "_" ++ U32.show(next), U32.add(2147483648, next), q, Nil{}), ff_fields(rest, q, U32.add(next, 1))))

@unsafe
def ff_field_cons(p, r):
  match r:
    case FFields{fields, next}:
      FFields{Con{p, fields}, next}

@unsafe
def ff_fields_done(h, hs, rows, v, vs, c, r):
  match r:
    case FFields{+fields, next}:
      ff_hit_done(h, hs, rows, v, vs, c, ff_match(norm_join(fields, hs), f_hit_rows(rows, c, fields, v), norm_join(fields, vs), next))

@unsafe
def ff_hit_done(h, hs, rows, v, vs, c, r):
  match r:
    case FFlatten{hit, next}:
      ff_miss_done(c, hit, ff_match(Con{h, hs}, f_miss_rows(rows, nm(c)), Con{v, vs}, next))

@unsafe
def ff_miss_done(c, hit, r):
  match r:
    case FFlatten{miss, next}:
      FFlatten{kt("Mat", nm(c), 0, 1, [hit, miss]), next}

@unsafe
def fc_ref(
  +name: String,
  +env: List<&2, KTerm>,
) -> U32:
  f_choose(U32, f_contains(name, '.') || Bool.not(f_eq(tg(f_env(name, env)), "Absent")), u => 0, u => 1)

@unsafe
def fc_bind(
  +v: KTerm,
  +env: List<&2, KTerm>,
) -> List<&2, KTerm>:
  f_choose(List<&2,KTerm>, f_eq(nm(v), "_"), u => env, u => Con{v, env})

@unsafe
def fc_binders(
  +ps: List<&2, KTerm>,
) -> List<&2, KTerm>:
  match ps:
    case Nil{}:
      Nil{}
    case Con{+p, rest}:
      f_choose(List<&2,KTerm>, f_eq(tg(p), "Ref") || f_eq(tg(p), "Var"), u => fc_bind(p, fc_binders(rest)), u => norm_join(fc_binders(ks(p)), fc_binders(rest)))

@unsafe
def fc_bind_count(
  +ps: List<&2, KTerm>,
) -> U32:
  match ps:
    case Nil{}:
      0
    case Con{+p, rest}:
      U32.add(f_choose(U32, f_eq(tg(p), "Ref") || f_eq(tg(p), "Var"), u => 1, u => fc_bind_count(ks(p))), fc_bind_count(rest))

@unsafe
def fc_terms(
  +ts: List<&2, KTerm>,
  +env: List<&2, KTerm>,
) -> U32:
  match ts:
    case Nil{}:
      0
    case Con{t, rest}:
      U32.add(fc_term(t, env), fc_terms(rest, env))

@unsafe
def fc_term(t, env):
  f_choose(U32, f_eq(tg(t), "Ref"), u => fc_ref(nm(t), env),
    u => f_choose(U32, f_eq(tg(t), "ADT"), u => U32.add(fc_ref(nm(t), env), fc_terms(ks(t), env)),
    u => f_choose(U32, f_eq(tg(t), "All"), u => U32.add(1, U32.add(fc_term(kid(t, 0), env), fc_term(kid(t, 1), fc_bind(t, env)))),
    u => f_choose(U32, f_eq(tg(t), "Lam"), u => U32.add(1, U32.add(fc_ref(nm(t), env), fc_term(kid(t, 0), fc_bind(t, env)))),
    u => f_choose(U32, f_eq(tg(t), "Match"), u => U32.add(fc_terms(ks(kid(t, 0)), env), fc_rows(f_tail_terms(ks(t)), env)),
    u => f_choose(U32, f_eq(tg(t), "Local"), u => U32.add(f_choose(U32, U32.is_eq(qt(kid(t, 0)), 0), u => 0, u => fc_term(kid(t, 0), env)), U32.add(fc_term(kid(t, 1), env), U32.add(fc_bind_count([kid(t, 0)]), fc_term(kid(t, 2), norm_join(fc_binders([kid(t, 0)]), env))))),
    u => f_choose(U32, f_eq(tg(t), "Parallel"), u => U32.add(fc_terms(ks(kid(t, 0)), env), U32.add(fc_terms(ks(kid(t, 1)), env), U32.add(fc_bind_count(ks(kid(t, 0))), fc_term(kid(t, 2), norm_join(fc_binders(ks(kid(t, 0))), env))))),
    u => f_choose(U32, f_eq(tg(t), "Mat"), u => U32.add(fc_ref(nm(t), env), fc_terms(ks(t), env)),
    u => fc_terms(ks(t), env)))))))))

@unsafe
def fc_rows(rs, env):
  match rs:
    case Nil{}:
      0
    case Con{+r, rest}:
      U32.add(fc_terms(ks(kid(r, 0)), env), U32.add(fc_bind_count(ks(kid(r, 0))), U32.add(fc_term(kid(r, 1), norm_join(fc_binders(ks(kid(r, 0))), env)), fc_rows(rest, env))))

@unsafe
def fc_start(pars, ty, body, filled):
  U32.add(f_choose(U32, filled, u => terms_len(pars), u => fc_term(ty, Nil{})), fc_term(body, pars))

