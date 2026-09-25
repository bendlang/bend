# a datatype parameter cannot smuggle a duplication license: a live
# field of an opaque grade a is Kind(a), which a Data declaration does
# not entail (only &2 has no atoms), so Tag<a, -T: Kind(a)> -> Data
# refuses at its field
import Base

type Tag<a, -T: Kind(a)> is Data:
  Mk{val: T}

law main:
  Nat

def main():
  0n

#|Error:
#|- expected : Data
#|- observed : Kind(a)
#|Context:
#|- a : Quant
#|- T : Kind(a)
#|Location: Mk
#|7 | type Tag<a, -T: Kind(a)> is Data:
#|8>|   Mk{val: T}
#|  |           ^
#|9 | 
#|exit 1
