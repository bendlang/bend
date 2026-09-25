# comp-splice pin (spec_comp_any_term): bend3 filled a comp (~) slot
# with ANY term (a ref, a runtime-bound lambda var). bend's ~ law use
# checks once, f an opaque constant; a ~ argument is a closed term, and
# a let-bound name is a variable of the caller's context, unbound in the
# empty one, so caller's call is refused (a def name, as in main, is
# closed).
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
#|- expected : a template applied to closed ~ arguments (g is a variable here, not comptime: pass it at run time)
#|- observed : use
#|Context:
#|- x : U32
#|- g : @_:U32 -> U32
#|Location: caller
#|29 |   g = {y => (y + 1 : U32) : U32 -> U32}
#|30>|   use(g, x)
#|   |   ^^^
#|31 |
#|exit 1
