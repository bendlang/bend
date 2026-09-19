# A callback-producing computation with a fork stays a runtime computation.
import Base

def id(x: U32) -> U32:
  x

def make() -> U32 -> U32:
  a b = id(1) id(2)
  x => ((x + a : U32) + b : U32)

def main() -> U32:
  make()(4)
#|7
