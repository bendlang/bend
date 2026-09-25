# comp-splice pin (spec_comp_curried_lambda): bend3's curried comp
# arrows took x => y => chains as spliced arguments. bend's ~ law app2
# takes the chain the same way (its fill checks once, f opaque); the pin
# moves to helper, whose x is spent twice.
import Base

law app2:
  for ~f: U32 -> U32 -> U32
  for a: U32
  for b: U32
  U32

def app2(f, a, b):
  f(a, b)

law helper:
  for x: U32
  U32

def helper(x):
  (x * x : U32)

law main:
  U32

def main():
  (app2(x => y => (x * 10 + y : U32), 3, 4) + helper(2) : U32)

#|Error:
#|- expected : x
#|- observed : x (consumed more than once)
#|Location: helper
#|19 |
#|20>| def helper(x):
#|   |            ^
#|21 |   (x * x : U32)
#|exit 1
