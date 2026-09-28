# a container's + license is its grade, never resolved structurally
# from the element: List<&1, Nat> is affine although Nat is Data, so
# +x: List<&1, Nat> refuses; List<&2, Nat> is the reusable spelling
import Base

law keep:
  for +x: List<&1, Nat>
  List<&1, Nat>

def keep(x):
  x

law main:
  Nat

def main():
  0n

#|SOME PROOFS FAIL
#|Error:
#|- expected : Data
#|- observed : Type
#|Location: keep
#|6 | law keep:
#|7>|   for +x: List<&1, Nat>
#|  |           ^^^^^^^
#|8 |   List<&1, Nat>
#|Note: +x can be used many times, so its type must be Data.
#|exit 1
