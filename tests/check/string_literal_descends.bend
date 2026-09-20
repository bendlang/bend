# a literal argument descends when it is a strict tail of its case's
# literal pattern: the termination check unfolds the literal
import Base

def f(s: String) -> Nat:
  match s:
    case "ab":
      f("b")
    case _:
      0n

def main() -> Nat:
  f("ab")

#|0n
