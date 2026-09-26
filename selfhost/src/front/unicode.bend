# String and character escape decoding is performed in Bend.
type FDecoded is Data:
  FDecoded{code: U32, +rest: String, +error: String}

law f_decode_char:
  for +s: String
  FDecoded

law f_decode_escape:
  for +s: String
  FDecoded

law f_escape_valid:
  for +c: Char
  Bool

law f_decode_unicode:
  for +s: String
  for +code: U32
  for +count: U32
  FDecoded

law f_string_decoded:
  for +d: FDecoded
  KTerm

law f_char_literal:
  for +s: String
  KTerm

law f_char_decoded:
  for +d: FDecoded
  KTerm

@unsafe
def f_decode_char(s):
  f_choose(FDecoded, String.is_empty(s), u => FDecoded{0, "", "expected character"}, u => f_choose(FDecoded, Char.is_eq(f_head(s), '\\'), u => f_decode_escape(f_tail(s)), u => FDecoded{Char.to_u32(f_head(s)), f_tail(s), ""}))

@unsafe
def f_decode_escape(s):
  f_choose(FDecoded, Char.is_eq(f_head(s), 'u') && Char.is_eq(f_head(f_tail(s)), '{'), u => f_decode_unicode(f_tail(f_tail(s)), 0, 0), u => f_choose(FDecoded, f_escape_valid(f_head(s)), u => FDecoded{f_escape_code(f_head(s)), f_tail(s), ""}, u => FDecoded{0, s, "invalid character escape"}))

@unsafe
def f_escape_valid(c):
  Char.is_eq(c, 'n') || Char.is_eq(c, 't') || Char.is_eq(c, 'r') || Char.is_eq(c, '0') || Char.is_eq(c, '\\') || Char.is_eq(c, '\'') || Char.is_eq(c, '"')

@unsafe
def f_hex(
  +c: Char,
) -> U32:
  f_choose(U32, Char.is_digit(c), u => U32.sub(Char.to_u32(c), 48), u => f_choose(U32, U32.is_ge(Char.to_u32(Char.to_lower(c)), 97) && U32.is_le(Char.to_u32(Char.to_lower(c)), 102), u => U32.sub(Char.to_u32(Char.to_lower(c)), 87), u => 16))

@unsafe
def f_decode_unicode(s, code, count):
  f_choose(FDecoded, Char.is_eq(f_head(s), '}') && U32.is_gt(count, 0), u => FDecoded{code, f_tail(s), ""}, u => f_choose(FDecoded, U32.is_lt(f_hex(f_head(s)), 16) && U32.is_lt(count, 6), u => f_decode_unicode(f_tail(s), U32.add(U32.mul(code, 16), f_hex(f_head(s))), U32.add(count, 1)), u => FDecoded{0, s, "invalid Unicode escape"}))

@unsafe
def f_string_decoded(d):
  match d:
    case FDecoded{code, rest, +err}:
      f_choose(KTerm, String.is_empty(err), u => kt("Ctr", "SCon", 0, 1, [kt("Ctr", "Chr", 0, 1, [f_u32(code)]), f_string(rest)]), u => kt("Error", err, 0, 0, Nil{}))

@unsafe
def f_char_literal(s):
  f_char_decoded(f_decode_char(s))

@unsafe
def f_char_decoded(d):
  match d:
    case FDecoded{code, +rest, +err}:
      f_choose(KTerm, String.is_empty(err) && f_eq(rest, "'"), u => kt("Ctr", "Chr", 0, 1, [f_u32(code)]), u => kt("Error", "character literal requires one character and a closing quote", 0, 0, Nil{}))

@unsafe
def f_float_bits(
  +bits: U32,
) -> KTerm:
  f_choose(KTerm, U32.is_eq(U32.and(bits, 2139095040), 2139095040), u => kt("Error", "float literal must be finite", 0, 0, Nil{}), u => kt("Ctr", "F32", 0, 1, [f_word(bits, 32)]))

