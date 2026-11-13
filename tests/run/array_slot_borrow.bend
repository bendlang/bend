# a slot's value is still used after the slot is overwritten: the read must copy
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

def mk(n: Nat, +acc: Chain) -> Chain:
  match n:
    case 0n:
      acc
    case 1n+p:
      mk(p, CCons{U32.inc(sum(acc, 0)), acc})

# overwrite, then read the old value
def over(r: Array<Chain> & Chain) -> U32 & Array<Chain>:
  (a, c) = r
  a2 = Array.set(Chain, a, 3, mk(5n, CNil{}))
  (sum(c, 0), a2)

# drop the array, then read the value
def drop(r: Array<Chain> & Chain) -> U32:
  (a, c) = r
  sum(c, 0)

# the value escapes into the result
def keep(r: Array<Chain> & Chain) -> Array<Chain> & Chain:
  (a, c) = r
  (a, c)

# the value goes back into another slot
def move(r: Array<Chain> & Chain) -> Array<Chain>:
  (a, c) = r
  Array.set(Chain, a, 5, CCons{99, c})

# the value goes back into its own slot, twice over
def twice(r: Array<Chain> & Chain) -> Array<Chain>:
  (a, +c) = r
  Array.set(Chain, Array.set(Chain, a, 3, CCons{7, c}), 3, CCons{8, c})

def fin(r: Array<Chain> & Chain) -> U32:
  (a, c) = r
  sum(c, 0)

def t1.go(r: U32 & Array<Chain>) -> U32:
  (s, a2) = r
  (s + fin(Array.get(Chain, a2, 3)) : U32)

def t1(a: Array<Chain>) -> U32:
  t1.go(over(Array.get(Chain, a, 3)))

def t3.go(r: Array<Chain> & Chain) -> U32:
  (a, c) = r
  (sum(c, 0) + fin(Array.get(Chain, a, 3)) : U32)

def t3(a: Array<Chain>) -> U32:
  t3.go(keep(Array.get(Chain, a, 3)))

def t4.go(x: U32, r: Array<Chain> & Chain) -> U32:
  (a, c) = r
  (x + sum(c, 0) : U32)

def t4.mid(r: Array<Chain> & Chain) -> U32:
  (a, c) = r
  t4.go(sum(c, 0), Array.get(Chain, a, 3))

def t4(a: Array<Chain>) -> U32:
  t4.mid(Array.get(Chain, move(Array.get(Chain, a, 3)), 5))

def t5(a: Array<Chain>) -> U32:
  fin(Array.get(Chain, twice(Array.get(Chain, a, 3)), 3))

def arr() -> Array<Chain>:
  Array.set(Chain, [CNil{} : Chain*8n], 3, mk(4n, CNil{}))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(t1(arr())))
    IO.print(U32.show(drop(Array.get(Chain, arr(), 3))))
    IO.print(U32.show(t3(arr())))
    IO.print(U32.show(t4(arr())))
    IO.print(U32.show(t5(arr())))

#|46
#|15
#|30
#|129
#|23
