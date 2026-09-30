# Regression for unsupported nested Nat matches reaching the worker recognizer.
# A candidate predicate must refuse these before subtracting from arity zero.
import Base

def nested(n: Nat, +x: U32) -> U32:
  match n:
    case 0n: x
    case 1n: U32.inc(x)
    case 2n: U32.add(x, 2)
    case 3n+p: U32.add(x, U32.add(3, U32.from_nat(p)))

def nested_nullary(n: Nat) -> U32:
  match n:
    case 0n: 7
    case 1n: 11
    case 2n+p: U32.add(13, U32.from_nat(p))

def no_residual(n: Nat) -> U32:
  match n:
    case 0n: 17
    case 1n+p: U32.add(19, U32.from_nat(p))
