# a let's value can name a def below it from a dead region, before that
# def's signature is checked: its type is not known to be one yet, so the
# let checks it, and x : 0n never reaches h(x), where it would blame main
import Base

def h(x: Nat) -> Nat:
  x

def main() -> Nat:
  -x = g();
  -y = h(x);
  0n

def g() -> 0n:
  ?TODO

#|SOME PROOFS FAIL
#|Error:
#|- expected : Kind(&0)
#|- observed : Nat
#|Location: main
#| 9 | def main() -> Nat:
#|10>|   -x = g();
#|   |   ^^
#|11 |   -y = h(x);
#|exit 1
