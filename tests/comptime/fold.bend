# a two-argument macro: f(h, acc) substitutes h at parse and leaves the
# second application to the checker's beta step (infer-app on a lambda
# head); a def name works the same. the list precedes the accumulator:
# descent reads the live columns left to right
import Base

def fold(~f: Nat -> Nat -> Nat, xs: List<Nat>, acc: Nat) -> Nat:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      fold(~f, t, f(h, acc))

def main() -> IO(Unit):
  a = fold(~(a => b => Nat.add(a, b)), [1n, 2n, 3n], 0n)
  b = fold(~Nat.add, [2n, 3n, 4n], 1n)
  IO.print(Nat.show(Nat.add(a, b)))

#|16
