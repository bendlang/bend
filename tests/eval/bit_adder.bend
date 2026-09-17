# the full-adder kit: sum(1,1,0) drops, carry(1,1,0) carries; encoded
# sum + 10*carry = 10, bend3's golden.
# ported from bend3: the Bit module becomes base Bool.full_add (a
# (Bool & Bool) tuple), Bit.to_u32 becomes a local Bool match
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

law main.go:
  for r: Bool & Bool
  U32

def main.go(r):
  (s, k) = r
  U32.add(b2u(s), U32.mul(b2u(k), 10))

law main.out:
  U32

def main.out():
  main.go(Bool.full_add(True{}, True{}, False{}))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|10
