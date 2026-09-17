# bend3's one-split pin: `match isz(n):` abstracted the call into the
# motive and the proof closed per arm. bend bans the computed match
# outright (a lambda-match application is a banned form), so the same
# spelling refuses at the flattener, and that refusal is the pin (the
# frozen worker-split spelling is pinned positively by
# check_computed_match_specialize)
import Base

law isz:
  for n: Nat
  Bool

def isz(n):
  match n:
    case Zero{}:
      True{}
    case Succ{p}:
      False{}

law orb:
  for a: Bool
  for b: Bool
  Bool

def orb(a, b):
  match a:
    case True{}:
      True{}
    case False{}:
      b

law or_true:
  for n: Nat
  {orb(isz(n), True{}) == True{} : Bool}

def or_true(n):
  match isz(n):
    case True{}:
      {==}
    case False{}:
      {==}

law main:
  Nat

def main():
  0n

#|Error:
#|- message  : a parameter or field scrutinee (a match cannot scrutinize a computed value: give it its own def)
#|Location:
#|36 | def or_true(n):
#|37>|   match isz(n):
#|38 |     case True{}:
#|exit 1
