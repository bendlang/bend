# a + field is reusable under a Lone holder: matching a plain p hands
# out a Many a (the goal binder is field times scrutinee), so a is
# consumed twice; MkP{3n} charges its argument once (certify-once).
import Base

type P is Data:
  MkP{+a: Nat}

law dbl:
  for p: P
  Nat

def dbl(p):
  match p:
    case MkP{a}:
      Nat.add(a, a)

law main:
  Nat

def main(): dbl(MkP{3n})

#|6n
