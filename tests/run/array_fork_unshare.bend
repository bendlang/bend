# a fork made by a safe main (Array.fork inlines, so BLK_SHR comes from
# the hot Array fact, not from a live @unsafe def): a write through one
# handle read through the other (7), a clone through a handle is
# (original, copy) on every lane (5, then 7 through the other handle),
# a match on a handle copies its half (9, the other handle still 7),
# and a match on the handle a join leaves (a half of 2). Then a boxed
# fork: a set through one handle read through the other (4), a match
# through each handle (4, 4: the last drop frees the block)
import Base

def show(r: Array<U32> & U32) -> IO(Unit):
  (b, v) = r
  IO.print(U32.show(v))

def lo(a: Array<U32>) -> Array<U32>:
  match a:
    case ALeaf{x}:
      ALeaf{x}
    case ANode{xs, ys}:
      xs

def s5(h: Array<U32>, r: Array<U32> & U32) -> IO(Unit):
  (b, v) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(v))
    show(Array.size(U32, lo(Array.join(U32, b, h))))

def s4(b: Array<U32>, r: Array<U32> & U32) -> IO(Unit):
  (h, v) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(v))
    s5(h, Array.get(U32, b, 0))

def s3(a: Array<U32>, c: Array<U32>, r: Array<U32> & U32) -> IO(Unit):
  (b, v) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(v))
    s4(b, Array.get(U32, Array.set(U32, lo(a), 0, 9), 0))

def s2(a: Array<U32>, b: Array<U32>, r: Array<U32> & U32) -> IO(Unit):
  (c, v) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(v))
    s3(a, c, Array.get(U32, b, 0))

def s1(b: Array<U32>, q: Array<U32> & Array<U32>) -> IO(Unit):
  (a, c) = q
  s2(a, b, Array.get(U32, Array.set(U32, c, 0, 5), 0))

def s0(a: Array<U32>, r: Array<U32> & U32) -> IO(Unit):
  (b, v) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(v))
    s1(b, Array.clone(U32, a))

def go(p: Array<U32> & Array<U32>) -> IO(Unit):
  (a, b) = p
  s0(Array.set(U32, a, 0, 7), Array.get(U32, b, 0))

def first(a: Array<Nat>) -> Nat:
  match a:
    case ALeaf{x}:
      x
    case ANode{xs, ys}:
      first(xs)

def t2(a: Array<Nat>, r: Array<Nat> & Nat) -> IO(Unit):
  (b, v) = r
  do IO<Unit>:
    Unit <- IO.print(Nat.show(v))
    Unit <- IO.print(Nat.show(first(a)))
    IO.print(Nat.show(first(b)))

def t1(p: Array<Nat> & Array<Nat>) -> IO(Unit):
  (a, b) = p
  t2(Array.set(Nat, a, 0, 4n), Array.get(Nat, b, 0))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- go(Array.fork(U32, Array.new(U32, 2n, 1)))
    t1(Array.fork(Nat, Array.new(Nat, 1n, 3n)))

#|7
#|5
#|7
#|9
#|7
#|2
#|4
#|4
#|4
