# lay_cyclic walks a datatype's fields instantiated: Nest<True{}> reaches
# itself through the family Cell(b), so it is a box (a node), where the
# walk by name alone saw Cell(b) stuck, called Nest flat, and lay_of
# recursed forever on the concrete type (#959)
import Base

type Nest<-b: Bool> is Data:
  End{}
  More{next: Cell(b)}

def Cell(b: Bool) -> Data:
  match b:
    case False{}:
      U32
    case True{}:
      Nest<True{}>

def read(n: Nest<True{}>) -> U32:
  match n:
    case End{}:
      7
    case More{next}:
      U32.add(1, read(next))

def wide(n: Nest<False{}>) -> U32:
  match n:
    case End{}:
      0
    case More{next}:
      next

def main() -> U32:
  U32.add(read(More{More{End{}}}), wide(More{100}))

#|109
