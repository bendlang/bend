# a ~ lambda whose binder is named like a caller local is closed by
# construction (the lambda's x is its own binder), and so is a let inside
# it reusing a caller local's name
import Base

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def g(x: Nat) -> Nat:
  app(~(x => Nat.add(x, 1n)), x)

def h(k: Nat) -> Nat:
  app(~(y => (k = {1n : Nat}; Nat.add(y, k))), k)

def main() -> IO(Unit):
  IO.print(Nat.show(Nat.add(g(3n), h(3n))))

#|8
