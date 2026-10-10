# A shared box of a flat type unboxes once, at its binding. The cut h =
# mf(True{}) is a box (mf returns a family at an open index) whose type at
# the closed index is the flat Maybe<&2, U32>; a fork's call and the body
# share it. The unbox once ran at the first sharing pop, after the fork's
# frame had laid h out as one word: the next frame popped two, read the box
# as a tag, and the sequential path (BEND_THREADS=1, or a task the pool drains)
# printed 12 for 18. rr(10n) forks 1024 leaves, which the pool drains
# sequentially at any thread count. Expect 1 + 10 + 7 = 18, then 1024 * 18.

import Base

law Fm:
  for x: Bool
  Data

def Fm(x):
  match x:
    case False{}:
      Bool
    case True{}:
      Maybe<&2, U32>

def mf(n: Bool) -> Fm(n):
  match n:
    case False{}:
      String.eq("a", "b")
    case True{}:
      Some{7}

def use(m: Maybe<&2, U32>) -> U32:
  match m:
    case None{}:
      0
    case Some{v}:
      v

def g2(m: Maybe<&2, U32>, x: U32) -> U32:
  (use(m) + x : U32)

def one(b: Bool) -> U32:
  1

def r() -> U32:
  +h = {mf(True{}) : Maybe<&2, U32>}
  a b = one(True{}) g2(h, 3)
  ((a + b : U32) + use(h) : U32)

law rr:
  for +d: Nat
  U32

def rr(d):
  match d:
    case 0n:
      r()
    case 1n+p:
      a b = rr(p) rr(p)
      (a + b : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(r()))
    IO.print(U32.show(rr(10n)))

#|18
#|18432
