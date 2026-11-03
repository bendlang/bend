# check-let does not check an ordinary or erased binder's type, so x : 0n
# enters the context here, from a signature below the let. the program is
# still refused, at g's own event: that event is what the skipped check relies on
import Base

def main() -> Nat:
  -x = g();
  0n

def g() -> 0n:
  ?TODO

#|SOME PROOFS FAIL
#|Error:
#|- expected : Type
#|- observed : Nat
#|Location: g
#| 9 | 
#|10>| def g() -> 0n:
#|   |            ^^
#|11 |   ?TODO
#|exit 1
