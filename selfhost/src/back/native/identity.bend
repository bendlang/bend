import Base

# C identifiers fold case and punctuation. Encode every non-Base constructor
# with decimal Unicode scalars so distinct source names remain distinct after
# that transformation. Only the enclosing ADT's provenance grants Base ABI.
law nc_ctor_owned:
  for +book: List<&2, KDef>
  for +name: String
  Bool

law nc_ctor_encode:
  for +name: String
  String

law nc_ctor_codes:
  for +name: String
  String

law nc_ctor_decode:
  for +rest: String
  for +acc: U32
  for +digits: U32
  for +out: String
  for +original: String
  String

law nc_ctor_decode_step:
  for +h: Char
  for +rest: String
  for +acc: U32
  for +digits: U32
  for +out: String
  for +original: String
  String

@unsafe
def nc_ctor_identity(
  +book: List<&2, KDef>,
  +name: String,
) -> String:
  kc(String, nc_ctor_owned(book, name), u => name, u => nc_ctor_encode(name))

@unsafe
def nc_ctor_owned(book, name):
  match book:
    case Nil{}:
      False{}
    case Con{d, rest}:
      kc(Bool, String.eq(dk(d), "ADT"),
        u => kc(Bool, String.eq(dk(lookup(dc(d), name)), "Ctr"), u => db(d), u => nc_ctor_owned(rest, name)),
        u => nc_ctor_owned(rest, name))

@unsafe
def nc_ctor_encode(name):
  "$ctor." ++ nc_ctor_codes(name)

@unsafe
def nc_ctor_codes(name):
  match name:
    case SNil{}:
      ""
    case SCon{h, rest}:
      U32.show(Char.to_u32(h)) ++ "_" ++ nc_ctor_codes(rest)

@unsafe
def nc_ctor_display(
  +name: String,
) -> String:
  kc(String, String.starts_with(name, "$ctor."),
    u => nc_ctor_decode(String.drop(name, String.length("$ctor.")), 0, 0, "", name),
    u => name)

@unsafe
def nc_ctor_decode(rest, acc, digits, out, original):
  match rest:
    case SNil{}:
      kc(String, U32.is_eq(digits, 0) && String.eq(nc_ctor_encode(out), original), u => out, u => original)
    case SCon{h, tail}:
      nc_ctor_decode_step(h, tail, acc, digits, out, original)

@unsafe
def nc_ctor_decode_step(h, rest, acc, digits, out, original):
  kc(String, Char.is_eq(h, '_'),
    u => kc(String, U32.is_gt(digits, 0) && U32.is_le(acc, 1114111) && Bool.not(U32.is_ge(acc, 55296) && U32.is_le(acc, 57343)),
      u => nc_ctor_decode(rest, 0, 0, out ++ Char.show(Char.from_u32(acc)), original),
      u => original),
    u => kc(String, U32.is_ge(Char.to_u32(h), 48) && U32.is_le(Char.to_u32(h), 57) && U32.is_lt(digits, 7),
      u => nc_ctor_decode(rest, U32.add(U32.mul(acc, 10), U32.sub(Char.to_u32(h), 48)), U32.add(digits, 1), out, original),
      u => original))
