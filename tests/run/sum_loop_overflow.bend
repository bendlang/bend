# A sum carried through two calls (sum_loop_calls) stops at the same wall as
# the recursion it replaces: fifteen equal parts of 2^48-1 over a tree of
# depth 3 land on the limit, and here the root adds one more. The loop meets
# the wall at a later add than the recursion would, with the same message.
# The depth and the extra one come from the command line's length (1 in the
# harness), which no compiler sees.
import Base

def big() -> Nat:
  Nat.add(Nat.mul(16777215n, 16777216n), 16777215n)

def t15(+d: Nat, +v: Nat, +top: Nat) -> Nat:
  match d:
    case 0n:
      v
    case 1n+p:
      Nat.add(Nat.add(v, top), Nat.add(t15(p, v, 0n), t15(p, v, 0n)))

def run(+one: Nat) -> Nat:
  t15(Nat.mul(3n, one), Nat.div(big(), 15n), one)

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(Nat.show(run(List.length(&1, String, xs))))

#|bend: a Nat past the largest immediate 2^48-1
#|exit 1
