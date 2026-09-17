# an operator chain without a ": T" suffix is Nat: + - * / % < > <=
# >= spell Nat.add, Nat.mul, Nat.is_lt.. at the usual ladder
import Base

def f(a: Nat, b: Nat, c: Nat) -> Nat:
  a + b * c

def main(a: Nat, b: Nat) -> Bool:
  a < b

#|a => b => Cmp.is_lt(Nat.cmp(a, b))
