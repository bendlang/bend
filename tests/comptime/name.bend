# a compile-time name: List.map takes its function as syntax (~f), and
# its type parameters too (~A, ~B: the function is concrete, so its type
# must be). the call mints List.map~0, a plain def with an erased binder
# per ~ parameter, and passes inc erased; the self-call with ~f lands on
# the same instance, so the loop is a plain recursive def in C and JS
import Base

def inc(n: Nat) -> Nat:
  1n+n

def sum(xs: List<Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      Nat.add(h, sum(t))

def main() -> IO(Unit):
  IO.print(Nat.show(sum(List.map(~Nat, ~Nat, ~inc, [1n, 2n, 3n]))))

#|9
