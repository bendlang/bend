# a compile-time parameter needs its type: the bare-name form is not for ~
import Base

def app(~f, x: Nat) -> Nat:
  f(x)

def main() -> Nat:
  app(~Nat.add(1n), 3n)

#|Error:
#|- expected : ':'
#|- observed : ','
#|Location:
#|3 | 
#|4>| def app(~f, x: Nat) -> Nat:
#|5 |   f(x)
#|exit 1
