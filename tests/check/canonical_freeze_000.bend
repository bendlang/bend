# bend3's freeze law: a canonical computed scrutinee must NOT rewrite
# a coincidental spelling in a hypothesis (the (Z,Z) corner tautology
# corruption); bend freezes unconditionally -- a computed scrutinee
# lives behind its own def whose assert states the goal, so the arms'
# goal stays unrewritten and the ORIGINAL hypothesis discharges both,
# the corruption unspellable
import Base

law f9.go:
  for -n: Bool
  for  e: {Bool.and(n, False{}) == False{} : Bool}
  for  w: Bool
  {Bool.and(n, False{}) == False{} : Bool}

def f9.go(n, e, w):
  match w:
    case True{}:
      e
    case False{}:
      e

law f9:
  for n: Bool
  for e: {Bool.and(n, False{}) == False{} : Bool}
  {Bool.and(n, False{}) == False{} : Bool}

def f9(n, e):
  f9.go(n, e, Bool.and(n, False{}))

law main.out:
  Nat

def main.out():
  0n

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|0n
