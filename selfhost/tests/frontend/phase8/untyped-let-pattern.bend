import Base

type T is Data:
  C{x: U32}
def take(t: T) -> U32:
  C{x} = t
  x
def main() -> U32:
  take(C{7})
