# regression witness: a pure result's family-selected field left native
# constructor IDs undeclared, including the unused sum alternative.
import Base

type Inner is Data:
  One{a: U32}
  Two{a: U32, b: U32}

def Pick(b: Bool) -> Data:
  match b:
    case False{}:
      U32
    case True{}:
      Inner

type Box<-b: Bool> is Data:
  Box{value: Pick(b)}

def main() -> Box<True{}>:
  Box{Two{1, 2}}

#|Box{Two{1, 2}}
