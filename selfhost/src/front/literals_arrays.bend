# Arrays, indexing, literal conversion and annotated operator namespaces.

law f_contains:
  for +s: String
  for +c: Char
  Bool

law f_float:
  for +s: String
  KTerm

law f_float_read:
  for +m: Maybe<&2, F32>
  KTerm

law f_array:
  for +ts: List<&2, FToken>
  FParsed

law f_array_first:
  for +p: FParsed
  FParsed

law f_array_type:
  for +n: KTerm
  for +p: FParsed
  FParsed

law f_array_size:
  for +n: KTerm
  for +ty: KTerm
  for +count: Bool
  for +p: FParsed
  FParsed

law f_array_depth:
  for +size: KTerm
  KTerm

law f_power_depth:
  for +s: String
  for +n: U32
  KTerm

law f_power_bits:
  for +n: U32
  for +d: U32
  KTerm

law f_index:
  for +n: KTerm
  for +p: FParsed
  for +min: U32
  FParsed

law f_index_value:
  for +n: KTerm
  for +idx: KTerm
  for +p: FParsed
  for +min: U32
  FParsed

law f_nat_extend:
  for +a: KTerm
  for +b: KTerm
  KTerm

law f_namespace:
  for +t: KTerm
  for +ty: KTerm
  KTerm

@unsafe
def f_contains(s, c):
  f_choose(Bool, String.is_empty(s), u => False{}, u => Char.is_eq(f_head(s), c) || f_contains(f_tail(s), c))

@unsafe
def f_float(s):
  f_float_read(F32.read(s))

@unsafe
def f_float_read(m):
  match m:
    case None{}:
      kt("Error", "invalid f32 literal", 0, 0, Nil{})
    case Some{v}:
      f_float_bits(F32.bits(v))

@unsafe
def f_array(ts):
  f_choose(FParsed, f_eq(f_tx(ts), ";"), u => f_err(ts, "expected term; a list does not use semicolon separators"), u => f_choose(FParsed, f_eq(f_tx(ts), "]"), u => FParsed{kt("Ctr", "Nil", 0, 1, Nil{}), f_tl(ts)}, u => f_array_first(f_expr(ts, 0))))

@unsafe
def f_array_first(p):
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_array_type(n, f_expr(f_tl(ts), 12)), u => f_list(f_args(f_choose(List<&2, FToken>, f_eq(f_tx(ts), ","), u => f_tl(ts), u => ts), "]", [n]))))

@unsafe
def f_array_type(n, p):
  match p:
    case FParsed{+ty, +ts}:
      +rest = f_space(ts)
      f_choose(FParsed, f_eq(tg(ty), "Error"), u => FParsed{ty, ts}, u => f_choose(FParsed, f_eq(f_tx(rest), "*") || f_eq(f_tx(rest), "^"), u => f_array_size(n, ty, f_eq(f_tx(rest), "*"), f_expr(f_tl(rest), 0)), u => fpe_error(rest, "expected * or ^ after array element type", "'^'")))

@unsafe
def f_array_size(n, ty, count, p):
  match p:
    case FParsed{+size, +ts}:
      f_choose(FParsed, f_eq(tg(size), "Error"), u => FParsed{size, ts}, u => f_expect(FParsed{f_app(ref("Array.new"), [ty, f_choose(KTerm, count, u => f_array_depth(size), u => size), f_namespace(n, ty)]), f_space(ts)}, "]"))

@unsafe
def f_array_depth(size):
  f_choose(KTerm, f_eq(tg(size), "Literal"), u => f_power_depth(nm(size), 0), u => kt("Error", "array count must be a literal power of two", 0, 0, Nil{}))

@unsafe
def f_power_depth(s, n):
  f_choose(KTerm, String.is_empty(s) || f_eq(s, "n"), u => f_power_bits(n, 0), u => f_choose(KTerm, Char.is_digit(f_head(s)), u => f_power_depth(f_tail(s), U32.add(U32.mul(n, 10), U32.sub(Char.to_u32(f_head(s)), 48))), u => kt("Error", "array count must be a literal power of two", 0, 0, Nil{})))

