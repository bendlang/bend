# a template calls a template with its own ~f (map2 maps twice), a closed
# lambda argument may itself call a template with a closed lambda (z is
# the inner lambda's own binder), and a closed forward inside a template's
# text (incs passes ~inc) mints its instance at the template's definition
import Base

def inc(n: Nat) -> Nat:
  1n+n

def sum(xs: List<Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      Nat.add(h, sum(t))

def map2(~f: Nat -> Nat, xs: List<Nat>) -> List<Nat>:
  List.map(~Nat, ~Nat, ~f, List.map(~Nat, ~Nat, ~f, xs))

def incs(~f: Nat -> Nat, xs: List<Nat>) -> List<Nat>:
  List.map(~Nat, ~Nat, ~inc, List.map(~Nat, ~Nat, ~f, xs))

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def main() -> IO(Unit):
  a = sum(map2(~(x => Nat.mul(x, 2n)), [1n, 2n]))
  b = app(~(y => app(~(z => Nat.add(z, 1n)), y)), 3n)
  c = sum(incs(~inc, [1n, 2n, 3n]))
  IO.print(Nat.show(Nat.add(a, Nat.add(b, c))))

#|28
