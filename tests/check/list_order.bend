# the checker grows a call's arguments, a constructor's fields and a def's
# binders as lists that copy nothing. Each must still come out in source
# order: the template takes its ~ argument off the front of the call and
# leaves the rest, the self-call reads its columns left to right, a field's
# type and the recursion's left-hand side see the fields in place, and a
# match on a later binder keeps the binders before it, in order.
import Base

type T is Data:
  K{a: U32, b: U32, next: T}
  L{}

def apply3(~f: U32 -> U32 -> U32 -> U32, x: U32, y: U32, z: U32) -> U32:
  f(x, y, z)

def join3(x: U32, y: U32, z: U32) -> U32:
  (100 * x + 10 * y + z : U32)

def inc(x: U32) -> U32:
  (x + 1 : U32)

# the instance's self-call descends on what the ~ argument leaves: k, then n
def rep(~f: U32 -> U32, +k: U32, n: Nat) -> U32:
  match n:
    case 0n:
      k
    case 1n+p:
      f(rep(f, k, p))

def digits(t: T) -> U32:
  match t:
    case K{a, b, next}:
      (100 * a + 10 * b + digits(next) : U32)
    case L{}:
      0

def walk(+a: U32, +b: U32, t: T) -> U32:
  match t:
    case K{x, y, next}:
      (a * x + b * y + walk(a, b, next) : U32)
    case L{}:
      (a - b : U32)

def absurd(x: U32, e: Empty) -> U32:
  y = {\{} : Unit -> U32};
  x

# the Empty binder sits on the scope tree's right side here, not its left
def absurd_late(x: U32, w: U32, e: Empty) -> U32:
  y = {\{} : Unit -> U32};
  x

# the second column's binder is c: b, between them, stays out of it
def skip(a: U32, b: U32, c: U32) -> U32:
  match a, c:
    case x, y:
      (100 * x + y : U32)

def tree() -> T:
  K{1, 2, K{3, 4, L{}}}

def main() -> U32:
  (apply3(join3, 1, 2, 3) + 1000 * digits(tree()) + 1000000 * walk(5, 3, tree()) + 1000000000 * rep(inc, 1, 2n) + skip(1, 2, 3) : U32)

#|3040460226
