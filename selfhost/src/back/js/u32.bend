# Native U32 -> U32 decision workers for checked, closed literal patterns.
# Only U32/Word/Bool matcher trees and ignored default binders are accepted.
# Calls, captured values, residual Words and nonliteral results keep the generic
# emitter. Native owner/constructor identity is required, not just spelling.
# The executable tree has an 8192-node budget; ignored bit binders are skipped
# once, rather than exploring both Boolean values and duplicating their suffix.

@unsafe
def j_u32_native_ctor(+book: List<&2,KDef>, +owner: String, +name: String) -> Bool:
  +d = lookup(book, owner)
  +c = lookup(dc(d), name)
  String.eq(dk(d), "ADT") && db(d) && String.eq(dk(c), "Ctr") && db(c)

@unsafe
def j_u32_native_book(+book: List<&2,KDef>) -> Bool:
  j_u32_native_ctor(book, "U32", "U32") &&
  j_u32_native_ctor(book, "Word.Nil", "WNil") &&
  j_u32_native_ctor(book, "Word.Con", "WCon") &&
  j_u32_native_ctor(book, "Bool", "False") &&
  j_u32_native_ctor(book, "Bool", "True") &&
  String.eq(dk(lookup(book, "Word")), "Def") && db(lookup(book, "Word"))

@unsafe
def j_u32_native_type(+ty: KTerm) -> Bool:
  String.eq(tg(ty), "ADT") && String.eq(nm(ty), "U32") &&
  U32.is_eq(terms_len(ks(ty)), 0) && Bool.not(has_name(rm(ty), "U32"))

@unsafe
def j_u32_bounded(+todo: List<&2,KTerm>, +fuel: U32) -> Bool:
  match todo:
    case Nil{}: True{}
    case Con{t, rest}:
      kc(Bool, U32.is_eq(fuel, 0), u => False{}, u =>
        j_u32_bounded(kc(List<&2,KTerm>, String.eq(tg(t), "Ann"),
          u => Con{kid(t, 0), rest}, u => List.append(&2, KTerm, ks(t), rest)), U32.sub(fuel, 1)))

@unsafe
def j_u32_result(+value: Maybe<&2,U32>) -> Maybe<&2,String>:
  match value:
    case None{}: None{}
    case Some{n}: Some{U32.show(n)}

@unsafe
def j_u32_word(+t: KTerm, +depth: U32) -> Maybe<&2,String>:
  j_u32_word_node(j_strip(t), depth)

@unsafe
def j_u32_word_node(+t: KTerm, +depth: U32) -> Maybe<&2,String>:
  kc(Maybe<&2,String>, String.eq(tg(t), "Lam"), u => j_u32_result(j_u32(kid(t, 0))), u =>
  kc(Maybe<&2,String>, String.eq(tg(t), "Mat") && String.eq(nm(t), "WCon"), u =>
    kc(Maybe<&2,String>, U32.is_lt(depth, 32),
      u => j_u32_word_arm(j_strip(kid(t, 0)), depth),
      u => j_u32_word(kid(t, 1), depth)), u =>
  kc(Maybe<&2,String>, String.eq(tg(t), "Mat") && String.eq(nm(t), "WNil"), u =>
    kc(Maybe<&2,String>, U32.is_eq(depth, 32),
      u => j_u32_result(j_u32(kid(t, 0))),
      u => j_u32_word(kid(t, 1), depth)), u => None{})))

@unsafe
def j_u32_word_arm(+t: KTerm, +depth: U32) -> Maybe<&2,String>:
  kc(Maybe<&2,String>, String.eq(tg(t), "Lam"),
    u => j_u32_word(kid(t, 0), U32.inc(depth)),
    u => j_u32_branches(depth, j_u32_bit(t, depth, False{}), j_u32_bit(t, depth, True{})))

@unsafe
def j_u32_bit(+t: KTerm, +depth: U32, +bit: Bool) -> Maybe<&2,String>:
  j_u32_bit_node(j_strip(t), depth, bit)

@unsafe
def j_u32_bit_node(+t: KTerm, +depth: U32, +bit: Bool) -> Maybe<&2,String>:
  kc(Maybe<&2,String>, String.eq(tg(t), "Lam"),
    u => j_u32_word(kid(t, 0), U32.inc(depth)), u =>
  kc(Maybe<&2,String>, String.eq(tg(t), "Mat") && (String.eq(nm(t), "True") || String.eq(nm(t), "False")),
    u => kc(Maybe<&2,String>, kc(Bool, bit, u => String.eq(nm(t), "True"), u => String.eq(nm(t), "False")),
      u => j_u32_word(kid(t, 0), U32.inc(depth)),
      u => j_u32_bit(kid(t, 1), depth, bit)), u => None{}))

@unsafe
def j_u32_branches(+depth: U32, +zero: Maybe<&2,String>, +one: Maybe<&2,String>) -> Maybe<&2,String>:
  match zero one:
    case Some{x} Some{y}:
      Some{kc(String, String.eq(x, y), u => x, u => "(((u>>>" ++ U32.show(depth) ++ ")&1)?" ++ y ++ ":" ++ x ++ ")")}
    case None{} other: None{}
    case Some{x} None{}: None{}

@unsafe
def j_u32_worker_type(+book: List<&2,KDef>, +t: KTerm, +ty: KTerm) -> Maybe<&2,String>:
  kc(Maybe<&2,String>, String.eq(tg(ty), "All") && Bool.not(U32.is_eq(qt(ty), 0)), u =>
    kc(Maybe<&2,String>, j_u32_native_type(wnf(book, kid(ty, 0))) && j_u32_native_type(wnf(book, kid(ty, 1))) && j_u32_native_book(book),
      u => kc(Maybe<&2,String>, j_u32_bounded([t], 8192),
        u => j_u32_worker_code(j_u32_word(kid(t, 0), 0)), u => None{}), u => None{}), u => None{})

@unsafe
def j_u32_worker_code(+body: Maybe<&2,String>) -> Maybe<&2,String>:
  match body:
    case None{}: None{}
    case Some{code}: Some{"fn(1,function(a){const u=a[0]>>>0;return " ++ code ++ ";})"}

@unsafe
def j_u32_worker(+book: List<&2,KDef>, +d: KDef) -> Maybe<&2,String>:
  +t = j_strip(dv(d))
  kc(Maybe<&2,String>, String.eq(tg(t), "Mat") && String.eq(nm(t), "U32"),
    u => j_u32_worker_type(book, t, wnf(book, dt(d))), u => None{})

@unsafe
def j_u32_global(+book: List<&2,KDef>, +d: KDef, +worker: Maybe<&2,String>) -> String:
  match worker:
    case Some{code}: j_l_global_worker(book, d, dv(d), code)
    case None{}:
      kc(String, j_l_deep(dv(d), 0), u => j_l_definition(book, d, j_l_mark(dv(d), "r", 0)), u => j_l_global(book, d, dv(d)))
