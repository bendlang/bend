# as let_forward_type, for a family below the let: L's kind is not checked
# until its own event, so the let checks it
import Base

def h(x: Nat) -> Nat:
  x

def main() -> Nat:
  -x = L;
  -y = h(x);
  0n

type L is 0n:
  C{}

#|SOME PROOFS FAIL
#|Error:
#|- expected : Kind(&0)
#|- observed : Nat
#|Location: main
#| 8 | def main() -> Nat:
#| 9>|   -x = L;
#|   |   ^^
#|10 |   -y = h(x);
#|exit 1
