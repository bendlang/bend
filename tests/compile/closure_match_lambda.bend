# a bare match lambda passed as a closure value
# ported from bend3: the U32 switch becomes a Nat lambda-match (arm on
# Zero, catch-all tail on the whole value)
import Base

law run:
  (Nat -> U32) -> U32

def run():
  f => f(3n)

law main.out:
  U32

def main.out():
  run(\{Zero: 9; n => U32.add(U32.from_nat(n), 100)})

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|103
