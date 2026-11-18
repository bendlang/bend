# control for unfold_drop_arg: the same call with a run-time zero selector is
# not unfolded, so every lane already evaluated boom before the fix. Only the
# selector's constness differs from the regression test.
import Base

def boom(+k: Nat) -> Nat:
  Nat.mul(Nat.mul(k, k), Nat.mul(k, k))

def pick(x: Nat, y: Nat, z: Nat) -> Nat:
  match y:
    case 0n:
      z
    case 1n+p:
      x

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +k : Nat = Nat.add(100000n, List.length(&1, String, args))
    IO.print(Nat.show(pick(boom(k), Nat.sub(k, k), 100n)))

#|bend: a Nat past the largest immediate 2^48-1
#|exit 1
