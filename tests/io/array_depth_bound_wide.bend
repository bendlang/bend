# io (io_array_depth_bound_wide): the depth wall counts cells, not
# elements. A Pt is two cells, so the C block of [p : Pt^31n] would need
# class 32 and buf_new refuses it, while the JS lanes once checked only
# the depth and set out to build 2^31 elements. Every lane now refuses
# a depth past 31 minus the element's cell class, the same wall.
import Base

type Pt is Data:
  Pt{x: U32, y: U32}

law main:
  IO(U32)

law main.x:
  for p: Pt
  U32

def main.x(p):
  match p:
    case Pt{x, y}:
      x

law main.go:
  for r: Array<Pt> & Pt
  IO(U32)

def main.go(r):
  (a, p) = r
  do IO<U32>:
    u : Unit <- IO.print(U32.show(main.x(p)))
    return 0

def main():
  main.go(Array.get(Pt, [Pt{7, 8} : Pt^31n], 5))

#|bend: an array past the deepest block class 31 (depth + log2 words per cell)
#|exit 1
