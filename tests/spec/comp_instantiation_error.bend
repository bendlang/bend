# comp-splice pin (spec_comp_instantiation_error): bend3 surfaced a
# template error AT THE INSTANTIATION (the spliced argument checked at
# the site's concrete types). bend3's def<A,B> respells as erased -A/-B
# binders, and a ~ clause after a plain one is refused where it is
# written: only leading clauses take ~, so f heads no template.
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

law caller:
  for xs: L<U32>
  L<F32>

def caller(xs):
  map(U32, F32, x => (x + 1 : U32), xs)

law main:
  L<F32>

def main():
  caller(C{1, N{}})

#|Error:
#|- expected : a plain clause (only leading clauses take ~)
#|- observed : '~'
#|Location:
#|14 |   for -B: Type
#|15>|   for ~f: A -> B
#|   |       ^
#|16 |   for xs: L<A>
#|exit 1
