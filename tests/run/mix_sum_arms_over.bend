# the sum passes 2^48-1 at a leaf reached through a copied arm: the Nat message, exit 1
import Base

def leaves(+d: Nat, +v: Nat) -> Nat:
  match d:
    case 0n:
      v
    case 1n+p:
      Nat.add(leaves(p, v), leaves(p, v))

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(Nat.show(leaves(Nat.mul(16n, List.length(&1, String, xs)), Nat.add(4294967295n, 2n))))

#|bend: a Nat past the largest immediate 2^48-1
#|exit 1
