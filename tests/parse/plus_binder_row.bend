# a + binder's re-bind opens its body below the row of destructures and
# match arms that head it, so a parallel let takes a + per name, a
# destructure may carry a + before another destructure, and a marked
# case field may be matched under a match on its sibling
import Base

type Kon is Data:
  Kon{h: U32, t: Bool}

def sq(+x: U32) -> U32:
  +a +b = U32.inc(x) U32.inc(U32.inc(x))
  U32.add(U32.mul(a, a), U32.mul(b, b))

def pair(r: U32 & U32, rg: U32 & U32) -> U32:
  (h, +v) = r
  (g, z) = rg
  U32.add(U32.add(v, v), U32.add(g, z))

def kon(x: Kon) -> U32:
  match x:
    case Kon{+h, t}:
      match t:
        case True{}:
          U32.add(h, h)
        case False{}:
          h

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(sq(1)))
    IO.print(U32.show(pair((1, 2), (3, 4))))
    IO.print(U32.show(kon(Kon{5, True{}})))

#|13
#|11
#|10
