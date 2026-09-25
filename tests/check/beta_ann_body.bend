# a redex whose body is an annotated name: the beta steps stop at the
# annotation and keep it, so w is checked against the type the user
# wrote and the miss is reported
import Base

def w(b: Nat) -> Nat:
  1n+b

def main() -> Nat:
  (x => {w : Bool -> Bool})(0n)(5n)

#|Error:
#|- expected : @_:Bool -> Bool
#|- observed : @b:Nat -> Nat
#|Location: main
#| 9 | def main() -> Nat:
#|10>|   (x => {w : Bool -> Bool})(0n)(5n)
#|   |          ^
#|11 |
#|exit 1