@unsafe
def f_power_bits(n, d):
  f_choose(KTerm, U32.is_eq(n, 1), u => f_nat(d), u => f_choose(KTerm, U32.is_eq(n, 0) || U32.is_eq(U32.and(n, 1), 1), u => kt("Error", "array count must be a positive power of two", 0, 0, Nil{}), u => f_power_bits(U32.shrn(n, 1n), U32.add(d, 1))))

@unsafe
def f_index(n, p, min):
  match p:
    case FParsed{idx, +ts}:
      f_choose(FParsed, f_eq(f_tx(ts), "<-"), u => f_index_value(n, idx, f_expr(f_tl(ts), 2), min), u => f_grow(FParsed{f_app(ref("Array.get"), [ref("U32"), n, f_namespace(idx, ref("U32"))]), ts}, min))

@unsafe
def f_index_value(n, idx, p, min):
  match p:
    case FParsed{v, ts}:
      f_grow(FParsed{f_choose(KTerm, f_eq(tg(n), "Ref"), u => kt("Write", nm(n), ix(n), 1, [f_app(ref("Array.set"), [ref("U32"), n, f_namespace(idx, ref("U32")), v])]), u => f_app(ref("Array.set"), [ref("U32"), n, f_namespace(idx, ref("U32")), v])), ts}, min)

@unsafe
def f_nat_extend(a, b):
  f_choose(KTerm, f_eq(tg(a), "Ctr") && f_eq(nm(a), "Zero"), u => b, u => f_choose(KTerm, f_eq(tg(a), "Ctr") && f_eq(nm(a), "Succ"), u => kt("Ctr", "Succ", 0, 1, [f_nat_extend(kid(a, 0), b)]), u => f_app(ref("Nat.add"), [a, b])))

@unsafe
def f_namespace(t, ty):
  f_choose(KTerm, f_eq(tg(t), "Local") || f_eq(tg(t), "Parallel"), u => kt(tg(t), nm(t), ix(t), qt(t), [kid(t, 0), kid(t, 1), f_namespace(kid(t, 2), ty)]), u => f_choose(KTerm, f_eq(tg(t), "Ref") && Char.is_eq(f_head(nm(t)), '.'), u => ref(nm(f_namespace_head(ty)) ++ nm(t)), u => f_choose(KTerm, (f_eq(tg(t), "App") || f_eq(tg(t), "Call")) && f_namespace_operator(f_namespace_head(t)), u => KTerm{tg(t), nm(t), ix(t), qt(t), f_namespace_terms(ks(t), ty), rm(t)}, u => t)))


law f_pattern_literal:
  for +s: String
  KTerm

law f_pattern_number:
  for +s: String
  for +n: U32
  U32

law f_nat_pattern:
  for +n: U32
  KTerm

@unsafe
def f_pattern_literal(s):
  f_choose(KTerm, String.ends_with(s, "n"), u => f_nat_pattern(f_pattern_number(s, 0)), u => f_literal(s))

@unsafe
def f_pattern_number(s, n):
  f_choose(U32, f_eq(s, "n") || String.is_empty(s), u => n, u => f_pattern_number(f_tail(s), U32.add(U32.mul(n, 10), U32.sub(Char.to_u32(f_head(s)), 48))))

@unsafe
def f_nat_pattern(n):
  f_choose(KTerm, U32.is_eq(n, 0), u => kt("Ctr", "Zero", 0, 1, Nil{}), u => kt("Ctr", "Succ", 0, 1, [f_nat_pattern(U32.sub(n, 1))]))


law f_namespace_head:
  for +t: KTerm
  KTerm

law f_namespace_operator:
  for +head: KTerm
  Bool

law f_namespace_terms:
  for +terms: List<&2, KTerm>
  for +ty: KTerm
  List<&2, KTerm>

@unsafe
def f_namespace_head(t):
  f_choose(KTerm, f_eq(tg(t), "App") || f_eq(tg(t), "Call"), u => f_namespace_head(kid(t, 0)), u => t)

@unsafe
def f_namespace_operator(head):
  f_eq(tg(head), "Ref") && (Char.is_eq(f_head(nm(head)), '.') || f_eq(nm(head), "Bool.and") || f_eq(nm(head), "Bool.or") || f_eq(nm(head), "String.append"))

@unsafe
def f_namespace_terms(terms, ty):
  match terms:
    case Nil{}:
      Nil{}
    case Con{term, rest}:
      Con{f_namespace(term, ty), f_namespace_terms(rest, ty)}
