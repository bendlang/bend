# the old Nat spelling +n is no operator: a + glued to a name heads
# a binder, so 1n +n opens a parallel let, and the error says so at the +
import Base

def main() -> Nat:
  1n +n 2n

#|SOME PROOFS FAIL
#|Error:
#|- expected : '=' (an operator takes spaces on both sides and a type: (a + b : T))
#|- observed : '+'
#|Location:
#|5 | def main() -> Nat:
#|6>|   1n +n 2n
#|  |      ^
#|7 | 
#|exit 1
