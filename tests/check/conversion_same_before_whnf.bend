# conversion compares two copies of the same closed term syntactically before
# normalizing them: 2^30 in unary overflows the stack.
import Base

law same:
  {U32.to_nat(1073741824) == U32.to_nat(1073741824) : Nat}

def same(): {==}

law args:
  {Nat.add(U32.to_nat(1073741824), 0n) == Nat.add(U32.to_nat(1073741824), 0n) : Nat}

def args(): {==}

# the identity walk has a budget, spent even on shared nodes: past it, the
# walk would unfold dag(40n, z)'s shared cells into a 2^40-leaf tree
type Box is Data:
  Box{v: Nat}

def pair(a: Nat, b: Nat, c: Nat, d: Nat) -> Nat:
  0n

def dag(n: Nat, +y: Nat) -> Box:
  match n:
    case 0n: Box{y}
    case 1n+p: dag(p, pair(y, y, 0n, 0n))

def dag2(n: Nat, +y: Nat) -> Box:
  dag(n, y)

def shared(+z: Nat) -> {dag(40n, z) == dag2(40n, z) : Box}:
  {==}

law main:
  U32

def main(): 0

#|0
