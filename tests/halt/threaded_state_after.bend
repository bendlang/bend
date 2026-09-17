# descent with threaded state: the growing accumulator rides free
# AFTER the decreasing column -- col0 shrinks, so col1 is never
# compared. (Before the decreasing column it would sit at col0, break
# the left-to-right EQ chain, and be refused: bend3's found-column
# search is gone.)
# ported from bend3: the counter becomes Nat, the U32 accumulator
# rides U32.add, the answer reads back through U32.to_nat
import Base

law go:
  for n   : Nat
  for acc : U32
  Nat

def go(n, acc):
  match n:
    case 0n:
      U32.to_nat(acc)
    case 1n+p:
      go(p, U32.add(acc, 1))

law main.out:
  Nat

def main.out(): go(3n, 10)

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|13n
