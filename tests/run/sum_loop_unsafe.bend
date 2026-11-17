# run_sum_loop_unsafe: a sum loop keeps its def's @unsafe. wsum's tail is an
# add of its self call, so it goes on in wsum~acc, and a call fixed for that
# recursion is computed once unless the def is @unsafe and the call reads a
# parameter that holds an Array: here a is one handle, each turn writes a[0]
# and then reads it back through asum, so the read is not fixed. wrote is
# the same loop with the sum already a parameter.
import Base

def asum(+n: Nat, w: Array<U32> & U32, acc: U32) -> U32:
  match n:
    case 0n:
      (a, v) = w
      U32.add(acc, v)
    case 1n+p:
      (a, v) = w
      asum(p, Array.get(U32, a, U32.from_nat(p)), U32.add(acc, v))

@unsafe
def wrote(+i: Nat, +a: Array<U32>, +m: Nat, acc: U32) -> U32:
  match i:
    case 0n:
      acc
    case 1n+p:
      +w = asum(0n, Array.get(U32, Array.set(U32, a, 0, U32.from_nat(i)), 0), 0)
      wrote(p, a, m, U32.add(U32.add(acc, w), asum(m, Array.get(U32, a, 0), 0)))

@unsafe
def wsum(+i: Nat, +a: Array<U32>, +m: Nat) -> U32:
  match i:
    case 0n:
      0
    case 1n+p:
      +w = asum(0n, Array.get(U32, Array.set(U32, a, 0, U32.from_nat(i)), 0), 0)
      +r = asum(m, Array.get(U32, a, 0), 0)
      U32.add(U32.add(w, r), wsum(p, a, m))

def show(+one: Nat) -> String:
  +t = Nat.mul(20n, one)
  String.join([
    U32.show(wrote(t, Array.new(U32, 3n, 1), Nat.mul(7n, one), 0)),
    U32.show(wsum(t, Array.new(U32, 3n, 1), Nat.mul(7n, one)))], "\n")

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(show(Nat.add(1n, List.length(&1, String, xs))))

#|3760
#|3760
