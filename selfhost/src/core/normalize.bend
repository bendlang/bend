import Base

# Weak head evaluation, strong normalization, and definitional conversion.
# Native definitions without equations remain opaque, as in the upstream kernel.
@unsafe
def norm_apply(
  +t: KTerm,
  +args: List<&2, KTerm>,
) -> KTerm:
  match args:
    case Nil{}:
      t
    case Con{h, rest}:
      norm_apply(app(t, h), rest)

@unsafe
def wnf(
  +book: List<&2, KDef>,
  +t: KTerm,
) -> KTerm:
  norm_eval(book, t, Nil{}, 0, atom("Absent"))

law norm_eval:
  for +book: List<&2, KDef>
  for +t: KTerm
  for +args: List<&2, KTerm>
  for +left: U32
  for +fallback: KTerm
  KTerm

@unsafe
def norm_eval_node(
  +book: List<&2, KDef>,
  +t: KTerm,
  +args: List<&2, KTerm>,
  +left: U32,
  +fallback: KTerm,
) -> KTerm:
  kc(KTerm, String.eq(tg(t), "App"), u => norm_eval(book, kid(t, 0), Con{kid(t, 1), args}, left, fallback), u => kc(KTerm, String.eq(tg(t), "Ann"), u => norm_eval(book, kid(t, 0), args, left, fallback), u => kc(KTerm, String.eq(tg(t), "Let"), u => norm_eval(book, norm_let(ks(t)), args, left, fallback), u => kc(KTerm, String.eq(tg(t), "Ref"), u => norm_ref(book, t, args, lookup(book, nm(t))), u => kc(KTerm, String.eq(tg(t), "Min"), u => norm_apply(norm_min(book, kid(t, 0), kid(t, 1)), args), u => kc(KTerm, String.eq(tg(t), "Rwt"), u => kc(KTerm, String.eq(tg(wnf(book, kid(t, 0))), "Rfl"), u => norm_eval(book, kid(t, 2), args, left, fallback), u => norm_apply(t, args)), u => norm_args(book, t, args, left, fallback)))))))
law norm_ref:
  for +book: List<&2, KDef>
  for +t: KTerm
  for +args: List<&2, KTerm>
  for +d: KDef
  KTerm

@unsafe
def norm_ref(book, t, args, d):
  kc(KTerm, String.eq(dk(d), "ADT"), u => kc(KTerm, U32.is_eq(da(d), 0), u => norm_apply(kt("ADT", nm(t), 0, 0, Nil{}), args), u => norm_apply(t, args)), u => kc(KTerm, Bool.and(Bool.not(String.eq(tg(dv(d)), "Absent") || String.eq(tg(dv(d)), "Foreign")), U32.is_le(da(d), terms_len(args))), u => norm_eval(book, dv(d), args, da(d), norm_apply(t, args)), u => norm_apply(t, args)))
law norm_args:
  for +book: List<&2, KDef>
  for +t: KTerm
  for +args: List<&2, KTerm>
  for +left: U32
  for +fallback: KTerm
  KTerm

@unsafe
def norm_args(book, t, args, left, fallback):
  match args:
    case Nil{}:
      t
    case Con{x, rest}:
      kc(KTerm, String.eq(tg(t), "Lam"), u => norm_eval(book, subst(kid(t, 0), ix(t), x), rest, norm_dec(left), fallback), u => kc(KTerm, String.eq(tg(t), "Mat"), u => norm_match(book, t, t, x, wnf(book, x), rest, left, fallback), u => kc(KTerm, Bool.and(String.eq(tg(t), "Efq"), Bool.not(U32.is_eq(left, 0))), u => fallback, u => norm_apply(t, args))))
law norm_dec:
  for +n: U32
  U32

@unsafe
def norm_dec(n):
  kc(U32, U32.is_eq(n, 0), u => 0, u => U32.sub(n, 1))
law norm_match:
  for +book: List<&2, KDef>
  for +arm: KTerm
  for +original: KTerm
  for +raw: KTerm
  for +x: KTerm
  for +args: List<&2, KTerm>
  for +left: U32
  for +fallback: KTerm
  KTerm

