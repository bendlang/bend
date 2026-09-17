# a compile-time lambda is a macro: applied at its name, its body takes
# the argument at parse (a Sub node, resolved at the raise), so a
# constructor body ([x]) lands in its check position and checks there;
# a partial application (Nat.add(10n)) is a closed term too
import Base

def sum(xs: List<Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      Nat.add(h, sum(t))

def flat(xs: List<List<Nat>>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      Nat.add(sum(h), flat(t))

def main() -> IO(Unit):
  a = sum(List.map(~Nat, ~Nat, ~(x => Nat.mul(x, 2n)), [1n, 2n, 3n]))
  b = flat(List.map(~Nat, ~List<Nat>, ~(x => [x]), [1n, 2n]))
  c = sum(List.map(~Nat, ~Nat, ~Nat.add(10n), [1n, 2n]))
  IO.print(Nat.show(Nat.add(a, Nat.add(b, c))))

#|38
