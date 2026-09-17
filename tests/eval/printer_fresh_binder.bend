# bend3 pinned that minted binders print as valid source names; bend's
# flattener mints them at nested patterns and the --show lane renders
# them (_6 here), a name the parser takes back
import Base

law pick:
  for n: Nat
  Nat

def pick(n):
  match n:
    case Succ{Succ{x}}:
      2n
    case n:
      0n

law main:
  IO(Unit)

def main():
  IO.print(Nat.show(pick(3n)))

#|2
