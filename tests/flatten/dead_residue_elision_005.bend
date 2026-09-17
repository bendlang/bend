# the numeric-loop dead residue, on Nat: the base arm destructures a
# tuple whose only ctor's residue is dead and elided, and the loop
# answers bend3's 281 -- the `case 1+n` countdown becomes a Nat match
# with a U32 mirror argument; contracted word binders ride + binders
# (the rebinds keep bend3's arithmetic exactly)
import Base

law step:
  for p: U32 & U32
  U32 & U32

def step(p):
  (a0, b) = p
  +a = {a0 : U32}
  ((a + b : U32), (a + 1 : U32))

law go:
  for n   : Nat
  for +i  : U32
  for p   : U32 & U32
  for acc : U32
  U32

def go(n, i, p, acc):
  match n:
    case Zero{}:
      (x, y) = p
      (acc + x * 10 + y : U32)
    case Succ{k}:
      go(k, (i - 1 : U32), step(p), (acc + i : U32))

law main.out:
  Nat

def main.out():
  U32.to_nat(go(5n, 5, (1, 2), 0))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|281n
