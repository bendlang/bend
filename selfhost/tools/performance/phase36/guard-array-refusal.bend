import Base

# Unary Nat recursion is pure but not an existing scalar tail/tree loop plan.
def guard.opaque(+n: Nat) -> U32:
  match n:
    case 0n: 1
    case 1n+p: U32.add(guard.opaque(p), 1)

def guard.mix(left: U32, right: U32) -> U32:
  array = Array.new(U32, 1n, left)
  (unused, value) = Array.get(U32, array, 0)
  U32.add(U32.add(value, right), guard.opaque(2n))

# Scalar inputs and a pure residual do not prove the whole root callback-free:
# direct private Array.new still calls mutable host allocation/fill hooks.
def guard.walk(+depth: Nat, +value: U32) -> U32:
  match depth:
    case 0n: value
    case 1n+p:
      left right = guard.walk(p, value) guard.walk(p, value)
      guard.mix(left, right)

def main() -> U32:
  guard.walk(2n, 3)
