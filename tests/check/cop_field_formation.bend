# the + law binds ADT telescopes: a + entry in a constructor's
# telescope demands a Data-kinded type, or the datatype would hand
# every match arm an unlicensed Many binder. book_valid refuses the
# declaration itself (a function field is Type); main never checks.
import Base

type BadT is Type:
  MkB{+f: Nat -> Nat}

law main:
  Nat

def main(): 0n

#|Error:
#|- expected : Data
#|- observed : Type
#|Location: MkB
#|7 | type BadT is Type:
#|8>|   MkB{+f: Nat -> Nat}
#|  |           ^^^^^^^^^^
#|9 |
#|exit 1