@unsafe
def norm_match(book, arm, original, raw, x, args, left, fallback):
  kc(KTerm, String.eq(tg(x), "Ctr"), u => kc(KTerm, String.eq(tg(arm), "Ann"), u => norm_match(book, kid(arm, 0), original, raw, x, args, left, fallback), u => kc(KTerm, String.eq(tg(arm), "Mat"), u => kc(KTerm, String.eq(nm(arm), nm(x)), u => kc(KTerm, U32.is_eq(left, 0), u => norm_eval(book, kid(arm, 0), norm_join(ks(x), args), 0, fallback), u => norm_eval(book, kid(arm, 0), norm_join(ks(x), args), U32.add(norm_dec(left), terms_len(ks(x))), fallback)), u => norm_match(book, kid(arm, 1), original, raw, x, args, left, fallback)), u => kc(KTerm, String.eq(tg(arm), "Efq"), u => norm_stuck(original, raw, args, left, fallback), u => norm_eval(book, arm, Con{x, args}, left, fallback)))), u => norm_stuck(original, raw, args, left, fallback))
law norm_stuck:
  for +t: KTerm
  for +x: KTerm
  for +args: List<&2, KTerm>
  for +left: U32
  for +fallback: KTerm
  KTerm

@unsafe
def norm_stuck(t, x, args, left, fallback):
  kc(KTerm, U32.is_eq(left, 0), u => norm_apply(app(t, x), args), u => fallback)
law norm_min:
  for +book: List<&2, KDef>
  for +a: KTerm
  for +b: KTerm
  KTerm

@unsafe
def norm_min(book, a, b):
  norm_min_left(book, wnf(book, a), b)

law norm_min_left:
  for +book: List<&2, KDef>
  for +a: KTerm
  for +b: KTerm
  KTerm

@unsafe
def norm_min_left(book, a, b):
  kc(KTerm, Bool.and(String.eq(tg(a), "Qua"), U32.is_eq(qt(a), 2)), u => wnf(book, b), u => kc(KTerm, Bool.and(String.eq(tg(a), "Qua"), U32.is_eq(qt(a), 0)), u => a, u => norm_min_right(a, wnf(book, b))))
law norm_min_right:
  for +a: KTerm
  for +b: KTerm
  KTerm

@unsafe
def norm_min_right(a, b):
  kc(KTerm, String.eq(tg(b), "Qua"), u => kc(KTerm, U32.is_eq(qt(b), 2), u => a, u => kc(KTerm, Bool.and(U32.is_eq(qt(b), 1), Bool.not(String.eq(tg(a), "Qua"))), u => kt("Min", "", 0, 0, Con{a, Con{b, Nil{}}}), u => b)), u => kt("Min", "", 0, 0, Con{a, Con{b, Nil{}}}))
@unsafe
def strong(
  +book: List<&2, KDef>,
  +t: KTerm,
) -> KTerm:
  graph_strong(book, t)

@unsafe
def norm_max(
  +a: U32,
  +b: U32,
) -> U32:
  kc(U32, U32.is_le(a, b), u => b, u => a)
@unsafe
def norm_max_term(
  +t: KTerm,
) -> U32:
  norm_max_walk(Con{t, Nil{}}, 0)

law norm_max_book:
  for +book: List<&2, KDef>
  U32

@unsafe
def norm_max_book(book):
  norm_max_defs(book, 0)

@unsafe
def compare(
  +book: List<&2, KDef>,
  +a: KTerm,
  +b: KTerm,
  +le: Bool,
) -> Bool:
  norm_compare(book, a, b, le, U32.add(1, norm_max(norm_book_bound(book), norm_max(norm_max_term(a), norm_max_term(b)))))

law norm_compare:
  for +book: List<&2, KDef>
  for +a: KTerm
  for +b: KTerm
  for +le: Bool
  for +fresh: U32
  Bool

@unsafe
def norm_compare(book, a, b, le, fresh):
  kc(Bool, norm_exact(a, b), u => True{}, u => norm_cmp_loop(book, Con{KNormCmp{a, b, le, fresh}, Nil{}}, Nil{}))

