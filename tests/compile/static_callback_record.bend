# A closed record projects a callback; computed arguments remain evaluated
# once, and the erased field is not a runtime callback argument.
import Base

type Callbacks is Type:
  Callbacks{-tag: U32, map: U32 -> U32}

def select(c: Callbacks) -> U32 -> U32:
  match c:
    case Callbacks{tag, f}:
      f

def callbacks() -> Callbacks:
  Callbacks{123, +x => (x + x : U32)}

def map(~f: U32 -> U32, xs: List<U32>) -> List<U32>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      f(h) <> map(~f, t)

def main() -> List<U32>:
  map(~(x => select(callbacks(), (x + 1 : U32))), [1, 2, 3])
#|[4, 6, 8]
