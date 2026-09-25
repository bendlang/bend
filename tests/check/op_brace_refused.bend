# braces ascribe a type and name no operator: a bare * inside {.. : Nat}
# is refused like any other, and the repair is (a * b : Nat) inside them
import Base

def main() -> Nat:
  {2n * 3n : Nat}

#|Error:
#|- message  : a type for this operator (write (a * b : Nat))
#|Location:
#|5 | def main() -> Nat:
#|6>|   {2n * 3n : Nat}
#|  |       ^
#|7 | 
#|Note: we broke this after launch, sorry. Until 2.0.16 a bare operator meant Nat.
#|That was a bug: operators demand annotation. Wrap the expression and it'll work again.
#|exit 1
