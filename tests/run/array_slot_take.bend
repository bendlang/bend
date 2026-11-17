# values read from a slot and written back, in the shapes a take-and-put must get right
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

def has(c: Chain, +k: U32, f: Bool) -> Bool:
  match c f:
    case _ True{}:
      True{}
    case CNil{} False{}:
      False{}
    case CCons{h, t} False{}:
      has(t, k, U32.is_eq(h, k))

# the hashmap insert
def put(a: Array<Chain>, b: U32, k: U32, c: Chain, found: Bool) -> Array<Chain>:
  match found:
    case True{}:
      a
    case False{}:
      Array.set(Chain, a, b, CCons{k, c})

def ins(+b: U32, +k: U32, r: Array<Chain> & Chain) -> Array<Chain>:
  (a, +c0) = r
  put(a, b, k, c0, has(c0, k, False{}))

# the value written back twice into the cons
def dup(+b: U32, r: Array<Chain> & Chain) -> Array<Chain>:
  (a, +c) = r
  Array.set(Chain, a, b, CCons{sum(c, 0), CCons{7, c}})

# written to another slot: the old slot keeps it
def other(+b: U32, r: Array<Chain> & Chain) -> Array<Chain>:
  (a, c) = r
  Array.set(Chain, a, (b + 1 : U32), CCons{5, c})

# the slot is cleared, the value dropped
def clear(+b: U32, r: Array<Chain> & Chain) -> Array<Chain>:
  (a, c) = r
  Array.set(Chain, a, b, CNil{})

# two reads of one slot, one written back
def two.go(+b: U32, c1: Chain, r: Array<Chain> & Chain) -> U32 & Array<Chain>:
  (a, c2) = r
  (sum(c2, 0), Array.set(Chain, a, b, CCons{3, c1}))

def two(+b: U32, r: Array<Chain> & Chain) -> U32 & Array<Chain>:
  (a, c1) = r
  two.go(b, c1, Array.get(Chain, a, b))

# used after the write
def after(+b: U32, r: Array<Chain> & Chain) -> U32 & Array<Chain>:
  (a, +c) = r
  a2 = Array.set(Chain, a, b, CCons{4, c})
  (sum(c, 0), a2)

def fill(n: Nat, +j: U32, a: Array<Chain>) -> Array<Chain>:
  match n:
    case 0n:
      a
    case 1n+p:
      +b = (j * 7 % 8 : U32)
      fill(p, (j + 1 : U32), ins(b, (j * 5 % 13 : U32), Array.get(Chain, a, b)))

def tot.go(acc: U32, r: Array<Chain> & Chain) -> Array<Chain> & U32:
  (a, c) = r
  (a, (acc * 31 + sum(c, 0) : U32))

def tot.at(n: Nat, +i: U32, r: Array<Chain> & U32) -> U32:
  match n:
    case 0n:
      (a, acc) = r
      acc
    case 1n+p:
      (a, acc) = r
      tot.at(p, (i + 1 : U32), tot.go(acc, Array.get(Chain, a, i)))

def tot(n: Nat, i: U32, a: Array<Chain>, acc: U32) -> U32:
  tot.at(n, i, (a, acc))

def fst(r: U32 & Array<Chain>) -> U32:
  (s, a) = r
  (s + tot(8n, 0, a, 0) : U32)

def base() -> Array<Chain>:
  fill(40n, 0, [CNil{} : Chain*8n])

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(tot(8n, 0, base(), 0)))
    IO.print(U32.show(tot(8n, 0, dup(2, Array.get(Chain, base(), 2)), 0)))
    IO.print(U32.show(tot(8n, 0, other(2, Array.get(Chain, base(), 2)), 0)))
    IO.print(U32.show(tot(8n, 0, clear(2, Array.get(Chain, base(), 2)), 0)))
    IO.print(U32.show(fst(two(2, Array.get(Chain, base(), 2)))))
    IO.print(U32.show(fst(after(2, Array.get(Chain, base(), 2)))))

#|4040509212
#|804820503
#|4056209069
#|3181634682
#|4126396695
#|4155025846
