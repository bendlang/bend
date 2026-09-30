# bend2's Kind(&0) and Kind(&1) are one rung, so K0 fits go's Nat -> Type:
# a literal &0 in a kind goes to --verdict as *(.Q1), since the kernel's
# *(.Q0) and *(.Q1) are two. go's self-call passes K0 as is (no eta), so
# the kernel compares the two kinds
import Base

def K0(A: Nat) -> Kind(&0):
  Nat

def go(n: Nat, f: Nat -> Type) -> Nat:
  match n:
    case 0n: 0n
    case 1n+p: go(p, K0)

def main() -> Nat:
  go(3n, K0)

#|0n
