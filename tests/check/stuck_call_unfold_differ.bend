# two calls of distinct defs whose bodies differ do not convert
import Base

def not1(b: Bool) -> Bool:
  match b:
    case True{}:
      False{}
    case False{}:
      True{}

def same(b: Bool) -> Bool:
  match b:
    case True{}:
      True{}
    case False{}:
      False{}

def eq(b: Bool) -> {not1(b) == same(b) : Bool}:
  {==}

def main() -> U32:
  0

#|SOME PROOFS FAIL
#|Error:
#|- expected : not1(b)
#|- observed : same(b)
#|Context:
#|- b : Bool
#|Location: eq
#|18 | def eq(b: Bool) -> {not1(b) == same(b) : Bool}:
#|19>|   {==}
#|   |   ^^^^
#|20 |
#|exit 1
