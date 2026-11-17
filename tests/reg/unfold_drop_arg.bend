# regression witness: emit_unfold folded a call whose literal selector picked
# an arm that does not use a live, non-constant argument, and the dead let it
# wrapped around the arm was dropped, so the C lane never evaluated the
# argument: it printed 100 where the interpreter and JS evaluate boom and stop
# at the Nat wall. The unfold is now refused when a probe is unused.
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
    IO.print(Nat.show(pick(boom(k), 0n, 100n)))

#|bend: a Nat past the largest immediate 2^48-1
#|exit 1
