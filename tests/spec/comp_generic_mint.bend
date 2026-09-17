# comp-splice pin (spec_comp_generic_mint): bend3's generic template --
# the exact List.map shape, one mint per site with the instantiation
# baked in. bend rules the comp surface out (map is not checkable even
# once Data lands); bend3's def<A,B> respells as erased -A/-B binders
# and the ~ binder pins bend's own parse refusal.
import Base

type L<-A: Type> is Type:
  C{h: A, t: L<A>}
  N{}

law map:
  for -A: Type
  for -B: Type
  for ~f: A -> B
  for xs: L<A>
  L<B>

def map(A, B, f, xs):
  match xs:
    case C{h, t}:
      C{f(h), map(A, B, f, t)}
    case N{}:
      N{}

law total:
  for xs: L<U32>
  U32

def total(xs):
  match xs:
    case C{h, t}:
      (h + total(t) : U32)
    case N{}:
      0

law main:
  U32

def main():
  total(map(U32, U32, x => (x + 1 : U32), C{1, C{2, N{}}}))

#|Error:
#|- expected : a name
#|- observed : '~'
#|Location:
#|14 |   for -B: Type
#|15>|   for ~f: A -> B
#|16 |   for xs: L<A>
#|exit 1
