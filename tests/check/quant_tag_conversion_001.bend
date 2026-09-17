# the quantity tag distinguishes Many from Lone even where the domains
# are identical: Nat is Data, so the tag comparison is the ONLY wall
# between @+x: Nat -> Nat and @x: Nat -> Nat. gutted, the two function
# types convert and a quantity cast needs no coercion at all.
import Base

law relax:
  for f: @+x: Nat -> Nat
  @x: Nat -> Nat

def relax(f):
  f

#|Error:
#|- expected : @x:Nat -> Nat
#|- observed : @+x:Nat -> Nat
#|Context:
#|- f : @+x:Nat -> Nat
#|Location: relax
#|11 | def relax(f):
#|12>|   f
#|13 | 
#|exit 1
