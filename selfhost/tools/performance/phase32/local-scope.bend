import Base

def scope.mix(+x: U32, +y: U32) -> U32:
  U32.add(U32.mul(x, 3), y)

# Repeated source names, scalar prefixes and nested unpacking must preserve
# the original bindings used by both independent call arguments.
def scope.score(+x: U32, +y: U32, p: (U32 & U32) & U32) -> U32:
  (inner, z) = p
  (a, b) = inner
  +x = U32.add(U32.add(x, y), a)
  +y = U32.add(b, z)
  scope.mix(x, y)

def scope.walk(+n: Nat, +acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+q:
      scope.walk(q, scope.score(3, 5, ((acc, 1), 2)))

def bench(+n: U32, +seed: U32) -> U32:
  scope.walk(U32.to_nat(n), seed)

def main() -> IO(Unit):
  IO.print(U32.show(bench(2, 5)))

#| 153
