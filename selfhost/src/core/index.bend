import Base

# Persistent exact-name index for checked books. Source event lists remain intact.
law index_child_list:
  for +ds: List<&2, KDef>
  for +right: Bool
  KDef

law index_first:
  for +ds: List<&2, KDef>
  KDef

law index_bucket:
  for +ds: List<&2, KDef>
  for +name: String
  KDef

# Compressed persistent binary trie. Internal nodes carry one discriminating
# hash bit; leaves retain exact-name buckets for complete 32-bit collisions.
law index_lookup:
  for +cache: KDef
  for +name: String
  KDef

@unsafe
def index_hash(
  +name: String,
  +acc: U32,
) -> U32:
  match name:
    case SNil{}:
      acc
    case SCon{h, rest}:
      index_hash(rest, U32.mul(U32.xor(acc, Char.to_u32(h)), 16777619))

@unsafe
def index_child(
  +tree: KDef,
  +right: Bool,
) -> KDef:
  index_child_list(dc(tree), right)

@unsafe
def index_child_list(ds, right):
  match ds:
    case Nil{}:
      missing()
    case Con{h, rest}:
      match right:
        case True{}: index_first(rest)
        case False{}: h

@unsafe
def index_first(ds):
  match ds:
    case Nil{}:
      missing()
    case Con{h, rest}:
      h

# The public callers supply complete 32-bit hashes. `bits` remains in this
# internal ABI for the native identifier validator; paths use stored masks.
@unsafe
def index_find(
  +tree: KDef,
  +name: String,
  +hash: U32,
  +bits: U32,
) -> KDef:
  index_find_absent(tree, name, hash, bits, String.eq(dk(tree), "Absent"))

@unsafe
def index_find_absent(
  +tree: KDef,
  +name: String,
  +hash: U32,
  +bits: U32,
  +absent: Bool,
) -> KDef:
  match absent:
    case True{}: missing()
    case False{}:
      index_find_leaf(tree, name, hash, bits, U32.is_eq(dx(tree), 0))

@unsafe
def index_find_leaf(
  +tree: KDef,
  +name: String,
  +hash: U32,
  +bits: U32,
  +leaf: Bool,
) -> KDef:
  match leaf:
    case True{}:
      index_find_hash(tree, name, U32.is_eq(da(tree), hash))
    case False{}:
      index_find(index_child(tree, Bool.not(U32.is_eq(U32.and(hash, dx(tree)), 0))), name, hash, bits)

@unsafe
def index_find_hash(
  +tree: KDef,
  +name: String,
  +same: Bool,
) -> KDef:
  match same:
    case True{}: index_bucket(dc(tree), name)
    case False{}: missing()

@unsafe
def index_bucket(ds, name):
  match ds:
    case Nil{}:
      missing()
    case Con{h, rest}:
      kc(KDef, String.eq(dn(h), name), u => h, u => index_bucket(rest, name))

@unsafe
def index_remove(
  +ds: List<&2, KDef>,
  +name: String,
) -> List<&2, KDef>:
  match ds:
    case Nil{}:
      Nil{}
    case Con{h, rest}:
      index_remove_step(h, rest, name, String.eq(dn(h), name))

@unsafe
def index_remove_step(
  +h: KDef, +rest: List<&2, KDef>, +name: String, +same: Bool,
) -> List<&2, KDef>:
  match same:
    case True{}: index_remove(rest, name)
    case False{}: Con{h, index_remove(rest, name)}

@unsafe
def index_tip(
  +tree: KDef,
  +hash: U32,
) -> KDef:
  kc(KDef, U32.is_eq(dx(tree), 0), u => tree,
    u => index_tip(index_child(tree, Bool.not(U32.is_eq(U32.and(hash, dx(tree)), 0))), hash))

# U32 subtraction wraps: x & (0 - x) isolates its lowest set bit, or 0.
@unsafe
def index_split_bit(
  +diff: U32,
) -> U32:
  U32.and(diff, U32.sub(0, diff))

@unsafe
def index_leaf(
  +d: KDef,
  +hash: U32,
  +ds: List<&2, KDef>,
) -> KDef:
  KDef{"", "IndexLeaf", hash, 0, atom("Absent"), atom("Absent"), Con{d, index_remove(ds, dn(d))}, True{}, False{}}

