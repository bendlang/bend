import Base

# Exact IR prefix validation for the host cache. Never accepts a changed prefix.
law exact_names_empty:
  for +b: List<&2, String>
  Bool

law exact_names_head:
  for +h: String
  for +rest: List<&2, String>
  for +b: List<&2, String>
  Bool

law exact_terms:
  for +a: List<&2, KTerm>
  for +b: List<&2, KTerm>
  Bool

law exact_terms_head:
  for +h: KTerm
  for +rest: List<&2, KTerm>
  for +b: List<&2, KTerm>
  Bool

law exact_defs:
  for +a: List<&2, KDef>
  for +b: List<&2, KDef>
  Bool

law exact_defs_head:
  for +h: KDef
  for +rest: List<&2, KDef>
  for +b: List<&2, KDef>
  Bool

law exact_prefix_head:
  for +book: List<&2, KDef>
  for +h: KDef
  for +rest: List<&2, KDef>
  Bool

@unsafe
def exact_names(
  +a: List<&2, String>,
  +b: List<&2, String>,
) -> Bool:
  match a:
    case Nil{}:
      exact_names_empty(b)
    case Con{h, rest}:
      exact_names_head(h, rest, b)

@unsafe
def exact_names_empty(b):
  match b:
    case Nil{}:
      True{}
    case Con{h, rest}:
      False{}

@unsafe
def exact_names_head(h, rest, b):
  match b:
    case Nil{}:
      False{}
    case Con{x, xs}:
      String.eq(h, x) && exact_names(rest, xs)

@unsafe
def exact_term(
  +a: KTerm,
  +b: KTerm,
) -> Bool:
  kc(Bool, core_literal(a),
    u => core_literal(b) && core_literal_same(a, b),
    u => Bool.not(core_literal(b)) && String.eq(tg(a), tg(b)) && String.eq(nm(a), nm(b)) && U32.is_eq(ix(a), ix(b)) && U32.is_eq(qt(a), qt(b)) && Bool.not(Bool.xor(k_quantity_present(a), k_quantity_present(b))) && exact_terms(ks(a), ks(b)) && exact_names(rm(a), rm(b)))

@unsafe
def exact_terms(a, b):
  match a:
    case Nil{}:
      U32.is_eq(terms_len(b), 0)
    case Con{h, rest}:
      exact_terms_head(h, rest, b)

@unsafe
def exact_terms_head(h, rest, b):
  match b:
    case Nil{}:
      False{}
    case Con{x, xs}:
      exact_term(h, x) && exact_terms(rest, xs)

@unsafe
def exact_def(
  +a: KDef,
  +b: KDef,
) -> Bool:
  String.eq(dn(a), dn(b)) && String.eq(dk(a), dk(b)) && U32.is_eq(da(a), da(b)) && U32.is_eq(dx(a), dx(b)) && Bool.not(Bool.xor(db(a), db(b))) && Bool.not(Bool.xor(du(a), du(b))) && exact_term(dt(a), dt(b)) && exact_term(dv(a), dv(b)) && exact_defs(dc(a), dc(b))

@unsafe
def exact_defs(a, b):
  match a:
    case Nil{}:
      defs_empty(b)
    case Con{h, rest}:
      exact_defs_head(h, rest, b)

@unsafe
def exact_defs_head(h, rest, b):
  match b:
    case Nil{}:
      False{}
    case Con{x, xs}:
      exact_def(h, x) && exact_defs(rest, xs)

@unsafe
def exact_prefix(
  +book: List<&2, KDef>,
  +prefix: List<&2, KDef>,
) -> Bool:
  match prefix:
    case Nil{}:
      True{}
    case Con{h, rest}:
      exact_prefix_head(book, h, rest)

@unsafe
def exact_prefix_head(book, h, rest):
  match book:
    case Nil{}:
      False{}
    case Con{x, xs}:
      exact_def(x, h) && exact_prefix(xs, rest)

@unsafe
def check_from_exact_prefix(
  +book: List<&2, KDef>,
  +validated: List<&2, KDef>,
) -> String:
  dg_result_error(check_book_diagnostic_from_exact_prefix(book, validated, Nil{}))

