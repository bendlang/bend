# an argument lambda whose binder is named like a template binder (h):
# binders are ids, so the template's h is the field and the lambda's h
# its own parameter, no capture
import Base

def sum(xs: List<Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      Nat.add(h, sum(t))

def main() -> IO(Unit):
  n = sum(List.map(~Nat, ~Nat, ~(h => Nat.mul(h, 2n)), [1n, 2n, 3n]))
  IO.print(Nat.show(n))

#|12
