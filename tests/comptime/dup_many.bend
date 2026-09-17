# a compile-time lambda using its parameter twice duplicates the
# argument's syntax: under a + domain the two uses of x are licensed
import Base

def app(~f: Nat -> Nat, +x: Nat) -> Nat:
  f(x)

def main() -> IO(Unit):
  IO.print(Nat.show(app(~(y => Nat.add(y, y)), 3n)))

#|6
