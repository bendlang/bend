# A call fixed for a loop (loop_fixed_call) still runs where the def first
# reached it, and after the statements before it. The loop turns once; its
# arm first binds a call that passes the Nat wall, then holds a fixed call
# that never returns. The program stops with the Nat message, as it does
# when every turn makes the calls in that order. The count is the command
# line's length (1 in the harness), which no compiler sees.
import Base

def boom(+n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n+p:
      boom(p, Nat.mul(Nat.mul(acc, 65536n), Nat.mul(65536n, 65536n)))

@unsafe
def hang(n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n+p:
      hang(Nat.add(p, 1n), acc)

def stop(+i: Nat, +k: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      acc
    case 1n+p:
      x = boom(i, 1n)
      stop(p, k, Nat.add(Nat.add(acc, x), hang(k, 1n)))

def run(+one: Nat) -> Nat:
  stop(one, one, 7n)

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(Nat.show(run(List.length(&1, String, xs))))

#|bend: a Nat past the largest immediate 2^48-1
#|exit 1
