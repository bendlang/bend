# Concrete function elements have a uniform boxed layout. Captured closures
# survive storage, splitting and recursive consumption in Array cells.
import Base

def mkA(n: U32) -> Array<(U32 -> U32)>:
  ALeaf{x => (x + n : U32)}

def sumA(a: Array<(U32 -> U32)>) -> U32:
  match a:
    case ALeaf{f}: f(1)
    case ANode{xs, ys}: (sumA(xs) + sumA(ys) : U32)

def swapped(r: Array<(U32 -> U32)> & (U32 -> U32)) -> U32:
  (a, old) = r
  (old(7) + sumA(a) : U32)

def replace(a: Array<(U32 -> U32)>) -> U32:
  swapped(Array.swap(U32 -> U32, a, 0, x => (x + 1 : U32)))

def strings(s: String) -> Array<(String -> String)>:
  ALeaf{x => s ++ x}

def joinStrings(a: Array<(String -> String)>, +s: String) -> String:
  match a:
    case ALeaf{f}: f(s)
    case ANode{xs, ys}: joinStrings(xs, s) ++ joinStrings(ys, s)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(sumA(ANode{mkA(41), mkA(6)})))
    IO.print(U32.show(replace(ANode{ALeaf{x => (x * 2 : U32)}, ALeaf{x => (x * 3 : U32)}})))
    IO.print(joinStrings(ANode{strings("a"), strings("b")}, "!"))

#|49
#|19
#|a!b!
