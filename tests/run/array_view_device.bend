# a bang builds a 2^16-cell array on the device, where a block over a page
# is aligned to a page only, and the host matches and sums it: the host
# splits a block in place only when it is aligned to its own size, so the
# halves give their parent back and the host's own array keeps its cells
import Base

def setk(+n: Nat, +i: U32, +k: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+q:
      setk(q, U32.inc(i), k, Array.set(U32, a, i, U32.add(i, k)))

def sum(a: Array<U32>) -> U32:
  match a:
    case ALeaf{x}:
      x
    case ANode{xs, ys}:
      U32.add(sum(xs), sum(ys))

def mk(+k: U32) -> Array<U32>:
  setk(1024n, 0, k, Array.new(U32, 16n, k))

def keep(a: Array<U32>, s: U32) -> Array<U32> & U32:
  (a, s)

def loop(+n: Nat, +k: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  match n:
    case 0n:
      r
    case 1n+q:
      (a, s) = r
      loop(q, U32.inc(k), keep(Array.set(U32, a, k, k), U32.add(s, sum(mk!(k)))))

def fin(r: Array<U32> & U32) -> String:
  (a, s) = r
  String.append(U32.show(s), String.append(" ", U32.show(sum(a))))

def main() -> IO(Unit):
  IO.print(fin(loop(4n, 0, (Array.new(U32, 16n, 7), 0))))

#|2488320 458730
