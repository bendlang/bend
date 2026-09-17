# a phase column is ordered by literal comparison: the recursion is
# lexicographic on (d, mode) -- flip(p, 1n) shrinks col0, and
# flip(1n+ p, 0n) keeps col0 EQ while 0n is a strict subterm of the
# refined 1n column. Both accepted by the left-to-right law.
# ported from bend3: the U32 switch becomes a Nat match, the catch-all
# phase arm a plain binder
import Base

law flip:
  for d: Nat
  for m: Nat
  Nat

def flip(d, m):
  match d:
    case 0n:
      0n
    case 1n+p:
      match m:
        case 0n:
          flip(p, 1n)
        case 1n:
          flip(1n+ p, 0n)
        case q:
          0n

law main.out:
  Nat

def main.out(): flip(3n, 0n)

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|0n
