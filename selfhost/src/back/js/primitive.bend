# Saturated native scalar calls lower to JavaScript expressions. Public native
# descriptors and partial applications keep their existing runtime path.
# The checked telescope and primitive owners establish identity; names alone do
# not. Repeated/conditional operands are bound once, in source order.

@unsafe
def j_primitive_known(+name: String) -> Bool:
  String.contains("|U32.add|U32.sub|U32.mul|U32.div|U32.mod|U32.and|U32.or|U32.xor|U32.inc|U32.not|U32.shl|U32.shr|U32.shln|U32.shrn|U32.is_zero|U32.is_eq|U32.is_ne|U32.is_lt|U32.is_le|U32.is_gt|U32.is_ge|U32.to_nat|U32.from_nat|U32.to_f32|F32.add|F32.sub|F32.mul|F32.div|F32.mod|F32.neg|F32.is_eq|F32.is_ne|F32.is_lt|F32.is_le|F32.is_gt|F32.is_ge|F32.sqrt|F32.exp|F32.log|F32.log2|F32.log10|F32.sin|F32.cos|F32.tan|F32.asin|F32.acos|F32.atan|F32.sinh|F32.cosh|F32.tanh|F32.floor|F32.ceil|F32.trunc|F32.abs|", "|" ++ name ++ "|")

@unsafe
def j_primitive_arity(+name: String) -> U32:
  kc(U32, String.contains("|U32.inc|U32.not|U32.shl|U32.shr|U32.is_zero|U32.to_nat|U32.from_nat|U32.to_f32|F32.neg|F32.sqrt|F32.exp|F32.log|F32.log2|F32.log10|F32.sin|F32.cos|F32.tan|F32.asin|F32.acos|F32.atan|F32.sinh|F32.cosh|F32.tanh|F32.floor|F32.ceil|F32.trunc|F32.abs|", "|" ++ name ++ "|"), u => 1, u => 2)

@unsafe
def j_primitive_input(+name: String, +at: U32) -> String:
  kc(String, String.eq(name, "U32.from_nat") || ((String.eq(name, "U32.shln") || String.eq(name, "U32.shrn")) && U32.is_eq(at, 1)), u => "Nat", u => kc(String, String.starts_with(name, "F32."), u => "F32", u => "U32"))

@unsafe
def j_primitive_result(+name: String) -> String:
  kc(String, String.starts_with(name, "U32.is_") || String.starts_with(name, "F32.is_"), u => "Bool", u =>
  kc(String, String.eq(name, "U32.to_nat"), u => "Nat", u =>
  kc(String, String.eq(name, "U32.to_f32") || String.starts_with(name, "F32."), u => "F32", u => "U32")))

@unsafe
def j_primitive_type(+book: List<&2,KDef>, +ty: KTerm, +name: String) -> Bool:
  String.eq(tg(ty), "ADT") && String.eq(nm(ty), name) && U32.is_eq(terms_len(ks(ty)), 0) &&
  List.is_empty(&2, String, rm(ty)) &&
  kc(Bool, String.eq(name, "Nat"), u => j_u32_native_ctor(book, "Nat", "Zero") && j_u32_native_ctor(book, "Nat", "Succ"), u =>
  kc(Bool, String.eq(name, "F32"), u => j_u32_native_ctor(book, "F32", "F32") && j_u32_native_book(book), u =>
  kc(Bool, String.eq(name, "Bool"), u => j_u32_native_ctor(book, "Bool", "False") && j_u32_native_ctor(book, "Bool", "True"), u => j_u32_native_book(book))))

@unsafe
def j_primitive_telescope(+book: List<&2,KDef>, +ty: KTerm, +name: String, +at: U32, +left: U32) -> Bool:
  +head = wnf(book, ty)
  kc(Bool, U32.is_eq(left, 0), u => j_primitive_type(book, head, j_primitive_result(name)), u =>
    kc(Bool, String.eq(tg(head), "All") && Bool.not(U32.is_eq(qt(head), 0)) &&
      j_primitive_type(book, wnf(book, kid(head, 0)), j_primitive_input(name, at)),
      u => j_primitive_telescope(book, kid(head, 1), name, U32.inc(at), U32.sub(left, 1)), u => False{}))

@unsafe
def j_primitive_definition(+book: List<&2,KDef>, +d: KDef, +arity: U32) -> Bool:
  kc(Bool, db(d) && String.eq(dk(d), "Def") && U32.is_eq(dx(d), 0) &&
    Bool.not(String.eq(tg(j_strip(dv(d))), "Foreign")) &&
    U32.is_eq(da(d), arity) && U32.is_eq(j_primitive_arity(dn(d)), arity),
    u => j_primitive_telescope(book, dt(d), dn(d), 0, arity), u => False{})

@unsafe
def j_primitive_call(+book: List<&2,KDef>, +spine: KTerm) -> Bool:
  kc(Bool, String.eq(tg(spine), "Call") && j_primitive_known(nm(spine)),
    u => j_primitive_definition(book, lookup(book, nm(spine)), terms_len(ks(spine))), u => False{})

