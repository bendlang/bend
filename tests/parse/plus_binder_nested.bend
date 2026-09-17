# the + binder in a nested constructor pattern, a list pattern, a tuple
# let and a constructor let
import Base

type Box is Data:
  Box{v: U32}

def sum2(xs: List<(U32 & U32)>) -> U32:
  match xs:
    case Nil{}:
      0
    case Tuple{+a, b} <> t:
      (a * a + b + sum2(t) : U32)

def two(xs: List<U32>) -> U32:
  match xs:
    case [+u, v]:
      (u * u + v : U32)
    case _:
      0

def pair(pq: U32 & U32) -> U32:
  (+p, q) = pq
  (p * p + q : U32)

def box(bx: Box) -> U32:
  Box{+m} = bx
  (m * m : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show((pair((3, 4)) + box(Box{5}) + two([6, 7]) + sum2([(1, 2), (2, 3)]) : U32)))

#|91
