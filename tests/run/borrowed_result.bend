# borrowed results, in the shapes that must fall back to a copy
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

# a part of its argument
def tail(c: Chain) -> Chain:
  match c:
    case CNil{}:
      CNil{}
    case CCons{h, t}:
      t

def nth(c: Chain, n: Nat) -> Chain:
  match c n:
    case c 0n:
      c
    case CNil{} 1n+p:
      CNil{}
    case CCons{h, t} 1n+p:
      nth(t, p)

# the holder is dropped while the part is used
def drop_first(n: Nat) -> U32:
  sum(nth(mk(n, 1, CNil{}), 2n), 0)

# the part outlives the holder in a constructor
def store(+c: Chain) -> Chain:
  CCons{sum(c, 0), nth(c, 1n)}

# the part is used after the holder is consumed
def after(+c: Chain) -> U32:
  +t = nth(c, 1n)
  (sum(t, 0) + sum(c, 0) + sum(t, 0) : U32)

# a part of a part
def deep(+c: Chain) -> U32:
  (sum(nth(nth(c, 1n), 1n), 0) + sum(c, 0) : U32)

# a wrapper tail-calls the accessor
def wrap(c: Chain) -> Chain:
  nth(c, 2n)

def use_wrap(+c: Chain) -> U32:
  (sum(wrap(c), 0) + sum(c, 0) : U32)

# one argument, two parts
def both(+c: Chain) -> U32:
  (sum(tail(c), 0) * 3 + sum(nth(c, 3n), 0) : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(drop_first(6n)))
    IO.print(U32.show(sum(store(mk(5n, 1, CNil{})), 0)))
    IO.print(U32.show(after(mk(5n, 1, CNil{}))))
    IO.print(U32.show(deep(mk(6n, 1, CNil{}))))
    IO.print(U32.show(use_wrap(mk(6n, 1, CNil{}))))
    IO.print(U32.show(both(mk(6n, 1, CNil{}))))

#|10
#|25
#|35
#|31
#|31
#|51
