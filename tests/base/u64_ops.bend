# U64 is the 64-bit word as a number: the same Word(64n) slot F64 holds,
# with integer operations the compiler lowers natively (the u64_ family),
# so every check below runs in word space on EVERY lane -- interpreter
# included. The fifteen checks pin the wrap points (add, inc/sub, mul) and
# the half boundary (shln/shrn through bit 63, an unsigned compare of
# 2^64-1 against 2^32-1, and/or across the halves). Two of them hand the
# CONSTRUCTOR a structurally built full-width word, as do the two printed
# numbers, which read the TOP half back: a conversion that packed only 32
# bits answers 0 for hi32 and fails checks 13 and 15.
import Base

def u_zero() -> U64:
  U64{Word.zero(64n)}

def u_one() -> U64:
  U64.inc(u_zero())

def u_max() -> U64:
  U64.not(u_zero())

# All ones built the STRUCTURAL way -- 64 WCon cells -- and handed to the
# constructor, which is where the word conversion happens.
def u_maxw() -> U64:
  U64{Word.not(64n, Word.zero(64n))}

def u_p32() -> U64:
  U64.shln(u_one(), 32n)

def u_nat(a: U64) -> Nat:
  match a:
    case U64{x}:
      Word.to_nat(64n, x)

def bn(b: Bool) -> Nat:
  match b:
    case False{}:
      0n
    case True{}:
      1n

def main.out() -> Nat:
  b0 = bn(U64.is_eq(U64.add(u_max(), u_one()), u_zero()))
  b1 = bn(U64.is_eq(U64.inc(U64.sub(u_max(), u_one())), u_max()))
  b2 = bn(U64.is_eq(U64.mul(u_p32(), u_p32()), u_zero()))
  b3 = bn(U64.is_eq(U64.shrn(U64.shln(u_one(), 63n), 63n), u_one()))
  b4 = bn(U64.is_gt(u_max(), U64.sub(u_p32(), u_one())))
  b5 = bn(U64.is_eq(U64.not(U64.xor(u_max(), u_max())), u_max()))
  b6 = bn(U64.is_zero(U64.and(u_p32(), U64.sub(u_p32(), u_one()))))
  b7 = bn(U64.is_ne(U64.or(u_zero(), u_p32()), u_zero()))
  b8 = bn(U64.is_eq(U64.shr(U64.shl(u_max())), U64.shr(u_max())))
  b9 = bn(U64.is_le(u_one(), u_one()))
  ba = bn(U64.is_ge(u_max(), u_one()))
  bb = bn(Cmp.is_gt(U64.cmp(u_max(), u_zero())))
  bc = bn(U64.is_eq(u_maxw(), u_max()))
  bd = bn(U64.is_eq(U64.sub(u_zero(), u_one()), u_max()))
  be = bn(U64.is_eq(U64{Word.sub(64n, Word.zero(64n),
    Word.inc(64n, Word.zero(64n)))}, u_max()))
  s0 = Nat.add(Nat.add(Nat.add(b0, b1), Nat.add(b2, b3)), Nat.add(b4, b5))
  s1 = Nat.add(Nat.add(Nat.add(b6, b7), Nat.add(b8, b9)), Nat.add(ba, bb))
  Nat.add(Nat.add(s0, s1), Nat.add(bc, Nat.add(bd, be)))

def main() -> IO(Unit):
  do IO<Unit>:
    a : Unit <- IO.print(String.append("checks ",
      String.append(Nat.show(main.out()), "/15")))
    b : Unit <- IO.print(String.append("hi32 ",
      Nat.show(u_nat(U64.shrn(u_maxw(), 32n)))))
    c : Unit <- IO.print(String.append("bit47 ",
      Nat.show(u_nat(U64.shrn(U64.shln(u_one(), 63n), 16n)))))
    IO.print("U64-END")

#|checks 15/15
#|hi32 4294967295
#|bit47 140737488355328
#|U64-END