@unsafe
def norm_subset(
  +as: List<&2, String>,
  +bs: List<&2, String>,
) -> Bool:
  match bs:
    case Nil{}:
      True{}
    case Con{h, t}:
      Bool.and(has_name(as, h), norm_subset(as, t))

@unsafe
def norm_removed(
  +as: List<&2, String>,
  +bs: List<&2, String>,
  +le: Bool,
) -> Bool:
  kc(Bool, le, u => norm_subset(as, bs), u => Bool.and(U32.is_eq(norm_names_len(as), norm_names_len(bs)), norm_subset(as, bs)))
law norm_let:
  for +ts: List<&2, KTerm>
  KTerm

@unsafe
def norm_let(ts):
  match ts:
    case Nil{}:
      atom("Absent")
    case Con{h, rest}:
      norm_let_tail(h, rest)

law norm_let_tail:
  for +h: KTerm
  for +rest: List<&2, KTerm>
  KTerm

@unsafe
def norm_let_tail(h, rest):
  match rest:
    case Nil{}:
      h
    case Con{x, xs}:
      subst(norm_let(rest), ix(h), kid(h, 0))


@unsafe
def norm_eval(book, t, args, left, fallback):
  kc(KTerm, String.eq(tg(t), "Var"), u => norm_var(book, t, ks(t), args, left, fallback), u => norm_eval_node(book, t, args, left, fallback))

law norm_var:
  for +book: List<&2, KDef>
  for +t: KTerm
  for +values: List<&2, KTerm>
  for +args: List<&2, KTerm>
  for +left: U32
  for +fallback: KTerm
  KTerm

@unsafe
def norm_var(book, t, values, args, left, fallback):
  match values:
    case Nil{}:
      norm_apply(t, args)
    case Con{h, rest}:
      norm_eval(book, h, args, left, fallback)

law norm_names_len:
  for +names: List<&2, String>
  U32

@unsafe
def norm_names_len(names):
  match names:
    case Nil{}:
      0
    case Con{h, rest}:
      U32.add(1, norm_names_len(rest))

# The book checker computes this immutable bound once per source book. Public
# callers without a stamp retain the complete scan, so fresh IDs stay sound.
law norm_book_bound:
  for +book: List<&2, KDef>
  U32

law norm_bound_found:
  for +book: List<&2, KDef>
  for +stamp: KDef
  U32

@unsafe
def norm_book_bound(book):
  match book:
    case Nil{}:
      0
    case Con{h, rest}:
      kc(U32, String.eq(dk(h), "BookCache"), u => da(h), u => norm_bound_found(book, lookup(book, "$kernel.max-id")))

@unsafe
def norm_bound_found(book, stamp):
  kc(U32, String.eq(dk(stamp), "BookBound"), u => da(stamp), u => norm_max_book(book))

# Strong normalization uses an explicit traversal stack. Each opened binder
# receives a fresh identity even when the same recursive definition unfolds
# repeatedly underneath another copy of its binder.
type KNormFrame is Data:
  KNormFrame{+parent: KTerm, +done: List<&2, KTerm>, +todo: List<&2, KTerm>}

law norm_max_walk:
  for +todo: List<&2, KTerm>
  for +bound: U32
  U32

law norm_max_defs:
  for +todo: List<&2, KDef>
  for +bound: U32
  U32

@unsafe
def norm_max_walk(todo, bound):
  match todo:
    case Nil{}:
      bound
    case Con{h, rest}:
      norm_max_walk(norm_join(ks(h), rest), norm_max(bound, ix(h)))

@unsafe
def norm_max_defs(todo, bound):
  match todo:
    case Nil{}:
      bound
    case Con{h, rest}:
      norm_max_defs(norm_defs_join(dc(h), rest), norm_max(bound, norm_max(norm_max_term(dt(h)), norm_max_term(dv(h)))))

@unsafe
def norm_rebind(
  +t: KTerm,
  +fresh: U32,
) -> KTerm:
  KTerm{tg(t), nm(t), fresh, qt(t), kc(List<&2, KTerm>, String.eq(tg(t), "Lam"), u => Con{subst(kid(t, 0), ix(t), var(nm(t), fresh)), Nil{}}, u => Con{kid(t, 0), Con{subst(kid(t, 1), ix(t), var(nm(t), fresh)), Nil{}}}), rm(t)}

