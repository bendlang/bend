# an Array parameter that nothing owns is lent, like any other boxed one, and
# a lend leaves the array whole: peek lends a handle twice and first still
# reads 12 (7 + 12), poke writes through the handle after a lend (7 + 18), a
# read after a write sees it through the other handle (18 + 18), and go lends
# one array down a loop of five calls without using it up (5)
import Base

@unsafe
def peek(+a: Array<U32>, +b: Array<U32>) -> U32:
  7

def val(r: Array<U32> & U32) -> U32:
  (b, v) = r
  v

def first(a: Array<U32>) -> U32:
  val(Array.get(U32, a, 0))

def poke(a: Array<U32>) -> Array<U32>:
  Array.set(U32, a, 0, 18)

@unsafe
def twice(+a: Array<U32>) -> U32:
  U32.add(peek(a, a), first(a))

@unsafe
def write(+a: Array<U32>) -> U32:
  U32.add(peek(a, a), first(poke(a)))

@unsafe
def read_after(+a: Array<U32>) -> U32:
  +x = first(poke(a))
  U32.add(x, first(a))

@unsafe
def lend(+a: Array<U32>, +x: U32) -> U32:
  U32.add(x, 1)

@unsafe
def go(+a: Array<U32>, n: Nat, +s: U32) -> U32:
  match n:
    case 0n:
      s
    case 1n+p:
      go(a, p, lend(a, s))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(twice(Array.new(U32, 3n, 12))))
    Unit <- IO.print(U32.show(write(Array.new(U32, 3n, 12))))
    Unit <- IO.print(U32.show(read_after(Array.new(U32, 3n, 12))))
    IO.print(U32.show(go(Array.new(U32, 3n, 12), 5n, 0)))

#|19
#|25
#|36
#|5
