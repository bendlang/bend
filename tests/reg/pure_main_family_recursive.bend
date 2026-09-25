# regression witness: a recursive family-selected pure result omitted
# native constructor metadata even when its value was shared across a pair.
import Base

type Inner is Data:
  Leaf{a: U32}
  Branch{left: Inner, right: Inner}

def Pick(b: Bool) -> Data:
  match b:
    case False{}:
      U32
    case True{}:
      Inner

type Box<-b: Bool> is Data:
  Box{value: Pick(b)}

def twice(+box: Box<True{}>) -> Pair(Box<True{}>, Box<True{}>):
  (box, box)

def main() -> Pair(Box<True{}>, Box<True{}>):
  twice(Box{Branch{Leaf{1}, Leaf{2}}})

#|(Box{Branch{Leaf{1}, Leaf{2}}}, Box{Branch{Leaf{1}, Leaf{2}}})
