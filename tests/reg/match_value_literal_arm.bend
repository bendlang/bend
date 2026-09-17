# a match VALUE mixing a literal arm with a point-free ref arm, built
# through the closure door (a hof argument) and consumed in a CUT
# position (an argument of the enclosing call). The applied bare form
# {\{..} : T}(n) is a banned lambda-match application now, so the mix
# rides the still-licensed value door (reg_match_pointfree pins the
# heap-datatype flavor)
import Base

law hof:
  for f: Nat -> Nat
  for x: Nat
  Nat

def hof(f, x):
  f(x)

law pf_arm:
  for n: Nat
  Nat

def pf_arm(n):
  hof(\{Zero: 1n; Succ: Nat.double}, n)

law main.out:
  U32

def main.out():
  U32.from_nat(pf_arm(3n))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|4