@unsafe
def index_node(
  +hash: U32,
  +mask: U32,
  +left: KDef,
  +right: KDef,
) -> KDef:
  KDef{"", "IndexNode", hash, mask, atom("Absent"), atom("Absent"), Con{left, Con{right, Nil{}}}, True{}, False{}}

@unsafe
def index_join(
  +tree: KDef,
  +d: KDef,
  +hash: U32,
  +mask: U32,
) -> KDef:
  kc(KDef, U32.is_eq(U32.and(hash, mask), 0),
    u => index_node(da(tree), mask, index_leaf(d, hash, Nil{}), tree),
    u => index_node(da(tree), mask, tree, index_leaf(d, hash, Nil{})))

@unsafe
def index_insert(
  +tree: KDef,
  +d: KDef,
  +hash: U32,
  +mask: U32,
) -> KDef:
  kc(KDef, Bool.not(U32.is_eq(mask, 0)) && (U32.is_eq(dx(tree), 0) || U32.is_lt(mask, dx(tree))),
    u => index_join(tree, d, hash, mask),
    u => kc(KDef, U32.is_eq(dx(tree), 0),
      u => index_leaf(d, hash, dc(tree)),
      u => kc(KDef, U32.is_eq(U32.and(hash, dx(tree)), 0),
        u => index_node(da(tree), dx(tree), index_insert(index_child(tree, False{}), d, hash, mask), index_child(tree, True{})),
        u => index_node(da(tree), dx(tree), index_child(tree, False{}), index_insert(index_child(tree, True{}), d, hash, mask)))))

@unsafe
def index_set(
  +tree: KDef,
  +d: KDef,
  +hash: U32,
  +bits: U32,
) -> KDef:
  kc(KDef, String.eq(dk(tree), "Absent"), u => index_leaf(d, hash, Nil{}),
    u => index_insert(tree, d, hash, index_split_bit(U32.xor(hash, da(index_tip(tree, hash))))))

@unsafe
def index_build(
  +book: List<&2, KDef>,
) -> KDef:
  match book:
    case Nil{}:
      missing()
    case Con{h, rest}:
      index_set(index_build(rest), h, index_hash(dn(h), 2166136261), 32)

@unsafe
def index_lookup(cache, name):
  index_find(index_first(dc(cache)), name, index_hash(name, 2166136261), 32)

@unsafe
def book_cached(
  +book: List<&2, KDef>,
  +bound: U32,
) -> List<&2, KDef>:
  Con{KDef{"$kernel.cache", "BookCache", bound, 0, atom("Absent"), atom("Absent"), Con{index_build(book), Nil{}}, True{}, False{}}, book}

# A cached name miss proves the declaration list contains nothing to remove.
# Missing definitions have the empty name. Preserve the generic empty-name case
# through filtering, even for malformed/duplicate books supplied through the API.
@unsafe
def index_put_rest(
  +cache: KDef,
  +rest: List<&2, KDef>,
  +name: String,
) -> List<&2, KDef>:
  kc(List<&2, KDef>, Bool.not(String.eq(name, "")) && String.eq(dn(index_lookup(cache, name)), ""),
    u => rest, u => index_remove(rest, name))

@unsafe
def book_put(
  +book: List<&2, KDef>,
  +d: KDef,
) -> List<&2, KDef>:
  match book:
    case Nil{}:
      Con{d, Nil{}}
    case Con{h, rest}:
      kc(List<&2, KDef>, String.eq(dk(h), "BookCache"), u => Con{KDef{dn(h), dk(h), da(h), 0, atom("Absent"), atom("Absent"), Con{index_set(index_first(dc(h)), d, index_hash(dn(d), 2166136261), 32), Nil{}}, True{}, False{}}, Con{d, index_put_rest(h, rest, dn(d))}}, u => Con{d, index_remove(book, dn(d))})


# An immutable context may be reused by several backend phases. Never nest the
# sentinel or recompute its maximum binder ID from the index's implementation.
@unsafe
def book_context(
  +book: List<&2, KDef>,
) -> List<&2, KDef>:
  match book:
    case Nil{}:
      book_cached(book, 0)
    case Con{h, rest}:
      kc(List<&2, KDef>, String.eq(dk(h), "BookCache"), u => book, u => book_cached(book, norm_max_book(book)))


