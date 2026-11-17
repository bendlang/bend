# a part of a value read from an Array, across writes to the array
import Base

type Chain is Data:
  CNil{}
  CCons{k: U32, t: Chain}

def sum(c: Chain, acc: U32) -> U32:
  match c:
    case CNil{}:
      acc
    case CCons{h, t}:
      sum(t, (acc + h : U32))

def mk(n: Nat, +x: U32, acc: Chain) -> Chain:
  match n:
    case 0n:
      acc
    case 1n+p:
      mk(p, (x + 1 : U32), CCons{x, acc})

def nth(c: Chain, n: Nat) -> Chain:
  match c n:
    case c 0n:
      c
    case CNil{} 1n+p:
      CNil{}
    case CCons{h, t} 1n+p:
      nth(t, p)

# a part read, the array left alone
def peek(r: Array<Chain> & Chain) -> Array<Chain> & U32:
  (a, c) = r
  (a, sum(nth(c, 2n), 0))

# a part read, then the slot overwritten, then the part used
def stale(r: Array<Chain> & Chain) -> Array<Chain> & U32:
  (a, +c) = r
  +t = nth(c, 2n)
  a2 = Array.set(Chain, a, 1, CNil{})
  (a2, (sum(t, 0) + sum(t, 0) : U32))

# a part written back into the slot it came from
def trim(r: Array<Chain> & Chain) -> Array<Chain>:
  (a, c) = r
  Array.set(Chain, a, 1, nth(c, 2n))

# the whole value written back under a part of itself
def wrap(r: Array<Chain> & Chain) -> Array<Chain>:
  (a, +c) = r
  Array.set(Chain, a, 1, CCons{sum(nth(c, 1n), 0), c})

def out(r: Array<Chain> & U32) -> U32:
  (a, s) = r
  s

def fin(r: Array<Chain> & Chain) -> U32:
  (a, c) = r
  sum(c, 0)

def arr() -> Array<Chain>:
  Array.set(Chain, [CNil{} : Chain*4n], 1, mk(6n, 1, CNil{}))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(out(peek(Array.get(Chain, arr(), 1)))))
    IO.print(U32.show(out(stale(Array.get(Chain, arr(), 1)))))
    IO.print(U32.show(fin(Array.get(Chain, trim(Array.get(Chain, arr(), 1)), 1))))
    IO.print(U32.show(fin(Array.get(Chain, wrap(Array.get(Chain, arr(), 1)), 1))))

#|10
#|20
#|10
#|36
