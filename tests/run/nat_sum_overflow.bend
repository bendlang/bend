# A sum carried by a loop (nat_sum_loop) stops at the same wall as the
# recursion it replaces: 255 steps of (2^48-1) / 255 land on 2^48-1, and
# the step count here is one more. The count is scaled by the command
# line's length (1 in the harness), which no compiler sees.
import Base

def big() -> Nat:
  Nat.add(Nat.mul(16777215n, 16777216n), 16777215n)

def edge(+n: Nat, +x: Nat) -> Nat:
  match n:
    case 0n:
      x
    case 1n+p:
      Nat.add(x, edge(p, x))

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(Nat.show(edge(Nat.mul(255n, List.length(&1, String, xs)), Nat.div(big(), 255n))))

#|bend: a Nat past the largest immediate 2^48-1
#|exit 1
