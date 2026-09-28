import Base

# Constant constructors lower to the JavaScript primitive representation.
law j_strip:
  for +t: KTerm
  KTerm

@unsafe
def j_strip(t):
  kc(KTerm, String.eq(tg(t), "Ann"), u => j_strip(kid(t, 0)), u => t)

@unsafe
def j_literal(
  +t: KTerm,
) -> String:
  j_literal_node(j_strip(t))

law j_literal_node:
  for +t: KTerm
  String

@unsafe
def j_literal_node(t):
  kc(String, core_nat(t), u => U32.show(qt(t)) ++ "n", u =>
  kc(String, String.eq(tg(t), "Ctr"), u => j_literal_ctor(t), u => ""))

law j_literal_ctor:
  for +t: KTerm
  String

@unsafe
def j_literal_ctor(t):
  kc(String, String.eq(nm(t), "U32"), u => j_word_text(j_word(j_strip(kid(t, 0)), 0, 0), False{}), u => kc(String, String.eq(nm(t), "F32"), u => j_word_text(j_word(j_strip(kid(t, 0)), 0, 0), True{}), u => kc(String, String.eq(nm(t), "Chr"), u => j_char_text(j_u32(kid(t, 0))), u => kc(String, String.eq(nm(t), "Zero") || String.eq(nm(t), "Succ"), u => j_nat_text(j_nat(t, 0n)), u => kc(String, String.eq(nm(t), "SNil") || String.eq(nm(t), "SCon"), u => j_string_text(j_string(t, "")), u => "")))))

law j_u32:
  for +t: KTerm
  Maybe<&2, U32>

@unsafe
def j_u32(t):
  j_u32_node(j_strip(t))

law j_u32_node:
  for +t: KTerm
  Maybe<&2, U32>

@unsafe
def j_u32_node(t):
  kc(Maybe<&2, U32>, String.eq(tg(t), "Ctr") && String.eq(nm(t), "U32"), u => j_word(j_strip(kid(t, 0)), 0, 0), u => None{})

law j_word:
  for +t: KTerm
  for +at: U32
  for +acc: U32
  Maybe<&2, U32>

@unsafe
def j_word(t, at, acc):
  kc(Maybe<&2, U32>, String.eq(tg(t), "Ctr"), u => kc(Maybe<&2, U32>, String.eq(nm(t), "WNil"), u => kc(Maybe<&2, U32>, U32.is_eq(at, 32), u => Some{acc}, u => None{}), u => kc(Maybe<&2, U32>, String.eq(nm(t), "WCon") && U32.is_lt(at, 32), u => j_word_bit(j_strip(kid(t, 0)), j_strip(kid(t, 1)), at, acc), u => None{})), u => None{})

law j_word_bit:
  for +bit: KTerm
  for +rest: KTerm
  for +at: U32
  for +acc: U32
  Maybe<&2, U32>

@unsafe
def j_word_bit(bit, rest, at, acc):
  kc(Maybe<&2, U32>, String.eq(tg(bit), "Ctr") && (String.eq(nm(bit), "True") || String.eq(nm(bit), "False")), u => j_word(rest, U32.add(at, 1), U32.or(acc, kc(U32, String.eq(nm(bit), "True"), u => U32.shln(1, U32.to_nat(at)), u => 0))), u => None{})

law j_word_text:
  for +value: Maybe<&2, U32>
  for +float: Bool
  String

@unsafe
def j_word_text(value, float):
  match value:
    case None{}:
      ""
    case Some{n}:
      kc(String, float, u => "bitsFloat(" ++ U32.show(n) ++ ")", u => U32.show(n))

law j_char_text:
  for +value: Maybe<&2, U32>
  String

@unsafe
def j_char_text(value):
  match value:
    case None{}:
      ""
    case Some{n}:
      "checkedChar(" ++ U32.show(n) ++ ")"

law j_nat:
  for +t: KTerm
  for +acc: Nat
  Maybe<&2, Nat>

@unsafe
def j_nat(t, acc):
  kc(Maybe<&2, Nat>, core_nat(t), u => Some{Nat.add(acc, U32.to_nat(qt(t)))}, u =>
  kc(Maybe<&2, Nat>, String.eq(tg(t), "Ctr"), u => kc(Maybe<&2, Nat>, String.eq(nm(t), "Zero"), u => Some{acc}, u => kc(Maybe<&2, Nat>, String.eq(nm(t), "Succ"), u => j_nat(j_strip(kid(t, 0)), Nat.add(acc, 1n)), u => None{})), u => None{}))

law j_nat_text:
  for +value: Maybe<&2, Nat>
  String

@unsafe
def j_nat_text(value):
  match value:
    case None{}:
      ""
    case Some{n}:
      Nat.show(n) ++ "n"

law j_string:
  for +t: KTerm
  for +acc: String
  Maybe<&2, String>

@unsafe
def j_string(t, acc):
  kc(Maybe<&2, String>, String.eq(tg(t), "Ctr"), u => kc(Maybe<&2, String>, String.eq(nm(t), "SNil"), u => Some{String.reverse(acc)}, u => kc(Maybe<&2, String>, String.eq(nm(t), "SCon"), u => j_string_head(j_strip(kid(t, 0)), j_strip(kid(t, 1)), acc), u => None{})), u => None{})

law j_string_head:
  for +head: KTerm
  for +tail: KTerm
  for +acc: String
  Maybe<&2, String>

@unsafe
def j_string_head(head, tail, acc):
  kc(Maybe<&2, String>, String.eq(tg(head), "Ctr") && String.eq(nm(head), "Chr"), u => j_string_char(j_u32(kid(head, 0)), tail, acc), u => None{})

law j_string_char:
  for +value: Maybe<&2, U32>
  for +tail: KTerm
  for +acc: String
  Maybe<&2, String>

@unsafe
def j_string_char(value, tail, acc):
  match value:
    case None{}:
      None{}
    case Some{n}:
      kc(Maybe<&2, String>, U32.is_le(n, 1114111) && (U32.is_lt(n, 55296) || U32.is_gt(n, 57343)), u => j_string(tail, SCon{Char.from_u32(n), acc}), u => None{})

law j_string_text:
  for +value: Maybe<&2, String>
  String

@unsafe
def j_string_text(value):
  match value:
    case None{}:
      ""
    case Some{s}:
      j_quote(s)


# Literal compression follows checked type provenance, so ordinary constructors
# named Zero, Succ, SNil, etc. keep their user-defined layout in libraries.
law j_literal_provenance:
  for +book: List<&2, KDef>
  for +ty: KTerm
  for +literal: String
  String

@unsafe
def j_literal_typed(
  +book: List<&2, KDef>,
  +t: KTerm,
  +ty: KTerm,
) -> String:
  +literal = j_literal(t)
  kc(String, String.eq(literal, ""), u => "", u => j_literal_provenance(book, wnf(book, ty), literal))

@unsafe
def j_literal_provenance(book, ty, literal):
  +d = lookup(book, nm(ty))
  kc(String, String.eq(tg(ty), "ADT") && String.eq(dk(d), "ADT") && Bool.not(db(d)), u => "", u => literal)
