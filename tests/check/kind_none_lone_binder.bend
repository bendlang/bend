# the kind order counts &0 and &1 as one rung: a single use is what
# every type affords, so a datatype declared Kind(&0) fits a plain
# (Lone) binder; only Data (&2) licenses a + binder, which refuses
import Base

type Z is Kind(&0):
  Mk{}

def f(x: Z) -> Z:
  x

def g(+x: Z) -> Z:
  x

def main() -> Nat:
  0n

#|Error:
#|- expected : Data
#|- observed : Kind(&0)
#|Location: g
#|11 | 
#|12>| def g(+x: Z) -> Z:
#|13 |   x
#|exit 1
