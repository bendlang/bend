import Base
type A is Data:
  MkA{b: B}
type B is Data:
  MkB{}
def main() -> A:
  MkA{MkB{}}
