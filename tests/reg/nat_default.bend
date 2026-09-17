# a Nat match goes out as one flat if/else-if over the word, so a
# default arm's binder at level n is the word minus n, whether the
# default sits under a literal pattern or closes a Succ pattern's
# tail. Both defaults here use their binder, and 4n+k binds k to the
# word minus 4. The three lanes must agree.
import Base

def f(c: Nat) -> Nat:
  match c:
    case 3n:
      100n
    case 5n:
      200n
    case k:
      Nat.add(k, 1n)

def g(c: Nat) -> U32:
  match c:
    case 0n:
      7
    case 2n:
      9
    case 4n+k:
      U32.from_nat(k)
    case k:
      (U32.from_nat(k) * 10 : U32)

def main() -> IO(Unit):
  a = (U32.from_nat(f(U32.to_nat(3))) * 1000000
    + U32.from_nat(f(U32.to_nat(5))) * 10000 : U32)
  b = (U32.from_nat(f(U32.to_nat(10))) * 100 + U32.from_nat(f(0n)) : U32)
  c = (g(0n) + g(1n) * 10 + g(2n) * 100 + g(3n) * 1000 + g(9n) * 10000 : U32)
  IO.print(U32.show((a + b : U32)) ++ " " ++ U32.show(c))

#|102001101 81007
