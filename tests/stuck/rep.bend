# a def that returns a lambda: rep(2n+x) unfolds twice under the
# returned binder and sticks on x, so the goal is k => rep(x, 2n+k):
# the stuck call applied to the rebuilt counter (the printer spells
# the curried application as one call), under the binder.
import Base

law rep:
  for n: Nat
  Nat -> Nat

def rep(n):
  match n:
    case 0n:
      k => k
    case 1n+p:
      k => rep(p)(1n+k)

law main:
  @x:Nat -> Nat -> Nat

def main():
  x => rep(2n+x)

#|x => k => rep(x, 2n+k)
