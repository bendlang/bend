# comp-splice pin (spec_mint_count): bend3's comp-lambda mint-count cost
# guard (a recursive template's knot tied structurally, counted under
# --stats). bend has neither comp mints nor a stats surface; the ~
# binder pins bend's own parse refusal. (bend3's number switch on the
# counter respells as base Nat recursion.)
import Base

law each:
  for n: Nat
  for ~g: U32 -> U32
  for x: U32
  U32

def each(n, g, x):
  match n:
    case 0n:
      g(x)
    case 1n+k:
      each(k, g, g(x))

law u0:
  for x: U32
  U32

def u0(x):
  (each(3n, y => (y + 1 : U32), x) + each(2n, y => (y * 2 : U32), x) : U32)

law main:
  U32

def main():
  u0(1)

#|Error:
#|- expected : a name
#|- observed : '~'
#|Location:
#| 9 |   for n: Nat
#|10>|   for ~g: U32 -> U32
#|11 |   for x: U32
#|exit 1
