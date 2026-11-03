# bend3 whitelisted exact canonical base axioms and warned on look-
# alikes; bend has no census -- the only exemption IS base.bend, so a
# user's bodiless assert under a base-looking name stays dead, and
# its live use refuses at validation
import Base

law U32.magic_hom:
  U32

law use:
  U32

def use():
  U32.magic_hom

law main:
  U32

def main():
  0

#|SOME PROOFS FAIL
#|Error:
#|- expected : a def whose body is implemented before the def is used (defs are checked in file order, and an unfilled law has none)
#|- observed : U32.magic_hom
#|Location: use
#|13 | def use():
#|14>|   U32.magic_hom
#|   |   ^^^^^^^^^^^^^
#|15 |
#|exit 1
