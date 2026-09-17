# over-used scrutinee off one binder feeding two calls
# ported from bend3: the U32 switch becomes a Nat match (bend words
# carry no literal-pattern switch), the share a +let
import Base

law f:
  for i: Nat
  U32

def f(i):
  match i:
    case 0n:
      7
    case 1n+k:
      U32.from_nat(k)

law main.out:
  U32

def main.out():
  +i = {42n : Nat}
  U32.add(f(i), f(i))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|82
