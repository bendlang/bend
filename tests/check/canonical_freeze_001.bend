# check_canonical_freeze_000's numeric flavor rode 0/1/2+ switches;
# bend has no number switches and the same unconditional freeze --
# the is_eq dispatch's arms keep the frozen goal and the original
# hypothesis closes them
import Base

law g9.go:
  for -n: U32
  for  e: {U32.is_eq(n, 0) == True{} : Bool}
  for  w: Bool
  {U32.is_eq(n, 0) == True{} : Bool}

def g9.go(n, e, w):
  match w:
    case True{}:
      e
    case False{}:
      e

law g9:
  for n: U32
  for e: {U32.is_eq(n, 0) == True{} : Bool}
  {U32.is_eq(n, 0) == True{} : Bool}

def g9(n, e):
  g9.go(n, e, U32.is_eq(n, 0))

law main.out:
  Nat

def main.out():
  0n

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|0n