# Syntactic reflexivity precedes evaluation, as pointer reflexivity does in
# upstream. Cell contents are included; different stored values never match.
law norm_exact:
  for +a: KTerm
  for +b: KTerm
  Bool

law norm_exact_lists:
  for +as: List<&2, KTerm>
  for +bs: List<&2, KTerm>
  Bool

law norm_exact_head:
  for +a: KTerm
  for +b: KTerm
  Bool

law norm_exact_names:
  for +as: List<&2, String>
  for +bs: List<&2, String>
  Bool

@unsafe
def norm_exact(a, b):
  norm_exact_lists(Con{a, Nil{}}, Con{b, Nil{}})

@unsafe
def norm_exact_lists(as, bs):
  match as bs:
    case Nil{} Nil{}:
      True{}
    case Con{a, ar} Con{b, br}:
      kc(Bool, norm_exact_head(a, b), u => norm_exact_lists(norm_join(ks(a), ar), norm_join(ks(b), br)), u => False{})
    case other_a other_b:
      False{}

@unsafe
def norm_exact_head(a, b):
  String.eq(tg(a), tg(b)) && String.eq(nm(a), nm(b)) && U32.is_eq(ix(a), ix(b)) && U32.is_eq(qt(a), qt(b)) && U32.is_eq(terms_len(ks(a)), terms_len(ks(b))) && norm_exact_names(rm(a), rm(b))

@unsafe
def norm_exact_names(as, bs):
  match as bs:
    case Nil{} Nil{}:
      True{}
    case Con{a, ar} Con{b, br}:
      kc(Bool, String.eq(a, b), u => norm_exact_names(ar, br), u => False{})
    case other_a other_b:
      False{}

# Comparison is a worklist of conjunctions with explicit alternatives for
# the right-hand kind meet. Deep constructor equality does not grow the host stack.
type KNormCmp is Data:
  KNormCmp{+a: KTerm, +b: KTerm, +le: Bool, +fresh: U32}

type KNormAlt is Data:
  KNormAlt{+todo: List<&2, KNormCmp>}
law norm_cmp_loop:
  for +book: List<&2, KDef>
  for +todo: List<&2, KNormCmp>
  for +alts: List<&2, KNormAlt>
  Bool

law norm_cmp_quick:
  for +a: KTerm
  for +b: KTerm
  Bool

law norm_cmp_heads:
  for +book: List<&2, KDef>
  for +a: KTerm
  for +b: KTerm
  for +le: Bool
  for +fresh: U32
  for +rest: List<&2, KNormCmp>
  for +alts: List<&2, KNormAlt>
  Bool

law norm_cmp_same:
  for +book: List<&2, KDef>
  for +a: KTerm
  for +b: KTerm
  for +le: Bool
  for +fresh: U32
  for +rest: List<&2, KNormCmp>
  for +alts: List<&2, KNormAlt>
  Bool

law norm_cmp_plain:
  for +book: List<&2, KDef>
  for +a: KTerm
  for +b: KTerm
  for +le: Bool
  for +fresh: U32
  for +rest: List<&2, KNormCmp>
  for +alts: List<&2, KNormAlt>
  Bool

law norm_cmp_fields:
  for +book: List<&2, KDef>
  for +as: List<&2, KTerm>
  for +bs: List<&2, KTerm>
  for +fresh: U32
  for +rest: List<&2, KNormCmp>
  for +alts: List<&2, KNormAlt>
  Bool

law norm_cmp_zip:
  for +as: List<&2, KTerm>
  for +bs: List<&2, KTerm>
  for +fresh: U32
  for +rest: List<&2, KNormCmp>
  List<&2, KNormCmp>

law norm_cmp_kind:
  for +book: List<&2, KDef>
  for +a: KTerm
  for +b: KTerm
  for +g: KTerm
  for +h: KTerm
  for +fresh: U32
  for +rest: List<&2, KNormCmp>
  for +alts: List<&2, KNormAlt>
  Bool

