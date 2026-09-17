# an operator chain without a ": T" suffix is Nat: + - * / % < > <=
# >= spell Nat.add, Nat.mul, Nat.is_lt.. at the usual ladder
import Base

def f(a: Nat, b: Nat, c: Nat) -> Nat:
  a + b * c

def g(a: Nat, b: Nat) -> Bool:
  a < b

def main() -> IO(Unit):
  IO.print(Nat.show(f(1n, 2n, 3n)))

#|7
