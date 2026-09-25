# comp-splice pin (spec_comp_erased_args): bend3 checked erased template
# args against the REAL earlier arguments (the %s placeholder soundness
# hole, pinned rejected). a ~ clause after a plain one is refused where
# it is written: only leading clauses take ~, so g heads no template.
# (bend3's local Nat rides base's Nat; the fake proof would be {==} at
# 0n == 1n.)
import Base

law tpl:
  for a: Nat
  for b: Nat
  for -e: {a == b : Nat}
  for ~g: Nat -> Nat
  for x: Nat
  Nat

def tpl(a, b, e, g, x):
  match x:
    case 0n:
      g(a)
    case 1n+p:
      g(b)

law main:
  for x: Nat
  Nat

def main(x):
  tpl(0n, 1n, {==}, y => y, x)

#|Error:
#|- expected : a plain clause (only leading clauses take ~)
#|- observed : '~'
#|Location:
#|12 |   for -e: {a == b : Nat}
#|13>|   for ~g: Nat -> Nat
#|   |       ^
#|14 |   for x: Nat
#|exit 1
