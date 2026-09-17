# borrow witness: a zero-box layout. Pt is two words and no box, so no
# parameter of it is ever borrowed or kept: F copies the words, and the C
# has no term_keep and no term_peek.
import Base

type Pt is Data:
  Pt{x: U32, y: U32}

def Pt.sum(p: Pt) -> U32:
  match p:
    case Pt{x, y}:
      (x + y : U32)

def F(+p: Pt) -> U32:
  (Pt.sum(p) + Pt.sum(p) : U32)

def main() -> IO(Unit):
  IO.print(U32.show(F(Pt{3, 4})))

#|14
