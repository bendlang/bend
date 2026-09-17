# comp-splice pin (spec_comp_generic_dedupe): bend3's generic battery --
# capture through a generic template, two type-pair instantiations,
# per-site minting. bend has no comp surface; def<A,B> respells as
# erased -A/-B binders and the ~ binder pins bend's own parse refusal.
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

law shift:
  for k: U32
  for xs: L<U32>
  L<U32>

def shift(k, xs):
  map(U32, U32, x => (x + k : U32), xs)

law main:
  U32

def main():
  total(shift(10, C{1, C{2, N{}}}))

#|Error:
#|- expected : a name
#|- observed : '~'
#|Location:
#|13 |   for -B: Type
#|14>|   for ~f: A -> B
#|15 |   for xs: L<A>
#|exit 1
