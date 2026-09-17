# an operator chain without a ": T" suffix is Nat: + - * / % < > <=
# >= spell Nat.add, Nat.mul, Nat.is_lt.. at the usual ladder
import Base

def main(a: Nat, b: Nat, c: Nat) -> Nat:
  a + b * c

def g(a: Nat, b: Nat) -> Bool:
  a < b

#|a => b => c => Nat.add(a, Nat.mul(b, c))
