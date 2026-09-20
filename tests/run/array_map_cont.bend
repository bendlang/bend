# Array.map lowers in the C lane to workers over index ranges of one source
# and one destination, and its callback keeps every shape a body has: a
# parallel let, a call into a def with no arguments, a call that needs a
# continuation, a let, an element it passes on and one it ignores. The last
# row is wider than one leaf, so its walk forks.
import Base

def slow(+d: Nat) -> U32:
  match d:
    case 0n:
      3
    case 1n+p:
      a b = slow(p) slow(p)
      U32.add(a, b)

def k() -> U32:
  slow(3n)

def rd(r: Array<U32> & U32) -> U32:
  (a, x) = r
  x

def u32s(xs: List<U32>) -> String:
  List.show(~&1, ~U32, ~(x => U32.show(x)), xs)

def strs(xs: List<String>) -> String:
  List.show(~&1, ~String, ~(s => s), xs)

def main() -> IO(Unit):
  do IO<Unit>:
    forks : Array<U32> = Array.map(~U32, ~U32, ~(x =>
      a b = U32.add(x, 1) U32.mul(7, 2)
      U32.add(a, b)), Array.set(U32, [3 : U32*4n], 1, 10))
    IO.print(u32s(Array.to_list(~U32, forks)))
    consts : Array<U32> = Array.map(~U32, ~U32, ~(x => U32.add(x, k())),
      [1 : U32*2n])
    IO.print(u32s(Array.to_list(~U32, consts)))
    slows : Array<U32> = Array.map(~Nat, ~U32, ~(n => slow(n)),
      Array.set(Nat, [1n : Nat*4n], 2, 4n))
    IO.print(u32s(Array.to_list(~U32, slows)))
    lets : Array<U32> = Array.map(~U32, ~U32, ~(x =>
      y = U32.mul(x, 3)
      U32.add(y, 1)), Array.set(U32, [3 : U32*4n], 1, 10))
    IO.print(u32s(Array.to_list(~U32, lets)))
    same : Array<String> = Array.map(~String, ~String, ~(s => s),
      Array.set(String, ["ab" : String*4n], 3, "xyz"))
    IO.print(strs(Array.to_list(~String, same)))
    gone : Array<U32> = Array.map(~String, ~U32, ~(s => 7),
      Array.set(String, ["ab" : String*2n], 1, "xyz"))
    IO.print(u32s(Array.to_list(~U32, gone)))
    wide : Array<U32> = Array.map(~U32, ~U32, ~(x => U32.add(x, 1)),
      Array.set(U32, [0 : U32*8192n], 8191, 41))
    IO.print(U32.show(rd(Array.get(U32, wide, 8191))))

#|[18, 25, 18, 18]
#|[25, 25]
#|[6, 6, 48, 6]
#|[10, 31, 10, 10]
#|[ab, ab, ab, xyz]
#|[7, 7]
#|42
