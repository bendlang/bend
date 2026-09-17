# the sugar program's surface in one book: infix arithmetic and
# bitwise (dotted) and logical operators, shifts, comparisons,
# list literals and cons and ++, array read/write, and
# the parallel let -- floats keep their own family (stuck in the
# interp). if/elif/else is gone with the lambda-match application
# ban: the branch points are spelled as their own defs matching a
# Bool param. a re-tested binder rides + (U32 is Data)
import Base

law cmp.b:
  for f: Bool
  U32

def cmp.b(f):
  match f:
    case True{}:
      200
    case False{}:
      300

law cmp.a:
  for +x: U32
  for  f: Bool
  U32

def cmp.a(x, f):
  match f:
    case True{}:
      100
    case False{}:
      cmp.b((x < 6 : U32))

law cmp:
  for +x0: U32
  U32

def cmp(x0):
  cmp.a(x0, (x0 < 3 : U32))

law getat.go:
  for r: Array<U32> & U32
  U32

def getat.go(r):
  (a2, got) = r
  got

law getat:
  for a: Array<U32>
  for i: U32
  U32

def getat(a, i):
  getat.go(a[i])

law csum:
  for xs  : List<&2, U32>
  for acc : U32
  U32

def csum(xs, acc):
  match xs:
    case h <> t:
      csum(t, (10 * acc + h : U32))
    case Nil{}:
      acc

law pick12:
  for f: Bool
  U32

def pick12(f):
  match f:
    case True{}:
      1
    case False{}:
      2

law main.out:
  U32

def main.out():
  arr = [0 : U32*4n];
  x y = cmp(1) cmp(9)
  a = (2 + 3 * 4 : U32)
  b = (1 << 3n : U32)
  c = (6 .&. 3 .|. 8 .^. 12 : U32)
  d = csum([1, 2, (7 - 4 : U32)], 0)
  s = "ab" ++ "cd"
  g = getat(arr[1] <- 5, 1)
  (a + b + c + d + pick12((20 < 8 : U32) || True{} && False{}) + U32.from_nat(String.length(s)) + x + y + g : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|562
