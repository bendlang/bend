# Name resolution, literal expansion, and ordered pattern-matrix compilation.

law f_env:
  for +name: String
  for +env: List<&2, KTerm>
  KTerm

law f_tail_terms:
  for +xs: List<&2, KTerm>
  List<&2, KTerm>

law f_subs:
  for +ts: List<&2, KTerm>
  for +id: U32
  for +v: KTerm
  List<&2, KTerm>

law f_first_ctor:
  for +rows: List<&2, KTerm>
  KTerm

law f_has_id:
  for +vars: List<&2, KTerm>
  for +id: U32
  Bool

law f_var_rows:
  for +rows: List<&2, KTerm>
  for +v: KTerm
  List<&2, KTerm>

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
def f_sub(
  +t: KTerm,
  +id: U32,
  +v: KTerm,
) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "Var") && U32.is_eq(ix(t), id),
    u => f_choose(KTerm, U32.is_eq(kb(v), 0) && U32.is_eq(ke(v), 0) && Bool.not(f_eq(tg(v), "FUnboundVar")), u => k_with_span(v, kb(t), ke(t)), u => v),
    u => k_with_children(t, f_subs(ks(t), id, v)))

@unsafe
def f_subs(ts, id, v):
  match ts:
    case Nil{}:
      Nil{}
    case Con{t, rest}:
      Con{f_sub(t, id, v), f_subs(rest, id, v)}

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
def f_var_rows(rows, v):
  match rows:
    case Nil{}:
      Nil{}
    case Con{+r, rs}:
      Con{kt("Row", "", 0, qt(r), [kt("Patterns", "", 0, 1, f_tail_terms(ks(kid(r, 0)))), f_choose(KTerm, U32.is_eq(qt(r), 0), u => kid(r, 1), u => f_pattern_sub(kid(r, 1), ix(f_rowpat(r)), v))]), f_var_rows(rs, v)}

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