@unsafe
def norm_cmp_loop(book, todo, alts):
  match todo:
    case Nil{}:
      True{}
    case Con{KNormCmp{a, b, le, fresh}, rest}:
      kc(Bool, norm_cmp_quick(a, b), u => norm_cmp_loop(book, rest, alts), u => norm_cmp_heads(book, wnf(book, a), wnf(book, b), le, fresh, rest, alts))

@unsafe
def norm_cmp_quick(a, b):
  kc(Bool, String.eq(tg(a), "App") || String.eq(tg(a), "Ref") || String.eq(tg(a), "Var"), u => norm_exact(a, b), u => False{})

@unsafe
def norm_cmp_fail(
  +book: List<&2, KDef>,
  +alts: List<&2, KNormAlt>,
) -> Bool:
  match alts:
    case Nil{}:
      False{}
    case Con{KNormAlt{todo}, rest}:
      norm_cmp_loop(book, todo, rest)

@unsafe
def norm_cmp_test(
  +book: List<&2, KDef>,
  +yes: Bool,
  +rest: List<&2, KNormCmp>,
  +alts: List<&2, KNormAlt>,
) -> Bool:
  kc(Bool, yes, u => norm_cmp_loop(book, rest, alts), u => norm_cmp_fail(book, alts))

@unsafe
def norm_cmp_heads(book, a, b, le, fresh, rest, alts):
  kc(Bool, String.eq(tg(a), "Lam") || String.eq(tg(b), "Lam"),
   u => norm_cmp_loop(book, Con{KNormCmp{app(a, var("_", fresh)), app(b, var("_", fresh)), le, U32.add(fresh, 1)}, rest}, alts),
   u => kc(Bool, String.eq(tg(a), tg(b)), u => norm_cmp_same(book, a, b, le, fresh, rest, alts), u => norm_cmp_fail(book, alts)))

@unsafe
def norm_cmp_same(book, a, b, le, fresh, rest, alts):
  kc(Bool, String.eq(tg(a), "Var"), u => norm_cmp_test(book, U32.is_eq(ix(a), ix(b)), rest, alts),
   u => kc(Bool, String.eq(tg(a), "Typ"), u => kc(Bool, le, u => norm_cmp_kind(book, a, b, wnf(book, kid(a, 0)), wnf(book, kid(b, 0)), fresh, rest, alts), u => norm_cmp_loop(book, Con{KNormCmp{kid(a, 0), kid(b, 0), False{}, fresh}, rest}, alts)),
   u => kc(Bool, String.eq(tg(a), "All"), u => kc(Bool, U32.is_eq(qt(a), qt(b)),
     u => norm_cmp_loop(book, Con{KNormCmp{kid(b, 0), kid(a, 0), le, fresh}, Con{KNormCmp{subst(kid(a, 1), ix(a), var("_", fresh)), subst(kid(b, 1), ix(b), var("_", fresh)), le, U32.add(fresh, 1)}, rest}}, alts), u => norm_cmp_fail(book, alts)),
   u => kc(Bool, String.eq(tg(a), "ADT"), u => kc(Bool, String.eq(nm(a), nm(b)) && norm_removed(rm(a), rm(b), le), u => norm_cmp_fields(book, ks(a), ks(b), fresh, rest, alts), u => norm_cmp_fail(book, alts)),
   u => kc(Bool, String.eq(tg(a), "Qua"), u => norm_cmp_test(book, U32.is_eq(qt(a), qt(b)), rest, alts),
   u => norm_cmp_plain(book, a, b, le, fresh, rest, alts))))))

