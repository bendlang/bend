# Nat arithmetic is native on BOTH backends: the C target answers
# add/sub/mul/divmod/cmp/is_lt/double on machine words (capped at
# 2^48 by ERR_NATS), so a 2^30-sized product returns at once -- the
# unary spelling would spin for minutes and trips the suite timeout
import Base

law b2u:
  for b: Bool
  U32

def b2u(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law c2u:
  for c: Cmp
  U32

def c2u(c):
  match c:
    case LT{}:
      0
    case EQ{}:
      1
    case GT{}:
      2

law dsum:
  for r: Nat & Nat
  U32

def dsum(r):
  (q, m) = r
  U32.add(U32.from_nat(q), U32.from_nat(m))

law main.out:
  U32

def main.out():
  big = U32.from_nat(Nat.mul(U32.to_nat(1048576), U32.to_nat(1024)))
  add = U32.from_nat(Nat.add(U32.to_nat(1000000000), U32.to_nat(65536)))
  sb = U32.from_nat(Nat.sub(U32.to_nat(3), U32.to_nat(1000000)))
  dm = dsum(Nat.divmod(U32.to_nat(1000000007), U32.to_nat(97)))
  c0 = c2u(Nat.cmp(U32.to_nat(7), U32.to_nat(9)))
  c1 = c2u(Nat.cmp(U32.to_nat(9), U32.to_nat(9)))
  c2 = c2u(Nat.cmp(U32.to_nat(11), U32.to_nat(9)))
  l1 = b2u(Nat.is_lt(U32.to_nat(3), U32.to_nat(5)))
  l0 = b2u(Nat.is_lt(U32.to_nat(5), U32.to_nat(3)))
  db = U32.from_nat(Nat.double(U32.to_nat(21)))
  U32.add(U32.add(U32.add(U32.add(big, add), U32.add(sb, dm)), U32.add(U32.add(c0, c1), U32.add(c2, l1))), U32.add(l0, db))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|2084116725
