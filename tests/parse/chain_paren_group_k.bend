# the ": T" belongs to the parens around it: a tuple component or a
# list element with its own type takes its own parens, an index is
# U32 with no suffix, and a comparison chain answers Bool
import Base

def f(a: U32, b: U32, c: Nat) -> U32 & Nat:
  ((a + b : U32), c + 1n)

def g(a: U32, b: U32, n: Nat) -> Nat:
  U32.to_nat((a * b : U32)) + n

def h(a: U32, b: U32, c: U32) -> List<U32>:
  [(a + b : U32), (c << 1n : U32)]

def main(a: U32, b: U32, c: U32) -> Bool:
  (a + b < c : U32)

def m(xs: Array<U32>, i: U32, j: U32) -> Array<U32> & U32:
  xs[i + j]

#|a => b => c => Cmp.is_lt(U32.cmp(U32.add(a, b), c))
