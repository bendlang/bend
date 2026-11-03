# A lambda passed to a def that cannot reach itself is inlined, so no
# closure is built: through a match on a runtime value (its arguments
# left and the let's rest move into the arms), a capture, two callbacks
# inside a callback, a function chosen by a match, and a lambda applied
# in place. Arguments that are no values are bound, so they run once.
import Base

type Shape is Data:
  Dot{}
  Line{n: U32}
  Box{w: U32, h: U32}

def choose(-A: Type, flag: Bool, a: A, b: A) -> A:
  match flag:
    case False{}:
      b
    case True{}:
      a

def invoke(-A: Type, -B: Type, f: A -> B, x: A) -> B:
  f(x)

def both(f: U32 -> U32, g: U32 -> U32, x: U32) -> U32:
  f(g(x))

def area(s: Shape, k: U32 -> U32) -> U32:
  match s:
    case Dot{}:
      k(1)
    case Line{n}:
      k(n)
    case Box{w, h}:
      k((w * h : U32))

def maybe_add(m: Maybe<U32>, f: U32 -> U32) -> U32:
  match m:
    case None{}:
      0
    case Some{v}:
      f(v)

def shape.go(m: U32, i: U32) -> Shape:
  match m:
    case 0:
      Dot{}
    case 1:
      Line{i}
    case k:
      Box{i, k}

def shape(+i: U32) -> Shape:
  shape.go(U32.mod(i, 3), i)

def step(+x: U32, +i: U32) -> U32:
  +a = invoke(U32, U32, y => (y + x : U32), (i * 3 : U32))
  f = choose(U32 -> U32, U32.is_zero(U32.and(i, 1)), y => (y + 7 : U32), y => (y * 3 : U32))
  +b = f(a)
  +c = choose(U32 -> U32, U32.is_eq(U32.mod(i, 4), 1), y => U32.xor(y, x), y => y)(b)
  +d = area(shape(i), w => both(z => (z + w : U32), z => (z * 5 : U32), c))
  +e = maybe_add(choose(Maybe<U32>, U32.is_lt(U32.mod(i, 4), 2), Some{d}, None{}), v => (v + i : U32))
  (u => (e + u : U32))(1)

def loop(n: Nat, +x: U32, +i: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+p:
      loop(p, U32.xor(step(x, i), U32.mul(x, 31)), (i + 1 : U32))

def main() -> U32:
  loop(40n, 1, 0)

#|3122355429
