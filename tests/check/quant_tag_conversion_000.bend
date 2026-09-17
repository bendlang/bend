# function types convert by quantity tag before domain and codomain:
# @x and @-x over the same Nat -> Nat are NOT convertible. gutted, this
# program checks whole and forges contraction with no license: g rides
# the erased-domain type, so g(a) checks a dead (a use that costs
# nothing) and the tuple consumes a again -- an affine value duplicated
# through a quantity cast alone.
import Base

law relax:
  for f: @x: Nat -> Nat
  @-x: Nat -> Nat

def relax(f):
  f

law dupl:
  for a: Nat
  Nat & Nat

def dupl(a):
  g = relax(x => x)
  (g(a), a)

law main:
  Nat & Nat

def main(): dupl(1n)

#|Error:
#|- expected : @-x:Nat -> Nat
#|- observed : @x:Nat -> Nat
#|Context:
#|- f : @x:Nat -> Nat
#|Location: relax
#|13 | def relax(f):
#|14>|   f
#|15 | 
#|exit 1
