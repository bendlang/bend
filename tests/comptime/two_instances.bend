# two calls with different arguments mint two instances; a call whose
# arguments print the same as an earlier one shares its instance, so
# there is no third
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
  a = sum(List.map(~Nat, ~Nat, ~inc, [1n, 2n, 3n]))
  b = sum(List.map(~Nat, ~Nat, ~(x => Nat.mul(x, 2n)), [1n, 2n, 3n]))
  c = sum(List.map(~Nat, ~Nat, ~inc, [4n]))
  d = sum(List.map(~Nat, ~Nat, ~(x => Nat.mul(x, 2n)), [4n]))
  IO.print(Nat.show(Nat.add(a, Nat.add(b, Nat.add(c, d)))))

#|34
