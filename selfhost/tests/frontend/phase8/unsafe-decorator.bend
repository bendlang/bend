import Base

@unsafe
def id(x: U32) -> U32:
  x

def main() -> U32:
  id(7)
