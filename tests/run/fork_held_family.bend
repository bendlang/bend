# A fork holds the same values on both of its paths. The cut h = mf(True{})
# is a box (mf returns a family at an open index) whose type at the closed
# index is the word U32. The parallel path holds it boxed for the joiner;
# the sequential path once rebound it through the shared-box unboxing rule,
# whose count the hold itself inflated, then dropped it as a dead word, and
# the join died with 'a fork's paths hold different values'. Expect 1 + 3.

import Base

law Fm:
  for x: Bool
  Data

def Fm(x):
  match x:
    case False{}:
      Bool
    case True{}:
      U32

def mf(n: Bool) -> Fm(n):
  match n:
    case False{}:
      String.eq("a", "b")
    case True{}:
      7

def g(+q: Bool, a: Fm(q), x: U32) -> U32:
  x

def one(b: Bool) -> U32:
  1

def r() -> U32:
  a b = one(True{}) g(True{}, mf(True{}), 3)
  (a + b : U32)

def main() -> IO(Unit):
  IO.print(U32.show(r()))

#|4