@unsafe
def norm_cmp_plain(book, a, b, le, fresh, rest, alts):
  kc(Bool, String.eq(tg(a), "Ref"), u => kc(Bool, String.eq(nm(a), nm(b)), u => norm_cmp_loop(book, rest, alts), u => norm_cmp_ref(book, a, b, le, norm_max(da(lookup(book, nm(a))), da(lookup(book, nm(b)))), fresh, rest, alts)),
   u => kc(Bool, String.eq(tg(a), "Hol"), u => norm_cmp_test(book, String.eq(nm(a), nm(b)), rest, alts),
   u => kc(Bool, String.eq(tg(a), "Ctr") || String.eq(tg(a), "Mat"), u => kc(Bool, String.eq(nm(a), nm(b)), u => norm_cmp_fields(book, ks(a), ks(b), fresh, rest, alts), u => norm_cmp_fail(book, alts)),
   u => kc(Bool, String.eq(tg(a), "App") && String.eq(tg(kid(a, 0)), "Ref") && String.eq(tg(kid(b, 0)), "Ref"), u => kc(Bool, String.eq(nm(kid(a, 0)), nm(kid(b, 0))), u => norm_cmp_loop(book, Con{KNormCmp{kid(a, 1), kid(b, 1), False{}, fresh}, rest}, alts), u => norm_cmp_fail(book, alts)),
   u => kc(Bool, String.eq(tg(a), "App") || String.eq(tg(a), "Min") || String.eq(tg(a), "Eql") || String.eq(tg(a), "Rwt"), u => norm_cmp_fields(book, ks(a), ks(b), fresh, rest, alts),
   u => norm_cmp_test(book, String.eq(tg(a), "Qnt") || String.eq(tg(a), "Rfl") || String.eq(tg(a), "Efq"), rest, alts))))))

# Only bare, under-applied definitions compare extensionally. Stuck App heads
# above stay nominal, avoiding repeated eta expansion of an opaque application.
@unsafe
def norm_cmp_ref(
  +book: List<&2, KDef>,
  +a: KTerm,
  +b: KTerm,
  +le: Bool,
  +n: U32,
  +fresh: U32,
  +rest: List<&2, KNormCmp>,
  +alts: List<&2, KNormAlt>,
) -> Bool:
  kc(Bool, U32.is_eq(n, 0), u => norm_cmp_fail(book, alts),
   u => kc(Bool, U32.is_eq(n, 1),
     u => norm_cmp_loop(book, Con{KNormCmp{app(a, var("_", fresh)), app(b, var("_", fresh)), le, U32.add(fresh, 1)}, rest}, alts),
     u => norm_cmp_ref(book, app(a, var("_", fresh)), app(b, var("_", fresh)), le, U32.sub(n, 1), U32.add(fresh, 1), rest, alts)))

@unsafe
def norm_cmp_fields(book, as, bs, fresh, rest, alts):
  kc(Bool, U32.is_eq(terms_len(as), terms_len(bs)), u => norm_cmp_loop(book, norm_cmp_zip(as, bs, fresh, rest), alts), u => norm_cmp_fail(book, alts))

@unsafe
def norm_cmp_zip(as, bs, fresh, rest):
  match as bs:
    case Con{a, ar} Con{b, br}:
      Con{KNormCmp{a, b, False{}, fresh}, norm_cmp_zip(ar, br, fresh, rest)}
    case other_a other_b:
      rest

@unsafe
def norm_cmp_kind(book, a, b, g, h, fresh, rest, alts):
  kc(Bool, (String.eq(tg(g), "Qua") && U32.is_eq(qt(g), 2)) || (String.eq(tg(h), "Qua") && Bool.not(U32.is_eq(qt(h), 2))), u => norm_cmp_loop(book, rest, alts),
   u => kc(Bool, String.eq(tg(g), "Min"),
     u => norm_cmp_loop(book, Con{KNormCmp{kt("Typ", "", 0, 0, Con{kid(g, 0), Nil{}}), b, True{}, fresh}, Con{KNormCmp{kt("Typ", "", 0, 0, Con{kid(g, 1), Nil{}}), b, True{}, fresh}, rest}}, alts),
   u => kc(Bool, String.eq(tg(h), "Min"),
     u => norm_cmp_loop(book, Con{KNormCmp{a, kt("Typ", "", 0, 0, Con{kid(h, 0), Nil{}}), True{}, fresh}, rest}, Con{KNormAlt{Con{KNormCmp{a, kt("Typ", "", 0, 0, Con{kid(h, 1), Nil{}}), True{}, fresh}, rest}}, alts}),
     u => norm_cmp_loop(book, Con{KNormCmp{g, h, True{}, fresh}, rest}, alts))))

