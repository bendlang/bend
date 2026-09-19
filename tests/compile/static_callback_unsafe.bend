# An unsafe callback producer is not a compile-time evaluation candidate.
import Base

@unsafe def make() -> U32 -> U32:
  x => (x + 1 : U32)

def main() -> U32:
  make()(4)
#|5
