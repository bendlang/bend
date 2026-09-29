# regression witness: a spin (a leaf loop) reads the location of an array
# param that each of its jumps passes back as is once, before its loop:
# tot, and bump over a fork's shared handle (a redirect, whose count the
# fork's other leaves move meanwhile). swap trades its two arrays each
# turn, so it passes neither back as is and reads each turn's own: its
# writes alternate (1030 and 204; 1234 and 0 had it kept the first
# array's). The fork's four leaves each add 3 to every cell (12 each).
# The turns come from an array's size, so no loop unrolls.
import Base

def turns(r: Array<U32> & U32) -> Nat:
  (a, +n) = r
  U32.to_nat(n)

def swap(+n: Nat, a: Array<U32>, b: Array<U32>, +i: U32) -> Array<U32> & Array<U32>:
  match n:
    case 0n:
      (a, b)
    case 1n+p:
      swap(p, b, Array.set(U32, a, i, (i + 1 : U32)), (i + 1 : U32))

# r holds the array and its entry at i: acc, then that entry and the n
# after it, as decimal digits.
def tot.go(+n: Nat, +i: U32, +acc: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  match n:
    case 0n:
      (a, +x) = r
      (a, (acc * 10 + x : U32))
    case 1n+p:
      (a, +x) = r
      +q = (i + 1 : U32)
      tot.go(p, q, (acc * 10 + x : U32), a[q])

def tot(a: Array<U32>) -> Array<U32> & U32:
  tot.go(3n, 0, 0, a[0])

# r holds the array (and a count read before): one more at each of the
# k entries from j, wrapping.
def bump(+k: Nat, +j: U32, r: Array<U32> & U32) -> Array<U32>:
  match k:
    case 0n:
      (a, +c) = r
      a
    case 1n+p:
      (a, +c) = r
      bump(p, (j + 1 : U32), Array.atomic.add(a, j, 1))

# fa holds two handles to one array: d levels of forks down to leaves
# that each bump both of theirs k times.
def fan(+d: Nat, +k: Nat, fa: Array<U32> & Array<U32>) -> Array<U32>:
  match d:
    case 0n:
      (x, y) = fa
      Array.join(U32, bump(k, 0, (x, 0)), bump(k, 0, (y, 0)))
    case 1n+p:
      (x, y) = fa
      l r = fan(p, k, Array.fork(U32, x)) fan(p, k, Array.fork(U32, y))
      Array.join(U32, l, r)

def show(r: Array<U32> & U32) -> IO(Unit):
  (a, x) = r
  IO.print(U32.show(x))

def both(p: Array<U32> & Array<U32>) -> IO(Unit):
  (a, b) = p
  do IO<Unit>:
    Unit <- show(tot(a))
    show(tot(b))

def main() -> IO(Unit):
  do IO<Unit>:
    +n : Nat <- IO.pure(Nat, turns(Array.size(U32, [0 : U32*4n])))
    Unit <- both(swap(n, [0 : U32*4n], [0 : U32*4n], 0))
    show(tot(fan!(1n, Nat.mul(n, 3n), Array.fork(U32, [0 : U32*4n]))))

#|1030
#|204
#|13332
