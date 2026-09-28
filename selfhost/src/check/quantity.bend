import Base

# A failed corresponding field must not be searched again as a proper subterm.
type KDescent is Data:
  KDescent{order: U32, bad: U32}

law descend_go:
  for +a: KTerm
  for +p: KTerm
  U32

law descend_fields:
  for +a: List<&2, KTerm>
  for +p: List<&2, KTerm>
  for +ord: U32
  for +index: U32
  KDescent

law descend_field:
  for +a: List<&2, KTerm>
  for +p: List<&2, KTerm>
  for +ord: U32
  for +index: U32
  for +field: U32
  KDescent

law terms_tail:
  for +ts: List<&2, KTerm>
  List<&2, KTerm>

law descend_ctr:
  for +a: KTerm
  for +p: KTerm
  for +result: KDescent
  U32

law descend_sub:
  for +a: KTerm
  for +ps: List<&2, KTerm>
  for +bad: U32
  for +index: U32
  U32

law descend_step:
  for +ord: U32
  for +qs: List<&2, KTerm>
  for +args: List<&2, KTerm>
  for +cols: List<&2, KTerm>
  Bool

@unsafe
def qadd(
  +a: U32,
  +b: U32,
) -> U32:
  kc(U32, U32.is_eq(a, 0), u => b, u => kc(U32, U32.is_eq(b, 0), u => a, u => 2))

@unsafe
def qjoin(
  +a: U32,
  +b: U32,
) -> U32:
  kc(U32, U32.is_gt(a, b), u => a, u => b)

@unsafe
def qdem(
  +q: U32,
  +d: U32,
) -> U32:
  kc(U32, U32.is_eq(q, 0), u => 0, u => d)

@unsafe
def uses_get(
  +xs: List<&2, KTerm>,
  +id: U32,
) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{h, t}:
      kc(U32, U32.is_eq(ix(h), id), u => qt(h), u => uses_get(t, id))

@unsafe
def uses_del(
  +xs: List<&2, KTerm>,
  +id: U32,
) -> List<&2, KTerm>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      kc(List<&2, KTerm>, U32.is_eq(ix(h), id), u => uses_del(t, id), u => Con{h, uses_del(t, id)})

@unsafe
def uses_merge(
  +a: List<&2, KTerm>,
  +b: List<&2, KTerm>,
  +join: Bool,
) -> List<&2, KTerm>:
  match a:
    case Nil{}:
      b
    case Con{h, t}:
      Con{kt("Use", "", ix(h), kc(U32, join, u => qjoin(qt(h), uses_get(b, ix(h))), u => qadd(qt(h), uses_get(b, ix(h)))), Nil{}), uses_merge(t, uses_del(b, ix(h)), join)}

@unsafe
def strip(
  +t: KTerm,
) -> KTerm:
  core_force(t)

@unsafe
def descend(
  +q: U32,
  +a: KTerm,
  +p: KTerm,
) -> U32:
  kc(U32, U32.is_eq(q, 0), u => 1, u => descend_go(strip(a), strip(p)))

@unsafe
def descend_go(a, p):
  kc(U32, core_nat(a) && String.eq(tg(p), "Ctr"), u => descend_go(core_nat_step(a), p), u =>
  kc(U32, String.eq(tg(p), "Var"),
    u => kc(U32, String.eq(tg(a), "Var") && U32.is_eq(ix(a), ix(p)), u => 1, u => 2),
    u => kc(U32, String.eq(tg(p), "Ctr"),
      u => descend_ctr(a, p, kc(KDescent, String.eq(tg(a), "Ctr") && String.eq(nm(a), nm(p)) && U32.is_eq(terms_len(ks(a)), terms_len(ks(p))), u => descend_fields(ks(a), ks(p), 1, 0), u => KDescent{2, 4294967295})),
      u => 2)))

@unsafe
def descend_fields(a, p, ord, index):
  match a:
    case Nil{}:
      KDescent{ord, 4294967295}
    case Con{h, t}:
      descend_field(t, terms_tail(p), ord, index, descend(1, h, terms_at(p, 0)))

@unsafe
def descend_field(a, p, ord, index, field):
  kc(KDescent, U32.is_eq(field, 2), u => KDescent{2, index}, u => descend_fields(a, p, kc(U32, U32.is_eq(field, 1), u => ord, u => field), U32.inc(index)))

@unsafe
def terms_tail(ts):
  match ts:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      t

@unsafe
def descend_ctr(a, p, result):
  match result:
    case KDescent{ord, bad}:
      kc(U32, U32.is_eq(ord, 2), u => descend_sub(a, ks(p), bad, 0), u => ord)

@unsafe
def descend_sub(a, ps, bad, index):
  match ps:
    case Nil{}:
      2
    case Con{h, t}:
      kc(U32, U32.is_eq(index, bad), u => descend_sub(a, t, bad, U32.inc(index)), u => kc(U32, U32.is_eq(descend(1, a, h), 2), u => descend_sub(a, t, bad, U32.inc(index)), u => 0))

@unsafe
def descend_spine(
  +qs: List<&2, KTerm>,
  +args: List<&2, KTerm>,
  +cols: List<&2, KTerm>,
) -> Bool:
  match cols:
    case Nil{}:
      False{}
    case Con{h, t}:
      descend_step(descend(qt(terms_at(qs, 0)), terms_at(args, 0), h), terms_tail(qs), terms_tail(args), t)

@unsafe
def descend_step(ord, qs, args, cols):
  kc(Bool, U32.is_eq(ord, 0), u => True{}, u => kc(Bool, U32.is_eq(ord, 1), u => descend_spine(qs, args, cols), u => False{}))
