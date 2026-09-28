# a pure main's printed type may reach a datatype only through a family
# field: Box's value is Pick(b), Inner at True{}, and the build still
# gives Inner's constructors their ids
import Base

type Inner is Data:
  Inner{a: U32, b: U32}

def Pick(b: Bool) -> Data:
  match b:
    case False{}:
      U32
    case True{}:
      Inner

type Box<-b: Bool> is Data:
  Box{value: Pick(b)}

def main() -> Box<True{}>:
  Box{Inner{1, 2}}

#|Box{Inner{1, 2}}