@unsafe
def j_primitive_emit(+book: List<&2,KDef>, +env: List<&2,KTerm>, +spine: KTerm) -> String:
  +name = nm(spine)
  +a = j_expr(book, env, kid(spine, 0), kt("ADT", j_primitive_input(name, 0), 0, 0, Nil{}), False{})
  +b = kc(String, U32.is_eq(j_primitive_arity(name), 2),
    u => j_expr(book, env, kid(spine, 1), kt("ADT", j_primitive_input(name, 1), 0, 0, Nil{}), False{}), u => "")
  +count = j_strip(kid(spine, 1))
  "(/* primitive */" ++ kc(String,
    (String.eq(name, "U32.shln") || String.eq(name, "U32.shrn")) && core_nat(count),
    u => j_primitive_shift_literal(name, "(" ++ a ++ ")", kl_number(count)),
    u => j_primitive_code(name, "(" ++ a ++ ")", "(" ++ b ++ ")")) ++ ")"

# A large literal shift still evaluates its left operand, without coercing it.
@unsafe
def j_primitive_shift_literal(+name: String, +a: String, +count: U32) -> String:
  kc(String, U32.is_lt(count, 32),
    u => "((" ++ a ++ kc(String, String.eq(name, "U32.shln"), u => "<<", u => ">>>") ++ U32.show(count) ++ ")>>>0)",
    u => "(" ++ a ++ ",0)")

@unsafe
def j_primitive_symbol(+op: String) -> String:
  kc(String, String.eq(op, "add"), u => "+", u =>
  kc(String, String.eq(op, "sub"), u => "-", u =>
  kc(String, String.eq(op, "mul"), u => "*", u =>
  kc(String, String.eq(op, "div"), u => "/", u =>
  kc(String, String.eq(op, "mod"), u => "%", u =>
  kc(String, String.eq(op, "and"), u => "&", u =>
  kc(String, String.eq(op, "or"), u => "|", u =>
  kc(String, String.eq(op, "xor"), u => "^", u =>
  kc(String, String.eq(op, "is_eq"), u => "===", u =>
  kc(String, String.eq(op, "is_ne"), u => "!==", u =>
  kc(String, String.eq(op, "is_lt"), u => "<", u =>
  kc(String, String.eq(op, "is_le"), u => "<=", u =>
  kc(String, String.eq(op, "is_gt"), u => ">", u => ">=")))))))))))))

@unsafe
def j_primitive_code(+name: String, +a: String, +b: String) -> String:
  +op = String.drop(name, 4n)
  kc(String, String.starts_with(op, "is_") && Bool.not(String.eq(op, "is_zero")),
    u => "(" ++ a ++ j_primitive_symbol(op) ++ b ++ ")", u =>
  kc(String, String.starts_with(name, "F32."), u => j_primitive_float(op, a, b), u => j_primitive_u32(op, a, b)))

@unsafe
def j_primitive_float(+op: String, +a: String, +b: String) -> String:
  kc(String, String.eq(op, "neg"), u => "Math.fround(-" ++ a ++ ")", u =>
  kc(String, String.contains("|add|sub|mul|div|mod|", "|" ++ op ++ "|"),
    u => "Math.fround(" ++ a ++ j_primitive_symbol(op) ++ b ++ ")",
    u => "Math.fround(Math." ++ op ++ "(" ++ a ++ "))"))

@unsafe
def j_primitive_u32(+op: String, +a: String, +b: String) -> String:
  kc(String, String.eq(op, "mul"), u => "(Math.imul(" ++ a ++ "," ++ b ++ ")>>>0)", u =>
  kc(String, String.eq(op, "div"), u => "((a,b)=>b===0?0:(Math.floor(a/b)>>>0))(" ++ a ++ "," ++ b ++ ")", u =>
  kc(String, String.eq(op, "mod"), u => "((a,b)=>b===0?a:a%b)(" ++ a ++ "," ++ b ++ ")", u =>
  kc(String, String.eq(op, "shln") || String.eq(op, "shrn"), u => "((a,n)=>n>=32n?0:(a" ++ kc(String, String.eq(op, "shln"), u => "<<", u => ">>>") ++ "Number(n))>>>0)(" ++ a ++ "," ++ b ++ ")", u =>
  kc(String, String.eq(op, "inc"), u => "((" ++ a ++ "+1)>>>0)", u =>
  kc(String, String.eq(op, "not"), u => "((~" ++ a ++ ")>>>0)", u =>
  kc(String, String.eq(op, "shl"), u => "((" ++ a ++ "<<1)>>>0)", u =>
  kc(String, String.eq(op, "shr"), u => "(" ++ a ++ ">>>1)", u =>
  kc(String, String.eq(op, "is_zero"), u => "(" ++ a ++ "===0)", u =>
  kc(String, String.eq(op, "to_nat"), u => "BigInt(" ++ a ++ ")", u =>
  kc(String, String.eq(op, "from_nat"), u => "Number(" ++ a ++ "&0xffffffffn)", u =>
  kc(String, String.eq(op, "to_f32"), u => "Math.fround(" ++ a ++ ")", u =>
    "((" ++ a ++ j_primitive_symbol(op) ++ b ++ ")>>>0)"))))))))))))
