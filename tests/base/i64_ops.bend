# I64 is the same Word(64n) slot U64 holds, read as two's complement. The
# arithmetic and the bitwise ops are bit-identical to the unsigned ones; the
# signed layer is negation, a comparison biased by the sign bit, and the
# arithmetic shift. The compiler lowers all of it natively (the i64_ family),
# so every check below runs in word space on EVERY lane. The twenty checks
# pin that layer where unsigned would give the OTHER answer: min < max is
# True signed and False unsigned, and the logical shift of min is positive
# where the arithmetic one is -2^62. Both printed numbers and two checks
# hand the CONSTRUCTOR a structurally built full-width word and read the TOP
# half back: a conversion that packed only 32 bits answers 32767 for ones47.
import Base

def i_zero() -> I64:
  I64{Word.zero(64n)}

def i_one() -> I64:
  I64.inc(i_zero())

def i_neg1() -> I64:
  I64.not(i_zero())

def i_min() -> I64:
  I64{I64.sign_mask()}

def i_max() -> I64:
  I64.not(i_min())

# All ones built the STRUCTURAL way -- 64 WCon cells -- and handed to the
# constructor, which is where the word conversion happens.
def i_onesw() -> I64:
  I64{Word.not(64n, Word.zero(64n))}

def i_nat(a: I64) -> Nat:
  match a:
    case I64{x}:
      Word.to_nat(64n, x)

def bn(b: Bool) -> Nat:
  match b:
    case False{}:
      0n
    case True{}:
      1n

def main.out() -> Nat:
  b0 = bn(I64.is_eq(I64.neg(i_one()), i_neg1()))
  b1 = bn(I64.is_eq(I64.add(i_neg1(), i_one()), i_zero()))
  b2 = bn(I64.is_eq(I64.neg(i_min()), i_min()))
  b3 = bn(I64.is_lt(i_min(), i_max()))
  b4 = bn(I64.is_gt(i_max(), i_min()))
  b5 = bn(I64.is_eq(I64.shr.s(i_min()), I64.neg(I64.shln(i_one(), 62n))))
  b6 = bn(I64.is_neg(i_min()))
  b7 = bn(Bool.not(I64.is_neg(i_max())))
  b8 = bn(I64.is_gt(I64.shr(i_min()), i_zero()))
  b9 = bn(I64.is_eq(I64.shr.s.n(i_min(), 63n), i_neg1()))
  ba = bn(I64.is_eq(I64.shrn(i_min(), 63n), i_one()))
  bb = bn(I64.is_eq(i_onesw(), i_neg1()))
  bc = bn(Cmp.is_lt(I64.cmp(i_min(), i_max())))
  bd = bn(I64.is_le(i_min(), i_min()))
  be = bn(I64.is_ge(i_max(), i_min()))
  bf = bn(I64.is_ne(i_min(), i_max()))
  bg = bn(I64.is_zero(I64.and(i_min(), i_max())))
  bh = bn(I64.is_eq(I64.mul(i_neg1(), i_neg1()), i_one()))
  bi = bn(I64.is_eq(I64.or(I64.xor(i_max(), i_max()), i_min()), i_min()))
  bj = bn(I64.is_eq(I64.shl(I64.inc(I64.sub(i_zero(), i_one()))), i_zero()))
  s0 = Nat.add(Nat.add(Nat.add(b0, b1), Nat.add(b2, b3)), Nat.add(b4, b5))
  s1 = Nat.add(Nat.add(Nat.add(b6, b7), Nat.add(b8, b9)), Nat.add(ba, bb))
  s2 = Nat.add(Nat.add(Nat.add(bc, bd), Nat.add(be, bf)), Nat.add(bg, bh))
  Nat.add(Nat.add(s0, s1), Nat.add(s2, Nat.add(bi, bj)))

def main() -> IO(Unit):
  do IO<Unit>:
    a : Unit <- IO.print(String.append("checks ",
      String.append(Nat.show(main.out()), "/20")))
    b : Unit <- IO.print(String.append("asr32 ",
      Nat.show(i_nat(I64.shrn(I64.shr.s(i_min()), 32n)))))
    c : Unit <- IO.print(String.append("ones47 ",
      Nat.show(i_nat(I64.shrn(i_onesw(), 17n)))))
    IO.print("I64-END")

#|checks 20/20
#|asr32 3221225472
#|ones47 140737488355327
#|I64-END
