import Base
type A is Data:
  MkA{b: B<U32>}
type B<q, -T: Kind(q)> is Kind(q):
  MkB{v: T}
def main() -> U32:
  7
