# comp-splice pin (spec_comp_any_term): bend3 filled a comp (~) slot with
# ANY term (a ref, a runtime-bound lambda var). bend has no comp surface
# by ruling -- the ~ binder pins bend's own parse refusal.
import Base

law use:
  for ~f: U32 -> U32
  for x: U32
  U32

def use(f, x):
  f(x)

law inc:
  for x: U32
  U32

def inc(x):
  (x + 1 : U32)

law caller:
  for x: U32
  U32

def caller(x):
  g = {y => (y + 1 : U32) : U32 -> U32}
  use(g, x)

law main:
  U32

def main():
  (caller(3) * 10 + use(inc, 5) : U32)

#|Error:
#|- expected : a name
#|- observed : '~'
#|Location:
#|6 | law use:
#|7>|   for ~f: U32 -> U32
#|8 |   for x: U32
#|exit 1
