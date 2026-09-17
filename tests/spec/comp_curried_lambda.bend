# comp-splice pin (spec_comp_curried_lambda): bend3's curried comp arrows
# took x => y => chains as spliced arguments. bend has no comp surface;
# the ~ binder pins bend's own parse refusal.
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
#|- expected : a name
#|- observed : '~'
#|Location:
#|6 | law app2:
#|7>|   for ~f: U32 -> U32 -> U32
#|8 |   for a: U32
#|exit 1
