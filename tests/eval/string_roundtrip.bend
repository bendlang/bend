# Base String: split/join round-trips through a separator, and
# concat/length count code points. Pure.
# ported from bend3: String.split takes (s, +sep: Char), String.join.go
# takes (xs, h, +sep: String) -- both separators wear + (Char and
# String are Data);
# lengths are Nats read back through U32.from_nat; concat is
# String.append
import Base

law beq:
  for a: Char
  for b: Char
  Bool

def beq(a, b):
  String.eq(SCon{a, SNil{}}, SCon{b, SNil{}})

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law main.out:
  U32

def main.out():
  b = bu(String.eq(String.join(String.split("a,b,c", ','), ","), "a,b,c"))
  l = U32.from_nat(List.length(&2, String, String.split("a,b,c", ',')))
  n = U32.from_nat(String.length(String.append("ab", "cd")))
  U32.add(U32.add(b, U32.mul(l, 100)), U32.mul(n, 10))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|341
