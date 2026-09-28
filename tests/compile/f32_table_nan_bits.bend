# f32 table (#897): a dense F32 match compiles to a CONSTV table whose
# C rows must be the constants' own bits, not a JS number's: a signaling
# NaN row came back as the quiet NaN, and a tag that read the bits took
# the wrong arm. walk() reads the table with a dynamic index; both sides
# of each compare go through F32, so the JS lane, which quiets every NaN
# alike, agrees with C.
import Base

def as_f32(u: U32) -> F32:
  U32{w} = u
  F32{w}

def bits(f: F32) -> U32:
  F32{w} = f
  U32{w}

def table(n: U32) -> F32:
  match n:
    case 0:
      as_f32(2139095041)
    case 1:
      as_f32(2139095042)
    case _:
      as_f32(2139095043)

def expected(n: U32) -> U32:
  match n:
    case 0:
      2139095041
    case 1:
      2139095042
    case _:
      2139095043

def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

def same(+n: U32) -> U32:
  b2u(U32.is_eq(bits(table(n)), bits(as_f32(expected(n)))))

def walk(+n: Nat) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      U32.add(same(U32.from_nat(p)), walk(p))

def main() -> U32:
  walk(40n)

#|40