# Exact final-definition selection. Short event lists use the original scan.
# Marker values distinguish even the empty name from an unsuccessful lookup.
law book_final_reverse:
  for +book: List<&2,KDef>
  for +done: List<&2,KDef>
  List<&2,KDef>

law book_final_scan:
  for +book: List<&2,KDef>
  for +seen: KDef
  for +kept: List<&2,KDef>
  for +done: List<&2,KDef>
  List<&2,KDef>

law book_final_step:
  for +d: KDef
  for +rest: List<&2,KDef>
  for +seen: KDef
  for +kept: List<&2,KDef>
  for +done: List<&2,KDef>
  for +hash: U32
  List<&2,KDef>

law book_final_filter:
  for +done: List<&2,KDef>
  for +seen: KDef
  List<&2,KDef>

law book_final_legacy:
  for +book: List<&2,KDef>
  for +done: List<&2,KDef>
  List<&2,KDef>

@unsafe
def book_final_large(
  +book: List<&2,KDef>,
  +remaining: U32,
) -> Bool:
  match book:
    case Nil{}: U32.is_eq(remaining, 0)
    case Con{h, rest}:
      kc(Bool, U32.is_eq(remaining, 0), u => True{}, u => book_final_large(rest, U32.sub(remaining, 1)))

# Malformed raw JavaScript names retain the legacy comparison demand order.
# Projection and Char.to_u32 do not throw on surrogate codepoints; only the
# unchanged legacy comparisons decide whether such input must fail.
@unsafe
def book_final_name_valid(
  +name: String,
) -> Bool:
  match name:
    case SNil{}: True{}
    case SCon{h, rest}:
      kc(Bool, U32.is_le(U32.sub(Char.to_u32(h), 55296), 2047),
        u => False{}, u => book_final_name_valid(rest))

@unsafe
def book_final_names_valid(
  +book: List<&2,KDef>,
) -> Bool:
  match book:
    case Nil{}: True{}
    case Con{d, rest}:
      kc(Bool, book_final_name_valid(dn(d)),
        u => book_final_names_valid(rest), u => False{})

@unsafe
def book_final_fast(
  +book: List<&2,KDef>,
  +done: List<&2,KDef>,
) -> List<&2,KDef>:
  kc(List<&2,KDef>, book_final_large(book, 256),
    u => kc(List<&2,KDef>, book_final_names_valid(book),
      u => kc(List<&2,KDef>, book_final_names_valid(done),
        u => book_final_scan(book_final_reverse(book, Nil{}), missing(), Nil{}, done),
        u => book_final_legacy(book, done)),
      u => book_final_legacy(book, done)),
    u => book_final_legacy(book, done))

@unsafe
def book_final_reverse(book, done):
  match book:
    case Nil{}: done
    case Con{d, rest}: book_final_reverse(rest, Con{d, done})

@unsafe
def book_final_seen(
  +seen: KDef,
  +name: String,
  +hash: U32,
) -> Bool:
  String.eq(dk(index_find(seen, name, hash, 32)), "$final.seen")

@unsafe
def book_final_scan(book, seen, kept, done):
  match book:
    case Nil{}: book_final_reverse(kept, book_final_filter(done, seen))
    case Con{d, rest}:
      book_final_step(d, rest, seen, kept, done, index_hash(dn(d), 2166136261))

@unsafe
def book_final_step(d, rest, seen, kept, done, hash):
  kc(List<&2,KDef>, book_final_seen(seen, dn(d), hash),
    u => book_final_scan(rest, seen, kept, done),
    u => book_final_scan(rest,
      index_set(seen, KDef{dn(d), "$final.seen", 0, 0, atom("Absent"), atom("Absent"), Nil{}, True{}, False{}}, hash, 32),
      Con{d, kept}, done))

@unsafe
def book_final_filter(done, seen):
  match done:
    case Nil{}: Nil{}
    case Con{d, rest}:
      kc(List<&2,KDef>, book_final_seen(seen, dn(d), index_hash(dn(d), 2166136261)),
        u => book_final_filter(rest, seen),
        u => Con{d, book_final_filter(rest, seen)})

@unsafe
def book_final_legacy(book, done):
  match book:
    case Nil{}: done
    case Con{d, rest}: book_final_legacy(rest, Con{d, index_remove(done, dn(d))})
