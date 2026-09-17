# Witness for app_live's annotation-reading half.
#
# term_spine reads argument liveness off the callee's telescope when
# the head is a def Ref, and off each application's own Ann otherwise.
# The second rule only ever answers "erased" for a CLOSURE whose
# domain is erased, which needs a function value with an erased
# parameter -- pick's -x. Every closure in bench/ and the other demos
# has fully live parameters, so across all twelve programs that half
# returns false zero times; here it returns false twenty times.
#
# Note the neighbouring V1 wall: drop y and f(3n) has no live argument
# at all, and the emitter refuses a Var-headed spine. This witness
# keeps one live parameter so it compiles.
#
# Expect 4n.

import Base

law pick:
  for -x: Nat
  for  y: Nat
  Nat

def pick(x, y):
  y

law apply:
  for f: @-x: Nat -> @y: Nat -> Nat
  Nat

def apply(f):
  f(3n, 4n)

law main.out:
  Nat

def main.out():
  apply(pick)

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|4n
