# a result deeper than the host stack must still normalize and print:
# bend3 pinned a 4000-deep list through term_snf/term_show; here the
# Nat show sugar must walk a 131072-deep Succ chain to its digits, on
# every lane (the C digit printer and the JS readback included).
# ported from bend3: List(U32) zeros(4000) becomes Nat.pow2(17n) --
# bend has no list literal, and the closed-chain digit render pins the
# same deep, non-overflowing walk
import Base

law Nat.pow2:
  for n: Nat
  Nat

def Nat.pow2(n):
  match n:
    case 0n:
      1n
    case 1n+p:
      Nat.double(Nat.pow2(p))

law main.out:
  Nat

def main.out():
  Nat.pow2(17n)

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|131072n
