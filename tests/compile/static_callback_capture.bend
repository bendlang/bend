import Base

type Box is Type:
  Box{f: U32 -> U32}

def extract(b: Box) -> U32 -> U32:
  match b:
    case Box{f}:
      f

def make(offset: U32) -> Box:
  Box{x => (x + offset : U32)}

def static() -> Box:
  make(10)

def apply(b: Box, x: U32) -> U32:
  extract(b, x)

def main() -> List<U32>:
  [extract(static(), 2), apply(make(20), 3)]
#|[12, 23]
