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
  for +origin: KTerm
  FFlatten

law ff_column:
  for +h: KTerm
  for +hs: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +vars: List<&2, KTerm>
  for +next: U32
  for +origin: KTerm
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
  for +origin: KTerm
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
  for +origin: KTerm
  FFlatten

law ff_hit_done:
  for +h: KTerm
  for +hs: List<&2, KTerm>
  for +rows: List<&2, KTerm>
  for +v: KTerm
  for +vs: List<&2, KTerm>
  for +c: KTerm
  for +r: FFlatten
  for +origin: KTerm
  FFlatten

law ff_miss_done:
  for +c: KTerm
  for +hit: KTerm
  for +r: FFlatten
  for +origin: KTerm
  FFlatten

@unsafe
def ff_flat(
  +t: KTerm,
  +vars: List<&2, KTerm>,
  +next: U32,
) -> FFlatten:
  f_choose(FFlatten, ff_failed(t), u => FFlatten{t, next}, u => f_choose(FFlatten, f_eq(tg(t), "Match"), u => ff_match(ks(kid(t, 0)), f_tail_terms(ks(t)), vars, next, t), u => f_choose(FFlatten, f_eq(tg(t), "Local"), u => ff_local(t, vars, next), u => f_choose(FFlatten, f_eq(tg(t), "Parallel"), u => ff_parallel(t, vars, ff_flat(kid(t, 2), ks(kid(t, 0)), next)), u => FFlatten{f_lbind(vars, t), next}))))

@unsafe
def ff_local(t, vars, next):
  f_choose(FFlatten, f_eq(tg(kid(t, 0)), "Ctr"), u => ff_match([kid(t, 1)], [kt("Row", "", 0, 1, [kt("Patterns", "", 0, 1, [kid(t, 0)]), kid(t, 2)])], vars, next, kid(t, 1)), u => ff_let(t, vars, ff_flat(kid(t, 2), [kid(t, 0)], next)))

@unsafe
def ff_let(t, vars, r):
  match r:
    case FFlatten{+body, next}:
      f_choose(FFlatten, ff_failed(body), u => FFlatten{body, next}, u => FFlatten{f_choose(KTerm, f_eq(tg(body), "Lam"), u => f_lbind(vars, kt_span("Let", "", 0, 1, [kt_span("Bind", nm(kid(t, 0)), ix(kid(t, 0)), qt(kid(t, 0)), [kid(t, 1)], kb(kid(t, 0)), ke(kid(t, 0))), kid(body, 0)], kb(t), ke(t))), u => fpe_message_at(kid(t, 0), "a match cannot scrutinize a local binding", "a parameter or field scrutinee (a match cannot scrutinize a local binder: give it its own def)")), next})

@unsafe
def ff_parallel(t, vars, r):
  match r:
    case FFlatten{body, next}:
      f_choose(FFlatten, ff_failed(body), u => FFlatten{body, next}, u => FFlatten{f_lbind(vars, kt_span("Let", "", 0, 1, norm_join(f_parallel_binds(ks(kid(t, 0)), ks(kid(t, 1))), [f_unlamb(body, terms_len(ks(kid(t, 0))))]), kb(t), ke(t))), next})

@unsafe
def ff_match(heads, rows, vars, next, origin):
  match heads:
    case Nil{}:
      f_choose(FFlatten, U32.is_eq(terms_len(rows), 0), u => FFlatten{kt_span("Efq", "", 0, 0, Nil{}, kb(origin), ke(origin)), next}, u => ff_flat(kid(terms_at(rows, 0), 1), vars, next))
    case Con{+h, hs}:
      f_choose(FFlatten, f_eq(tg(f_first_ctor(rows)), "Absent") && U32.is_gt(terms_len(rows), 0) && ff_variable(h) && f_has_id(vars, ix(h)), u => ff_match(hs, f_var_rows(rows, h), f_mark_vars(vars, ix(h), f_mark_rows(rows, qt(h))), next, origin), u => ff_column(h, hs, rows, vars, next, origin))

@unsafe
def ff_column(h, hs, rows, vars, next, origin):
  match vars:
    case Nil{}:
      FFlatten{f_match_error(h, origin), next}
    case Con{+v, vs}:
      f_choose(FFlatten, ff_variable(h) && U32.is_eq(ix(h), ix(v)), u => ff_split(h, hs, rows, v, vs, f_first_ctor(rows), next, origin), u => ff_lam(v, ff_match(Con{h, hs}, rows, vs, next, origin)))

@unsafe
def ff_lam(v, r):
  match r:
    case FFlatten{body, next}:
      f_choose(FFlatten, ff_failed(body), u => FFlatten{body, next}, u => FFlatten{k_lam(nm(v), ix(v), qt(v), [body], kb(v), ke(v), True{}), next})

@unsafe
def ff_split(h, hs, rows, v, vs, c, next, origin):
  f_choose(FFlatten, f_eq(tg(c), "Absent"), u => FFlatten{kt_span("Efq", "", 0, 0, Nil{}, kb(origin), ke(origin)), next}, u => ff_fields_done(h, hs, rows, v, vs, c, ff_fields(ks(c), f_mark_rows(rows, qt(v)), next), origin))

@unsafe
def ff_fields(ps, q, next):
  match ps:
    case Nil{}:
      FFields{Nil{}, next}
    case Con{+p, rest}:
      f_choose(FFields, f_eq(tg(p), "Var"), u => ff_field_cons(kt_span("Var", nm(p), ix(p), f_choose(U32, U32.is_eq(q, 2), u => 2, u => qt(p)), Nil{}, kb(p), ke(p)), ff_fields(rest, q, next)), u => ff_field_cons(kt_span("Var", "_" ++ U32.show(next), U32.add(2147483648, next), q, Nil{}, kb(p), ke(p)), ff_fields(rest, q, U32.add(next, 1))))

@unsafe
def ff_field_cons(p, r):
  match r:
    case FFields{fields, next}:
      FFields{Con{p, fields}, next}

@unsafe
def ff_fields_done(h, hs, rows, v, vs, c, r, origin):
  match r:
    case FFields{+fields, next}:
      ff_hit_done(h, hs, rows, v, vs, c, ff_match(norm_join(fields, hs), f_hit_rows(rows, c, fields, v), norm_join(fields, vs), next, origin), origin)

@unsafe
def ff_hit_done(h, hs, rows, v, vs, c, r, origin):
  match r:
    case FFlatten{hit, next}:
      f_choose(FFlatten, ff_failed(hit), u => FFlatten{hit, next}, u => ff_miss_done(c, hit, ff_match(Con{h, hs}, f_miss_rows(rows, nm(c)), Con{v, vs}, next, origin), origin))

@unsafe
def ff_miss_done(c, hit, r, origin):
  match r:
    case FFlatten{miss, next}:
      f_choose(FFlatten, ff_failed(miss), u => FFlatten{miss, next}, u => FFlatten{kt_span("Mat", nm(c), 0, 1, [hit, miss], kb(c), ke(c)), next})

@unsafe
def ff_failed(+term: KTerm) -> Bool:
  String.eq(tg(term), "Error")

@unsafe
def ff_variable(+term: KTerm) -> Bool:
  String.eq(tg(term), "Var")
