# Projecting a callback must not assume other computed fields are static.
import Base

type PairFn is Type:
  PairFn{unused: U32, f: U32 -> U32}

@unsafe def value() -> U32:
  7

def make() -> PairFn:
  PairFn{value(), x => (x + 1 : U32)}

def select(p: PairFn) -> U32 -> U32:
  match p:
    case PairFn{unused, f}:
      f

def main() -> U32:
  select(make(), 41)
#|42
