# a closed ~ argument of the wrong type: the miss is the type's own,
# against the template's domain, not an open-argument refusal
import Base

def T(~n: Nat, x: Nat) -> Nat:
  Nat.add(n, x)

def main() -> Nat:
  T(~True{}, 2n)

#|Error:
#|- expected : Nat
#|- observed : Bool
#|Location: main
#| 8 | def main() -> Nat:
#| 9>|   T(~True{}, 2n)
#|   |      ^^^^^^
#|10 |
#|exit 1
