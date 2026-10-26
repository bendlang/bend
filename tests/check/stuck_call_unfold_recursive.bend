# a call inside an unfolded body stays a call: two recursive defs with
# the same body do not convert stuck, as each body calls itself by its
# own name (that needs coinduction, not one unfolding)
import Base

def r(n: Nat) -> Nat:
  match n:
    case Zero{}:
      Zero{}
    case Succ{m}:
      r(m)

def s(n: Nat) -> Nat:
  match n:
    case Zero{}:
      Zero{}
    case Succ{m}:
      s(m)

def eq(n: Nat) -> {r(n) == s(n) : Nat}:
  {==}

def main() -> U32:
  0

#|SOME PROOFS FAIL
#|Error:
#|- expected : r(n)
#|- observed : s(n)
#|Context:
#|- n : Nat
#|Location: eq
#|20 | def eq(n: Nat) -> {r(n) == s(n) : Nat}:
#|21>|   {==}
#|   |   ^^^^
#|22 |
#|exit 1
